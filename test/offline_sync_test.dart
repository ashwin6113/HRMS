import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/api/api.dart';
import 'package:hrms/data/local/database_helper.dart';
import 'package:hrms/data/model/models.dart';
import 'package:hrms/data/providers/attendance_provider.dart';
import 'package:hrms/data/providers/sync_provider.dart';
import 'package:hrms/data/repo/attendance_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value([ConnectivityResult.wifi]);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    MockScenarioManager.instance.reset();
    final db = await DatabaseHelper.instance.database;
    await db.delete('pending_attendance_events');
    await db.delete('attendance_records');
    await db.delete('employee_cache');
  });

  group('Phase 5: Offline Storage & Two-Way Sync Engine Tests', () {
    test(
        'Assignment Required Test 2: Repeated submission or retry does not create duplicate attendance (Idempotency)',
        () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = AttendanceRepository(apiService: apiService);

      final event = AttendanceEvent(
        clientEventId: 'idempotent-test-event-uuid-1234',
        employeeId: 'EMP-001',
        eventType: 'check_in',
        timestamp: DateTime.parse('2026-11-16T09:00:00Z'),
        latitude: 12.9716,
        longitude: 77.5946,
      );

      // First submission (Online)
      final firstRecord = await repo.recordAttendanceEvent(event, isOnline: true);
      expect(firstRecord.status, 'Checked In');
      expect(firstRecord.syncStatus, 'synced');

      // Retry submission with the exact same client_event_id
      final retryRecord = await repo.recordAttendanceEvent(event, isOnline: true);
      expect(retryRecord.status, 'Checked In');
      expect(retryRecord.id, firstRecord.id);

      // Verify the server processed count is 1, not 2
      final history = await repo.getAttendanceHistory(forceRefresh: true);
      final matchingRecords = history.where(
        (r) => r.date == '2026-11-16' && r.checkInTime == event.timestamp,
      );
      expect(matchingRecords.length, 1);
    });

    test(
        'Assignment Required Test 3: Pending attendance survives local persistence and is synchronized in chronological order',
        () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final dbHelper = DatabaseHelper.instance;
      final repo = AttendanceRepository(
        apiService: apiService,
        dbHelper: dbHelper,
      );

      final checkInTime = DateTime.parse('2026-11-16T09:00:00Z');
      final checkOutTime = DateTime.parse('2026-11-16T17:30:00Z');

      // 1. Simulate check-in while OFFLINE
      final checkInEvent = AttendanceEvent(
        clientEventId: 'event-checkin-001',
        employeeId: 'EMP-001',
        eventType: 'check_in',
        timestamp: checkInTime,
        latitude: 12.9716,
        longitude: 77.5946,
      );
      final provisionalIn = await repo.recordAttendanceEvent(
        checkInEvent,
        isOnline: false,
      );
      expect(provisionalIn.status, 'Checked In');
      expect(provisionalIn.syncStatus, 'pending');

      // 2. Simulate check-out while OFFLINE
      final checkOutEvent = AttendanceEvent(
        clientEventId: 'event-checkout-002',
        employeeId: 'EMP-001',
        eventType: 'check_out',
        timestamp: checkOutTime,
        latitude: 12.9716,
        longitude: 77.5946,
      );
      final provisionalOut = await repo.recordAttendanceEvent(
        checkOutEvent,
        isOnline: false,
      );
      expect(provisionalOut.status, 'Checked Out');
      expect(provisionalOut.syncStatus, 'pending');

      // 3. Verify SQLite persistence survives (simulating app restart)
      final persistedPending = await repo.getPendingEvents();
      expect(persistedPending.length, 2);
      expect(persistedPending[0].clientEventId, 'event-checkin-001');
      expect(persistedPending[0].eventType, 'check_in');
      expect(persistedPending[1].clientEventId, 'event-checkout-002');
      expect(persistedPending[1].eventType, 'check_out');

      // Ensure chronological ordering
      expect(
        persistedPending[0].timestamp.isBefore(persistedPending[1].timestamp),
        isTrue,
      );

      // 4. Trigger Sync (reconnect online)
      final syncResult = await repo.syncPendingEvents();
      expect(syncResult.total, 2);
      expect(syncResult.synced, 2);
      expect(syncResult.hasErrors, isFalse);

      // 5. Verify pending queue in DB is now empty
      final remainingPending = await repo.getPendingEvents();
      expect(remainingPending.isEmpty, isTrue);

      // 6. Verify local record is updated to Synced
      final todayRecord = await DatabaseHelper.instance.getTodayAttendanceRecord('2026-11-16');
      expect(todayRecord?.syncStatus, 'synced');
      expect(todayRecord?.status, 'Checked Out');
      expect(todayRecord?.checkInTime, checkInTime);
      expect(todayRecord?.checkOutTime, checkOutTime);
    });

    test(
        'Server 409 Conflict: Attendance already exists marks event as rejected and saves reason',
        () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = AttendanceRepository(apiService: apiService);

      // Set scenario to trigger duplicate attendance conflict (409)
      MockScenarioManager.instance.setScenario(MockApiScenario.duplicateAttendanceConflict);

      final event = AttendanceEvent(
        clientEventId: 'event-conflict-uuid',
        employeeId: 'EMP-001',
        eventType: 'check_in',
        timestamp: DateTime.parse('2026-11-16T09:15:00Z'),
        latitude: 12.9716,
        longitude: 77.5946,
      );

      // Record offline first
      await repo.recordAttendanceEvent(event, isOnline: false);

      // Sync while server is returning 409 Conflict
      final syncResult = await repo.syncPendingEvents();
      expect(syncResult.total, 1);
      expect(syncResult.rejected, 1);
      expect(syncResult.synced, 0);

      // Verify DB record is marked rejected with message
      final todayRecord = await DatabaseHelper.instance.getTodayAttendanceRecord('2026-11-16');
      expect(todayRecord?.syncStatus, 'rejected');
      expect(todayRecord?.rejectionReason, contains('conflict'));
    });

    test('Temporary network drop keeps events in queue with incremented retry count',
        () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = AttendanceRepository(apiService: apiService);

      // Simulate server error (500)
      MockScenarioManager.instance.setScenario(MockApiScenario.serverError);

      final event = AttendanceEvent(
        clientEventId: 'event-retry-uuid',
        employeeId: 'EMP-001',
        eventType: 'check_in',
        timestamp: DateTime.parse('2026-11-16T09:30:00Z'),
        latitude: 12.9716,
        longitude: 77.5946,
      );

      await repo.recordAttendanceEvent(event, isOnline: false);

      // Sync attempt 1 (fails due to 500)
      final result1 = await repo.syncPendingEvents();
      expect(result1.failed, 1);
      expect(result1.synced, 0);

      // Event is still in queue
      var pending = await repo.getPendingEvents();
      expect(pending.length, 1);
      expect(pending.first.retryCount, 1);

      // Restore server to success
      MockScenarioManager.instance.setScenario(MockApiScenario.success);

      // Sync attempt 2 (now succeeds)
      final result2 = await repo.syncPendingEvents();
      expect(result2.synced, 1);
      expect(result2.failed, 0);

      // Queue is now empty
      pending = await repo.getPendingEvents();
      expect(pending.isEmpty, isTrue);
    });

    test('SyncProvider automatically triggers auto-sync on reconnect', () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = AttendanceRepository(apiService: apiService);
      final attendanceProvider = AttendanceProvider(repository: repo);
      final syncProvider = SyncProvider(connectivity: _FakeConnectivity());

      bool autoSyncCalled = false;
      syncProvider.registerAutoSyncCallback(() async {
        autoSyncCalled = true;
        await attendanceProvider.syncPending();
      });

      // 1. Simulate offline
      MockScenarioManager.instance.setSimulateOffline(true);
      expect(syncProvider.isOffline, isTrue);

      // 2. Perform check-in offline
      await repo.recordAttendanceEvent(
        AttendanceEvent(
          clientEventId: 'event-autosync-uuid',
          employeeId: 'EMP-001',
          eventType: 'check_in',
          timestamp: DateTime.now(),
          latitude: 12.9716,
          longitude: 77.5946,
        ),
        isOnline: false,
      );

      // 3. Switch back to online (trigger auto-sync)
      MockScenarioManager.instance.setSimulateOffline(false);
      expect(syncProvider.isOnline, isTrue);

      // Allow microtasks to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(autoSyncCalled, isTrue);
    });
  });
}
