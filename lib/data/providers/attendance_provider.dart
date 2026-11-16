import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../model/models.dart';
import '../repo/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;

  AttendanceRecord? _todayRecord;
  List<AttendanceRecord> _latestRecords = [];
  List<AttendanceEvent> _pendingEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _durationTimer;
  Duration _elapsedDuration = Duration.zero;

  AttendanceProvider({AttendanceRepository? repository})
      : repository = repository ?? AttendanceRepository();

  AttendanceRecord? get todayRecord => _todayRecord;
  List<AttendanceRecord> get latestRecords => _latestRecords;
  List<AttendanceEvent> get pendingEvents => _pendingEvents;
  bool get isLoading => _isLoading;
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
