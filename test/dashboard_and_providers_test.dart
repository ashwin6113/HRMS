import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/api/api.dart';
import 'package:hrms/data/local/database_helper.dart';
import 'package:hrms/data/model/models.dart';
import 'package:hrms/data/providers/attendance_provider.dart';
import 'package:hrms/data/providers/employee_provider.dart';
import 'package:hrms/data/repo/attendance_repository.dart';
import 'package:hrms/data/repo/employee_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 3 - Employee Dashboard & Providers', () {
    late ApiService apiService;
    late DatabaseHelper dbHelper;
    late EmployeeProvider employeeProvider;
    late AttendanceProvider attendanceProvider;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();

      apiService = ApiService(
        client: MockHttpClient(defaultLatency: Duration.zero),
      );

      final employeeRepo = EmployeeRepository(
        apiService: apiService,
        dbHelper: dbHelper,
      );
      final attendanceRepo = AttendanceRepository(
        apiService: apiService,
        dbHelper: dbHelper,
      );

      employeeProvider = EmployeeProvider(repository: employeeRepo);
      attendanceProvider = AttendanceProvider(repository: attendanceRepo);
    });

    test('EmployeeProvider loads employee and caches to SQLite', () async {
      await employeeProvider.loadEmployee(forceRefresh: true);

      expect(employeeProvider.employee?.employeeId, 'EMP-878');
      expect(employeeProvider.employee?.name, 'Alex Smith');
      expect(employeeProvider.employee?.department, 'Engineering');

      // Check SQLite cache
      final cached = await dbHelper.getEmployee();
      expect(cached?.name, 'Alex Smith');
    });

    test('AttendanceProvider loads dashboard and tracks status correctly', () async {
      await attendanceProvider.loadDashboardAttendance(forceRefresh: true);

      expect(attendanceProvider.todayStatus, 'Not Checked In');
      expect(attendanceProvider.isCheckedIn, false);
      expect(attendanceProvider.latestRecords.isNotEmpty, true);
    });

    test('AttendanceProvider calculates elapsed working duration when checked in', () async {
      final now = DateTime.now().subtract(const Duration(hours: 2, minutes: 15));

      final checkInEvent = AttendanceEvent(
        clientEventId: 'dash-checkin-1',
        employeeId: 'EMP-878',
        eventType: 'check_in',
        timestamp: now,
        latitude: 12.9716,
        longitude: 77.5946,
        createdAt: now,
      );

      await attendanceProvider.recordEvent(checkInEvent, isOnline: true);

      expect(attendanceProvider.isCheckedIn, true);
      expect(attendanceProvider.todayStatus, 'Checked In');
      expect(attendanceProvider.elapsedDuration.inHours >= 2, true);
      expect(attendanceProvider.formattedElapsedDuration.contains('02h'), true);
    });

    test('AttendanceProvider records offline event into pending queue', () async {
      final now = DateTime.now();

      final offlineEvent = AttendanceEvent(
        clientEventId: 'dash-offline-event-1',
        employeeId: 'EMP-878',
        eventType: 'check_in',
        timestamp: now,
        latitude: 12.9716,
        longitude: 77.5946,
        createdAt: now,
      );

      await attendanceProvider.recordEvent(offlineEvent, isOnline: false);

      expect(attendanceProvider.todayRecord?.syncStatus, 'pending');
      expect(attendanceProvider.pendingEvents.length, 1);
      expect(attendanceProvider.pendingEvents.first.clientEventId, 'dash-offline-event-1');
    });
  });
}
