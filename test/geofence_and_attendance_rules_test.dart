import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/api/api.dart';
import 'package:hrms/common/utils/location_service.dart';
import 'package:hrms/data/local/database_helper.dart';
import 'package:hrms/data/model/models.dart';
import 'package:hrms/data/providers/attendance_provider.dart';
import 'package:hrms/data/repo/attendance_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 4 - Geofencing & Attendance Business Rules', () {
    late DatabaseHelper dbHelper;
    late ApiService apiService;
    late AttendanceRepository repository;
    late AttendanceProvider attendanceProvider;
    late LocationService locationService;

    const testEmployee = Employee(
      id: 1,
      employeeId: 'EMP-878',
      name: 'Alex Smith',
      department: 'Engineering',
      officeLatitude: 12.9716,
      officeLongitude: 77.5946,
      geofenceRadiusMeters: 200.0,
      timezone: 'Asia/Kolkata',
    );

    setUp(() async {
      MockHttpClient.resetServerData();
      dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();

      apiService = ApiService(
        client: MockHttpClient(defaultLatency: Duration.zero),
      );

      repository = AttendanceRepository(
        apiService: apiService,
        dbHelper: dbHelper,
      );

      attendanceProvider = AttendanceProvider(repository: repository);
      locationService = LocationService.instance;
      locationService.setSimulationMode(LocationSimulationMode.atOffice);
    });

    test('Rule 1: Check-out without check-in is rejected', () async {
      await attendanceProvider.loadDashboardAttendance(forceRefresh: true);

      final result = await attendanceProvider.performCheckOut(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );

      expect(result.success, false);
      expect(
        result.message.contains('Cannot check out without an active check-in'),
        true,
      );
    });

    test('Rule 2: Geofence violation (>200m) blocks check-in with distance message', () async {
      await attendanceProvider.loadDashboardAttendance(forceRefresh: true);

      // Simulate employee being outside the 200m office zone (~550m away)
      locationService.setSimulationMode(LocationSimulationMode.outsideOffice);

      final result = await attendanceProvider.performCheckIn(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );

      expect(result.success, false);
      expect(result.message.contains('away from the office'), true);
      expect(result.message.contains('200m'), true);
      expect(result.geofenceResult?.isWithinGeofence, false);
    });

    test('Rule 3: Check-in within 200m succeeds and updates status', () async {
      await attendanceProvider.loadDashboardAttendance(forceRefresh: true);

      // Employee is at the office
      locationService.setSimulationMode(LocationSimulationMode.atOffice);

      final result = await attendanceProvider.performCheckIn(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );

      expect(result.success, true);
      expect(attendanceProvider.isCheckedIn, true);
      expect(attendanceProvider.todayRecord?.status, 'Checked In');
    });

    test('Rule 4: Check-in allowed only once per working day', () async {
      await attendanceProvider.loadDashboardAttendance(forceRefresh: true);
      locationService.setSimulationMode(LocationSimulationMode.atOffice);

      // First check-in
      final firstResult = await attendanceProvider.performCheckIn(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );
      expect(firstResult.success, true);

      // Second check-in on the same day must be rejected
      final secondResult = await attendanceProvider.performCheckIn(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );

      expect(secondResult.success, false);
      expect(
        secondResult.message.contains('already checked in for today'),
        true,
      );
    });

    test('Rule 5: Check-out permitted only after check-in and finishes session', () async {
      await attendanceProvider.loadDashboardAttendance(forceRefresh: true);
      locationService.setSimulationMode(LocationSimulationMode.atOffice);

      // 1. Check in
      await attendanceProvider.performCheckIn(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );

      // 2. Check out
      final checkoutResult = await attendanceProvider.performCheckOut(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );

      expect(checkoutResult.success, true);
      expect(attendanceProvider.isCheckedOut, true);
      expect(attendanceProvider.todayRecord?.status, 'Checked Out');
      expect(attendanceProvider.todayRecord?.checkOutTime != null, true);
    });

    test('Rule 6: Denied location permission displays meaningful user feedback', () async {
      await attendanceProvider.loadDashboardAttendance(forceRefresh: true);
      locationService.setSimulationMode(LocationSimulationMode.permissionDenied);

      final result = await attendanceProvider.performCheckIn(
        employee: testEmployee,
        isOnline: true,
        locationService: locationService,
      );

      expect(result.success, false);
      expect(result.message.contains('permission was denied'), true);
    });
  });
}
