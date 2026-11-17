import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/api/api.dart';
import 'package:hrms/data/model/models.dart';

void main() {
  group('Phase 2 - Mock API & Repeatable Scenarios', () {
    late MockScenarioManager scenarioManager;
    late MockHttpClient mockClient;
    late ApiService apiService;

    setUp(() {
      scenarioManager = MockScenarioManager.instance;
      scenarioManager.resetToSuccess();
      mockClient = MockHttpClient(
        scenarioManager: scenarioManager,
        defaultLatency: Duration.zero,
      );
      apiService = ApiService(client: mockClient);
    });

    test('GET /employee/me returns preconfigured employee', () async {
      final employee = await apiService.getEmployeeMe();

      expect(employee.employeeId, 'EMP-878');
      expect(employee.name, 'Alex Smith');
      expect(employee.department, 'Engineering');
      expect(employee.officeLatitude, 12.9716);
      expect(employee.geofenceRadiusMeters, 200.0);
    });

    test('GET /attendance returns seeded history', () async {
      final history = await apiService.getAttendanceHistory();

      expect(history.isNotEmpty, true);
      expect(history.length >= 5, true);
    });

    test('POST /attendance/events check-in and checkout cycle', () async {
      final now = DateTime.now();

      // 1. Check in
      final checkInEvent = AttendanceEvent(
        clientEventId: 'test-checkin-uuid-1',
        employeeId: 'EMP-878',
        eventType: 'check_in',
        timestamp: now,
        latitude: 12.9716,
        longitude: 77.5946,
        createdAt: now,
      );

      final record = await apiService.submitAttendanceEvent(checkInEvent);
      expect(record.status, 'Checked In');
      expect(record.checkInTime != null, true);

      // 2. Check out
      final checkOutEvent = AttendanceEvent(
        clientEventId: 'test-checkout-uuid-1',
        employeeId: 'EMP-878',
        eventType: 'check_out',
        timestamp: now.add(const Duration(minutes: 30)),
        latitude: 12.9716,
        longitude: 77.5946,
        createdAt: now.add(const Duration(minutes: 30)),
      );

      final updatedRecord = await apiService.submitAttendanceEvent(checkOutEvent);
      expect(updatedRecord.status, 'Checked Out');
      expect(updatedRecord.checkOutTime != null, true);
    });

    test('POST /attendance/events enforces idempotency on clientEventId', () async {
      final now = DateTime.now();
      const eventId = 'idempotent-event-123';

      final event = AttendanceEvent(
        clientEventId: eventId,
        employeeId: 'EMP-878',
        eventType: 'check_in',
        timestamp: now,
        latitude: 12.9716,
        longitude: 77.5946,
        createdAt: now,
      );

      final firstResponse = await apiService.submitAttendanceEvent(event);
      // Resend identical event
      final secondResponse = await apiService.submitAttendanceEvent(event);

      expect(firstResponse.id, secondResponse.id);
      expect(firstResponse.date, secondResponse.date);
    });

    test('Scenario: Server Error (500) throws ServerException', () async {
      scenarioManager.setScenario(MockApiScenario.serverError);

      expect(
        () => apiService.getEmployeeMe(),
        throwsA(isA<ServerException>()),
      );
    });

    test('Scenario: Duplicate attendance conflict (409) throws ConflictException', () async {
      scenarioManager.setScenario(MockApiScenario.duplicateAttendanceConflict);

      final event = AttendanceEvent(
        clientEventId: 'conflict-event-1',
        employeeId: 'EMP-878',
        eventType: 'check_in',
        timestamp: DateTime.now(),
        latitude: 12.9716,
        longitude: 77.5946,
        createdAt: DateTime.now(),
      );

      expect(
        () => apiService.submitAttendanceEvent(event),
        throwsA(isA<ConflictException>()),
      );
    });

    test('Scenario: Leave validation rejection (422) throws ValidationException', () async {
      scenarioManager.setScenario(MockApiScenario.leaveValidationRejection);

      final request = LeaveRequest(
        id: 'req-1',
        clientRequestId: 'client-req-1',
        employeeId: 'EMP-878',
        leaveType: 'sick',
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        daysCount: 2,
        reason: 'Medical checkup and procedure',
        createdAt: DateTime.now(),
      );

      expect(
        () => apiService.submitLeaveRequest(request),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Scenario: Simulated network offline throws NetworkException', () async {
      scenarioManager.setSimulateOffline(true);

      expect(
        () => apiService.getEmployeeMe(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
