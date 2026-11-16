import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../common/utils/location_service.dart';
import '../model/models.dart';
import '../repo/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;
  final Uuid _uuid = const Uuid();

  AttendanceRecord? _todayRecord;
  List<AttendanceRecord> _latestRecords = [];
  List<AttendanceEvent> _pendingEvents = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  Timer? _durationTimer;
  Duration _elapsedDuration = Duration.zero;

  AttendanceProvider({AttendanceRepository? repository})
      : repository = repository ?? AttendanceRepository();

  AttendanceRecord? get todayRecord => _todayRecord;
  List<AttendanceRecord> get latestRecords => _latestRecords;
  List<AttendanceEvent> get pendingEvents => _pendingEvents;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  Duration get elapsedDuration => _elapsedDuration;

  String get todayStatus => _todayRecord?.status ?? 'Not Checked In';
  bool get isCheckedIn => todayStatus == 'Checked In';
  bool get isCheckedOut => todayStatus == 'Checked Out';
  bool get isNotCheckedIn => todayStatus == 'Not Checked In';

  String get formattedElapsedDuration {
    final hours = _elapsedDuration.inHours.toString().padLeft(2, '0');
    final minutes =
        (_elapsedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
        (_elapsedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m ${seconds}s';
  }

  Future<void> loadDashboardAttendance({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch remote history to keep local SQLite fresh
      await repository.getAttendanceHistory(forceRefresh: forceRefresh);

      // 2. Load today's record from local persistence
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _todayRecord = await repository.getTodayAttendance() ??
          AttendanceRecord(
            id: 'today-$todayStr',
            employeeId: 'EMP-878',
            date: todayStr,
            status: 'Not Checked In',
            syncStatus: 'synced',
          );

      // 3. Load latest 5 records
      _latestRecords = await repository.getLatestAttendance(limit: 5);

      // 4. Load pending events
      _pendingEvents = await repository.getPendingEvents();

      // 5. Update elapsed duration timer if checked in
      _updateTimerState();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateTimerState() {
    _durationTimer?.cancel();

    if (_todayRecord != null &&
        _todayRecord!.status == 'Checked In' &&
        _todayRecord!.checkInTime != null) {
      _calculateElapsed();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _calculateElapsed();
        notifyListeners();
      });
    } else if (_todayRecord != null &&
        _todayRecord!.status == 'Checked Out' &&
        _todayRecord!.checkInTime != null &&
        _todayRecord!.checkOutTime != null) {
      _elapsedDuration = _todayRecord!.checkOutTime!
          .difference(_todayRecord!.checkInTime!);
    } else {
      _elapsedDuration = Duration.zero;
    }
  }

  void _calculateElapsed() {
    if (_todayRecord?.checkInTime != null) {
      _elapsedDuration = DateTime.now().difference(_todayRecord!.checkInTime!);
      if (_elapsedDuration.isNegative) {
        _elapsedDuration = Duration.zero;
      }
    }
  }

  // ================= Geofenced Check-In =================
  Future<AttendanceActionResult> performCheckIn({
    required Employee employee,
    required bool isOnline,
    LocationService? locationService,
  }) async {
    // 1. Debounce / tap lock to prevent duplicate attendance events
    if (_isProcessing) {
      return const AttendanceActionResult(
        success: false,
        message: 'Action in progress, please wait...',
      );
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // 2. Rule: Check-in allowed only once per working day
      if (_todayRecord != null && _todayRecord!.checkInTime != null) {
        return const AttendanceActionResult(
          success: false,
          message: 'You have already checked in for today.',
        );
      }

      // 3. Rule: Check geofence within 200m of office coordinates
      final loc = locationService ?? LocationService.instance;
      final geofenceResult = await loc.checkGeofence(
        officeLatitude: employee.officeLatitude,
        officeLongitude: employee.officeLongitude,
        allowedRadiusMeters: employee.geofenceRadiusMeters,
      );

      if (!geofenceResult.isWithinGeofence) {
        return AttendanceActionResult(
          success: false,
          message: geofenceResult.errorMessage ??
              'You are outside the permitted office attendance zone.',
          geofenceResult: geofenceResult,
        );
      }

      // 4. Create atomic event with unique client_event_id
      final event = AttendanceEvent(
        clientEventId: _uuid.v4(),
        employeeId: employee.employeeId,
        eventType: 'check_in',
        timestamp: DateTime.now(),
        latitude: geofenceResult.currentLatitude,
        longitude: geofenceResult.currentLongitude,
        createdAt: DateTime.now(),
      );

      // 5. Submit or queue offline
      final record = await recordEvent(event, isOnline: isOnline);

      return AttendanceActionResult(
        success: true,
        message: isOnline
            ? 'Checked In successfully!'
            : 'Checked In saved offline. Will sync when connection returns.',
        record: record,
        geofenceResult: geofenceResult,
      );
    } catch (e) {
      return AttendanceActionResult(
        success: false,
        message: 'Check-In failed: $e',
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ================= Geofenced Check-Out =================
  Future<AttendanceActionResult> performCheckOut({
    required Employee employee,
    required bool isOnline,
    LocationService? locationService,
  }) async {
    // 1. Debounce / tap lock
    if (_isProcessing) {
      return const AttendanceActionResult(
        success: false,
        message: 'Action in progress, please wait...',
      );
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // 2. Rule: Check-out is permitted only after check-in
      if (_todayRecord == null || _todayRecord!.checkInTime == null) {
        return const AttendanceActionResult(
          success: false,
          message: 'Cannot check out without an active check-in for today.',
        );
      }

      // 3. Rule: Already checked out
      if (_todayRecord!.checkOutTime != null) {
        return const AttendanceActionResult(
          success: false,
          message: 'You have already checked out for today.',
        );
      }

      // 4. Rule: Check geofence within 200m of office coordinates
      final loc = locationService ?? LocationService.instance;
      final geofenceResult = await loc.checkGeofence(
        officeLatitude: employee.officeLatitude,
        officeLongitude: employee.officeLongitude,
        allowedRadiusMeters: employee.geofenceRadiusMeters,
      );

      if (!geofenceResult.isWithinGeofence) {
        return AttendanceActionResult(
          success: false,
          message: geofenceResult.errorMessage ??
              'You are outside the permitted office attendance zone.',
          geofenceResult: geofenceResult,
        );
      }

      // 5. Create atomic check-out event
      final event = AttendanceEvent(
        clientEventId: _uuid.v4(),
        employeeId: employee.employeeId,
        eventType: 'check_out',
        timestamp: DateTime.now(),
        latitude: geofenceResult.currentLatitude,
        longitude: geofenceResult.currentLongitude,
        createdAt: DateTime.now(),
      );

      // 6. Submit or queue offline
      final record = await recordEvent(event, isOnline: isOnline);

      final durationMinutes = record.durationMinutes ?? 0;
      final durationStr =
          '${durationMinutes ~/ 60}h ${durationMinutes % 60}m';

      return AttendanceActionResult(
        success: true,
        message: isOnline
            ? 'Checked Out successfully! Total duration: $durationStr'
            : 'Checked Out saved offline. Will sync when connection returns.',
        record: record,
        geofenceResult: geofenceResult,
      );
    } catch (e) {
      return AttendanceActionResult(
        success: false,
        message: 'Check-Out failed: $e',
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<AttendanceRecord> recordEvent(
    AttendanceEvent event, {
    required bool isOnline,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final record = await repository.recordAttendanceEvent(
        event,
        isOnline: isOnline,
      );

      _todayRecord = record;
      _latestRecords = await repository.getLatestAttendance(limit: 5);
      _pendingEvents = await repository.getPendingEvents();
      _updateTimerState();

      return record;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SyncResult> syncPending() async {
    final result = await repository.syncPendingEvents();
    await loadDashboardAttendance(forceRefresh: false);
    return result;
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}

class AttendanceActionResult {
  final bool success;
  final String message;
  final AttendanceRecord? record;
  final GeofenceCheckResult? geofenceResult;

  const AttendanceActionResult({
    required this.success,
    required this.message,
    this.record,
    this.geofenceResult,
  });
}
