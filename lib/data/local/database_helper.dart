import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../model/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rebs_hrms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Employee Cache Table
    await db.execute('''
      CREATE TABLE employee_cache (
        id INTEGER PRIMARY KEY,
        employee_id TEXT NOT NULL,
        name TEXT NOT NULL,
        department TEXT NOT NULL,
        office_latitude REAL NOT NULL,
        office_longitude REAL NOT NULL,
        geofence_radius_meters REAL NOT NULL,
        timezone TEXT NOT NULL,
        avatar_url TEXT
      )
    ''');

    // 2. Attendance Records (History & Cache)
    await db.execute('''
      CREATE TABLE attendance_records (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        date TEXT NOT NULL,
        check_in_time TEXT,
        check_out_time TEXT,
        status TEXT NOT NULL,
        duration_minutes INTEGER,
        sync_status TEXT NOT NULL,
        rejection_reason TEXT
      )
    ''');

    // 3. Pending Attendance Events Queue (survives app restart, FIFO)
    await db.execute('''
      CREATE TABLE pending_attendance_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_event_id TEXT UNIQUE NOT NULL,
        employee_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        sync_status TEXT NOT NULL,
        rejection_reason TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Leave Requests Table
    await db.execute('''
      CREATE TABLE leave_requests (
        id TEXT PRIMARY KEY,
        client_request_id TEXT NOT NULL,
        employee_id TEXT NOT NULL,
        leave_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        days_count INTEGER NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL,
        rejection_reason TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Leave Balance Cache Table
    await db.execute('''
      CREATE TABLE leave_balance_cache (
        id INTEGER PRIMARY KEY,
        casual_available REAL NOT NULL,
        casual_total REAL NOT NULL,
        sick_available REAL NOT NULL,
        sick_total REAL NOT NULL
      )
    ''');
  }

  // ================= Employee Cache =================
  Future<void> saveEmployee(Employee employee) async {
    final db = await database;
    await db.insert(
      'employee_cache',
      employee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Employee?> getEmployee() async {
    final db = await database;
    final results = await db.query('employee_cache', limit: 1);
    if (results.isNotEmpty) {
      return Employee.fromMap(results.first);
    }
    return null;
  }

  // ================= Attendance Records =================
  Future<void> saveAttendanceRecords(List<AttendanceRecord> records) async {
    final db = await database;
    for (final r in records) {
      // Don't overwrite local pending records for the same date with stale remote records
      final existingPending = await db.query(
        'attendance_records',
        where: 'date = ? AND sync_status = ?',
        whereArgs: [r.date, 'pending'],
      );
      if (existingPending.isEmpty) {
        await db.delete(
          'attendance_records',
          where: 'date = ?',
          whereArgs: [r.date],
        );
        await db.insert(
          'attendance_records',
          r.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> upsertAttendanceRecord(AttendanceRecord record) async {
    final db = await database;
    // Always remove existing rows for this date to ensure 1 atomic record per day
    await db.delete(
      'attendance_records',
      where: 'date = ? OR id = ?',
      whereArgs: [record.date, record.id],
    );
    await db.insert(
      'attendance_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttendanceRecord>> getAttendanceRecords({String? month}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (month != null && month.isNotEmpty) {
      whereClause = 'date LIKE ?';
      whereArgs = ['$month%'];
    }

    final results = await db.query(
      'attendance_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, check_out_time DESC, check_in_time DESC',
    );

    final List<AttendanceRecord> records = [];
    final Set<String> seenDates = {};
    for (final m in results) {
      final rec = AttendanceRecord.fromMap(m);
      if (!seenDates.contains(rec.date)) {
        seenDates.add(rec.date);
        records.add(rec);
      }
    }
    return records;
  }

  Future<List<AttendanceRecord>> getLatestAttendanceRecords({int limit = 5}) async {
    final db = await database;
    final results = await db.query(
      'attendance_records',
      orderBy: 'date DESC, check_out_time DESC, check_in_time DESC',
    );
    final List<AttendanceRecord> records = [];
    final Set<String> seenDates = {};
    for (final m in results) {
      final rec = AttendanceRecord.fromMap(m);
      if (!seenDates.contains(rec.date)) {
        seenDates.add(rec.date);
        records.add(rec);
        if (records.length >= limit) break;
      }
    }
    return records;
  }

  Future<AttendanceRecord?> getTodayAttendanceRecord(String date) async {
    final db = await database;
    final results = await db.query(
      'attendance_records',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'check_out_time DESC, check_in_time DESC',
      limit: 1,
    );
    if (results.isNotEmpty) {
      return AttendanceRecord.fromMap(results.first);
    }
    return null;
  }

  // ================= Pending Attendance Queue =================
  Future<int> queueAttendanceEvent(AttendanceEvent event) async {
    final db = await database;
    return await db.insert(
      'pending_attendance_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttendanceEvent>> getPendingAttendanceEvents() async {
    final db = await database;
    final results = await db.query(
      'pending_attendance_events',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC, id ASC', // strict FIFO ordering
    );
    return results.map((m) => AttendanceEvent.fromMap(m)).toList();
  }

  Future<List<AttendanceEvent>> getAllAttendanceEvents() async {
    final db = await database;
    final results = await db.query(
      'pending_attendance_events',
      orderBy: 'timestamp DESC',
    );
    return results.map((m) => AttendanceEvent.fromMap(m)).toList();
  }

  Future<void> updateAttendanceEventStatus(
    String clientEventId,
    String status, {
    String? rejectionReason,
  }) async {
    final db = await database;
    final Map<String, dynamic> values = {'sync_status': status};
    if (rejectionReason != null) {
      values['rejection_reason'] = rejectionReason;
    }
    await db.update(
      'pending_attendance_events',
      values,
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
    );
  }

  Future<void> incrementEventRetry(String clientEventId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE pending_attendance_events 
      SET retry_count = retry_count + 1 
      WHERE client_event_id = ?
    ''', [clientEventId]);
  }

  Future<void> deleteAttendanceEvent(String clientEventId) async {
    final db = await database;
    await db.delete(
      'pending_attendance_events',
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
    );
  }

  // ================= Leave Requests =================
  Future<void> saveLeaveRequests(List<LeaveRequest> requests) async {
    final db = await database;
    final batch = db.batch();
    for (final r in requests) {
      batch.insert(
        'leave_requests',
        r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertLeaveRequest(LeaveRequest request) async {
    final db = await database;
    await db.insert(
      'leave_requests',
      request.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LeaveRequest>> getLeaveRequests() async {
    final db = await database;
    final results = await db.query(
      'leave_requests',
      orderBy: 'created_at DESC, start_date DESC',
    );
    return results.map((m) => LeaveRequest.fromMap(m)).toList();
  }

  // ================= Leave Balance Cache =================
  Future<void> saveLeaveBalance(LeaveBalance balance) async {
    final db = await database;
    await db.insert(
      'leave_balance_cache',
      {'id': 1, ...balance.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LeaveBalance?> getLeaveBalance() async {
    final db = await database;
    final results = await db.query('leave_balance_cache', limit: 1);
    if (results.isNotEmpty) {
      return LeaveBalance.fromMap(results.first);
    }
    return null;
  }

  // ================= Reset / Cleanup =================
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('employee_cache');
    await db.delete('attendance_records');
    await db.delete('pending_attendance_events');
    await db.delete('leave_requests');
    await db.delete('leave_balance_cache');
  }
}
