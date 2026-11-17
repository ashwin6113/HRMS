# REBS HRMS — Offline-Capable Mobile Employee Workspace

An offline-first, geofenced Human Resource Management System (HRMS) built with Flutter. Designed to operate reliably in high-latency, intermittent, or completely disconnected environments while maintaining strict business rule validation and data integrity.

---

## 1. Architecture Overview

This project adheres to a clean, layered architecture separating UI, Business Logic (State Management), Data Layer (Repositories & Persistence), and Network Communication:

```
lib/
├── api/                        # HTTP client & Mock API Sandbox
│   ├── core/                   # Typed API exceptions (Network, Conflict, Validation, Server)
│   ├── mock_api_scenario.dart  # Reviewer Scenario Manager (Slow, 500, 409, 422, Offline)
│   ├── mock_http_client.dart   # In-memory server seeded with databasesample.com contract
│   └── api_service.dart        # Clean REST API abstraction
├── data/
│   ├── model/                  # Domain Models (Employee, AttendanceRecord, AttendanceEvent, Leave)
│   ├── local/                  # SQLite Database Helper (5 tables, FIFO queue, caches)
│   ├── repo/                   # Repositories (EmployeeRepository, AttendanceRepository, LeaveRepository)
│   └── providers/              # State Management (Employee, Attendance, Leave, Sync, Theme)
├── common/
│   ├── constants/              # AppColors, Theme, AppStyles
│   ├── router/                 # GoRouter navigation & ShellRoute configuration
│   └── utils/                  # Haversine Location Service & Geofencing engine
├── screens/
│   ├── home/                   # Employee Dashboard, Live Ticker, Reviewer Drawer
│   ├── calendar/               # Leave Management screen & Leave Application modal
│   ├── main_shell_screen.dart  # Shell with floating bottom nav and quick actions modal
│   └── ...
└── widgets/                    # Reusable UI components (FloatingBottomNav, Shimmer, etc.)
```

### State Management & Persistence Choices
* **State Management (`Provider`)**: Lightweight, robust, and clean separation between business logic and UI presentation without boilerplate. Used `ChangeNotifierProxyProvider` to link network reconnection events directly to auto-sync.
* **Local Persistence (`sqflite` & `sqflite_common_ffi`)**: Production-grade SQLite database with 5 distinct tables (`employee_cache`, `attendance_records`, `pending_attendance_events`, `leave_requests`, `leave_balance_cache`). Supports cross-platform execution (iOS, Android, macOS desktop).
* **Mock Backend Engine (`MockHttpClient`)**: Implements `http.BaseClient` directly, intercepting network requests in memory, persisting changes across sessions, and simulating repeatable edge-case scenarios without requiring external servers.

---

## 2. Core Features Breakdown

### 1. Employee Dashboard
* **Employee Information**: Displays name, employee ID, department, office coordinates, and avatar.
* **Today's Attendance Card**: Shows live attendance status (`Checked In`, `Checked Out`, `Not Checked In`), exact check-in/out timestamps, and a real-time working duration counter (`HH:MM:SS`) updated every second.
* **Leave Balance Overview**: Real-time summary of available Casual and Sick leave balances.
* **Attendance History**: Displays the latest 5 attendance records with sync status badges (`Synced`, `Pending`, `Rejected`).
* **UI States**: Shimmer skeleton loading during network fetch, empty state fallbacks, error handling, and persistent offline banners.

### 2. Geofenced Check-In & Check-Out
* **200-Meter Geofence**: Enforces check-in/out within 200m radius of configurable office coordinates (`12.9716, 77.5946` by default) using the Haversine distance formula.
* **Business Rule Enforcement**:
  * Exactly one check-in allowed per working day.
  * Check-out permitted **only after** a valid check-in.
  * Button debouncing and tap locking prevent race conditions and duplicate taps.
* **Hardware & Reviewer Location Simulation**:
  * Dropdown in Reviewer Settings allows instant switching between:
    * `At Office Desk (0m)` — Permits check-in/out.
    * `Outside Office (~550m)` — Rejects with exact distance feedback.
    * `Permission Denied` & `Permanently Denied` — Rejects with prompt to open settings.
    * `GPS Disabled` — Rejects with GPS activation guidance.
    * `Real Hardware GPS` — Reads physical device coordinates.

### 3. Offline Storage & Two-Way Sync Engine
* **Restart Persistence**: When offline, attendance actions are committed immediately to the SQLite `pending_attendance_events` table with status `PENDING`. Survives application kills and restarts.
* **FIFO Chronological Synchronization**: Events are synchronized strictly in order of timestamp (`ORDER BY timestamp ASC`), ensuring check-in always precedes check-out.
* **Idempotency via `client_event_id`**: Every action generates a unique UUID `client_event_id`. If network drops or retries occur, the server deduplicates by this ID and never creates duplicate attendance records.
* **Auto-Sync on Reconnect**: Automatically synchronizes queued events the moment connectivity is restored.
* **Conflict & Failure Handling**:
  * **Server 409 Conflict**: Marked as `rejected` in local database, preserving server error message on the UI.
  * **Temporary Network Drop / 500 Server Error**: Retains event in queue with an incremented `retry_count`.

### 4. Leave Application Module
* **Leave Balances**: Categorized into `Casual` and `Sick` leave with available vs total day counts.
* **Date Range Picker**: Full date selector preventing past dates and ensuring end date $\ge$ start date.
* **Live Validation Rules**:
  * `startDate` cannot be before current date.
  * `endDate` cannot be before `startDate`.
  * Requested calendar days cannot exceed available balance.
  * Requested dates cannot overlap any existing `Pending` or `Approved` request.
  * Reason field requires at least **10 non-whitespace characters** (`X/10 min characters` live indicator).
* **Online Submission Enforcement**: Blocks offline submission with actionable feedback (`NetworkException`), while allowing full offline viewing of previously cached requests.
* **Filter Tabs**: Filter leave history by `All`, `Pending`, `Approved`, or `Rejected`.

---

## 3. Device-Side vs Server-Side Validation Matrix

| Validation Rule | Device-Side Responsibility | Server-Side Responsibility (Must Repeat) |
| :--- | :--- | :--- |
| **GPS Geofence (200m)** | Prevents invalid submission, saves cellular bandwidth, provides instant user feedback. | Recalculate distance using verified GPS coordinates to prevent client spoofing. |
| **Check-in Order & Frequency** | Blocks check-out before check-in; prevents multiple taps and duplicate sessions. | Enforce database constraints; ensure exactly one active attendance record per day. |
| **Idempotency (`client_event_id`)** | Generates unique UUID per tap; prevents duplicate retries during retries. | Deduplicate based on `client_event_id` before inserting records into the database. |
| **Leave Overlap & Balance** | Prevents selecting invalid date ranges; prevents form submission. | Transactional lock on leave ledger to prevent race conditions across multiple devices. |
| **Reason Length & Format** | Instant form feedback on keystrokes (`X/10 characters`). | Sanitize input against XSS/injection; validate length constraints on payload. |
| **Connectivity Gate** | Informs user immediately that leave submission requires network. | Rejects unauthenticated or malformed requests; verifies session freshness. |

---

## 4. Reviewer Demonstration Guide

Follow these steps to demonstrate every requirement:

### Scenario A: Geofenced Attendance & Live Ticker
1. Open the app. The dashboard loads employee details and available leave balances.
2. In the top app bar, tap the **Reviewer icon** (top-right sliders).
3. Under **Location Simulation**, select **"Outside Office (~550m)"**.
4. Tap **Check In**. Notice the red SnackBar: *"Check-In failed: You are 550m away from the office. Attendance is permitted only within 200m."*
5. Return to Reviewer Settings, select **"At Office Desk (0m)"**, and tap **Check In**.
6. The status changes immediately to **Checked In**, and the working duration counter begins counting up in real-time (`00h 00m 01s`, `00h 00m 02s`...).
7. Try tapping Check In again: notice it is disabled (single check-in per day enforced).

### Scenario B: Offline Persistence & Restart Survival
1. Open Reviewer Settings and toggle **Simulate Network Offline** to **ON**.
2. Notice the yellow **Offline** badge and **"Working Offline"** banner on the dashboard.
3. Tap **Check Out**. The action succeeds locally, status becomes **Checked Out**, and the record shows badge **`Pending Sync`**.
4. **Kill the app completely** (terminate the process).
5. Relaunch the app. Notice the **Checked Out** status and **`Pending Sync`** record remain intact from SQLite!
6. Open Reviewer Settings and toggle **Simulate Network Offline** to **OFF**.
7. The app automatically triggers **Auto-Sync**. Notice the record transitions from `Pending Sync` to `Synced` with a green checkmark!

### Scenario C: Leave Application & Validation Rules
1. Tap the **Calendar** tab in the bottom navigation bar (or tap "Apply Leave" from the floating `+` button).
2. Tap **Apply Leave**.
3. **Past Date Check**: Try selecting a date in the past; notice the date picker restricts selection to today and future dates.
4. **Reason Length Check**: Enter `"Sick"` in the reason field; notice the counter shows `4/10 min characters` and the Submit button remains disabled with a validation warning.
5. Enter a valid reason (e.g. `"Attending brother wedding ceremony"`).
6. **Balance Check**: Select a date range spanning 15 days; notice the validation warning: *"Requested 15 day(s) exceeds your available Casual balance (10 day(s))."*
7. Adjust the range to 2 days and tap **Submit Leave Application**. The request appears under **Pending** and the available balance updates provisionally.
8. **Overlap Check**: Tap **Apply Leave** again and attempt to select the same 2 days. The system immediately rejects with: *"Selected dates overlap with an existing Pending leave."*

### Scenario D: Repeatable Edge Case Scenarios
1. Open Reviewer Settings and set **Mock Scenarios** to **"Duplicate Attendance Conflict (409)"**.
2. Attempt to synchronize attendance. The event is safely marked as **`Rejected`** with the server's rejection reason preserved.
3. Switch scenario back to **"Success (Normal 200/201)"** and reset scenarios at any time.

---

## 5. Setup & Run Instructions

### Prerequisites
* Flutter SDK: `^3.12.0` (or Flutter 3.24+)
* Xcode (for iOS/macOS) or Android Studio (for Android)

### Installation
```bash
# Clone and enter directory
cd hrms

# Clean and fetch dependencies
flutter clean
flutter pub get

# For iOS Simulator / device
cd ios && pod install && cd ..
flutter run -d ios

# For macOS Desktop
flutter run -d macos

# For Android
flutter run -d android
```

---

## 6. Automated Test Suite

Run the full automated test suite containing unit tests, repository tests, provider tests, and widget tests:

```bash
flutter test
```

### Assignment Mandatory Tests Included:
1. **Test 1 (`test/geofence_and_attendance_rules_test.dart`)**:
   * *Check-out without check-in is rejected.*
2. **Test 2 (`test/offline_sync_test.dart`)**:
   * *Repeated submission or retry does not create duplicate attendance (Idempotency via `client_event_id`).*
3. **Test 3 (`test/offline_sync_test.dart`)**:
   * *Pending attendance survives local persistence and is synchronized in chronological FIFO order.*
4. **Test 4 (`test/leave_rules_test.dart`)**:
   * *Overlapping leave dates are rejected.*
5. **Additional Rule & Scenario Tests**:
   * Leave requests exceeding available balance are rejected.
   * Reasons under 10 non-whitespace characters are rejected.
   * Temporary network drops increment retry count without losing events.
   * Automatic background synchronization on network reconnect.
   * Server 409 conflict marks event as rejected.
6. **Mandatory Widget Tests (`test/widget_test.dart`)**:
   * Loading shimmer verification during slow API response.
   * Loaded dashboard validation (employee info, attendance card, leave summary).
   * Offline banner and badge verification when network is simulated offline.
