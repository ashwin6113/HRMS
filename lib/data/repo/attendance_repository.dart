import 'package:intl/intl.dart';
import '../../api/api.dart';
import '../local/database_helper.dart';
import '../model/models.dart';

class AttendanceRepository {
  final ApiService apiService;
  final DatabaseHelper dbHelper;

  AttendanceRepository({
    ApiService? apiService,
    DatabaseHelper? dbHelper,
  })  : apiService = apiService ?? ApiService(),
        dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<AttendanceRecord>> getAttendanceHistory({
    String? month,
    bool forceRefresh = false,
  }) async {
    // 1. Check local cache first if not forced
    if (!forceRefresh) {
      final cached = await dbHelper.getAttendanceRecords(month: month);
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    // 2. Fetch from API and update local cache
    try {
      final remoteList = await apiService.getAttendanceHistory(month: month);
      await dbHelper.saveAttendanceRecords(remoteList);
      return remoteList;
    } catch (e) {
      // 3. Fallback to cache on error / offline
      return await dbHelper.getAttendanceRecords(month: month);
    }
  }

  Future<List<AttendanceRecord>> getLatestAttendance({int limit = 5}) async {
    return await dbHelper.getLatestAttendanceRecords(limit: limit);
  }

  Future<AttendanceRecord?> getTodayAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await dbHelper.getTodayAttendanceRecord(today);
  }

  /// Processes check-in or check-out, supporting offline queuing
  Future<AttendanceRecord> recordAttendanceEvent(
    AttendanceEvent event, {
    required bool isOnline,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(event.timestamp);

    // If Offline: Queue locally with PENDING status
    if (!isOnline) {
      await dbHelper.queueAttendanceEvent(event.copyWith(syncStatus: 'pending'));

      final current = await dbHelper.getTodayAttendanceRecord(today);
      final isCheckIn = event.eventType == 'check_in';

      final provisionalRecord = AttendanceRecord(
        id: current?.id ?? 'pending-${event.clientEventId}',
        employeeId: event.employeeId,
        date: today,
        checkInTime: isCheckIn ? event.timestamp : current?.checkInTime,
        checkOutTime: isCheckIn ? null : event.timestamp,
        status: isCheckIn ? 'Checked In' : 'Checked Out',
        durationMinutes: !isCheckIn && current?.checkInTime != null
            ? event.timestamp.difference(current!.checkInTime!).inMinutes
            : (current?.durationMinutes ?? 0),
        syncStatus: 'pending',
      );

      await dbHelper.upsertAttendanceRecord(provisionalRecord);
      return provisionalRecord;
    }

    // If Online: Submit directly to API
    try {
      final record = await apiService.submitAttendanceEvent(event);
      await dbHelper.upsertAttendanceRecord(record.copyWith(syncStatus: 'synced'));
      return record;
    } on ConflictException catch (e) {
      // Server rejected due to conflict
      await dbHelper.queueAttendanceEvent(
        event.copyWith(syncStatus: 'rejected', rejectionReason: e.message),
      );
      rethrow;
    } catch (e) {
      // Network drop or timeout: queue locally for sync retry
      await dbHelper.queueAttendanceEvent(event.copyWith(syncStatus: 'pending'));

      final current = await dbHelper.getTodayAttendanceRecord(today);
      final isCheckIn = event.eventType == 'check_in';

      final fallbackRecord = AttendanceRecord(
        id: current?.id ?? 'pending-${event.clientEventId}',
        employeeId: event.employeeId,
        date: today,
        checkInTime: isCheckIn ? event.timestamp : current?.checkInTime,
        checkOutTime: isCheckIn ? null : event.timestamp,
        status: isCheckIn ? 'Checked In' : 'Checked Out',
        syncStatus: 'pending',
      );

      await dbHelper.upsertAttendanceRecord(fallbackRecord);
      return fallbackRecord;
    }
  }

  Future<List<AttendanceEvent>> getPendingEvents() async {
    return await dbHelper.getPendingAttendanceEvents();
  }

  /// Synchronizes all pending attendance events strictly in chronological FIFO order
  Future<SyncResult> syncPendingEvents() async {
    final pendingEvents = await dbHelper.getPendingAttendanceEvents();
    if (pendingEvents.isEmpty) {
      return const SyncResult(total: 0, synced: 0, rejected: 0, failed: 0);
    }

    int syncedCount = 0;
    int rejectedCount = 0;
    int failedCount = 0;

    for (final event in pendingEvents) {
      try {
        final record = await apiService.submitAttendanceEvent(event);
        await dbHelper.updateAttendanceEventStatus(
          event.clientEventId,
          'synced',
        );
        await dbHelper.upsertAttendanceRecord(record.copyWith(syncStatus: 'synced'));
        syncedCount++;
      } on ConflictException catch (e) {
        // Attendance already exists on server -> mark rejected
        await dbHelper.updateAttendanceEventStatus(
          event.clientEventId,
          'rejected',
          rejectionReason: e.message,
        );
        final today = event.timestamp.toIso8601String().substring(0, 10);
        final existingRecord = await dbHelper.getTodayAttendanceRecord(today);
        if (existingRecord != null && existingRecord.syncStatus == 'pending') {
          await dbHelper.upsertAttendanceRecord(
            existingRecord.copyWith(
              syncStatus: 'rejected',
              rejectionReason: e.message,
            ),
          );
        }
        rejectedCount++;
      } catch (e) {
        // Temporary failure: increment retry count and keep in queue
        await dbHelper.incrementEventRetry(event.clientEventId);
        failedCount++;
      }
    }

    return SyncResult(
      total: pendingEvents.length,
      synced: syncedCount,
      rejected: rejectedCount,
      failed: failedCount,
    );
  }
}

class SyncResult {
  final int total;
  final int synced;
  final int rejected;
  final int failed;

  const SyncResult({
    required this.total,
    required this.synced,
    required this.rejected,
    required this.failed,
  });

  bool get hasErrors => failed > 0 || rejected > 0;
}
