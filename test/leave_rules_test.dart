import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/api/api.dart';
import 'package:hrms/data/local/database_helper.dart';
import 'package:hrms/data/providers/leave_provider.dart';
import 'package:hrms/data/repo/leave_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    MockScenarioManager.instance.reset();
    final db = await DatabaseHelper.instance.database;
    await db.delete('leave_requests');
    await db.delete('leave_balance_cache');
  });

  group('Phase 6: Leave Management & Application Rules Tests', () {
    test('Assignment Required Test 4: Overlapping leave dates are rejected',
        () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = LeaveRepository(apiService: apiService);
      final provider = LeaveProvider(repository: repo);

      // Load initial leave data
      await provider.loadLeaveData(forceRefresh: true);

      final now = DateTime.now();
      final baseDate = DateTime(now.year, now.month, now.day + 5);

      // 1. Submit initial approved/pending leave (Day 5 to Day 7)
      final firstRequest = await provider.submitLeaveRequest(
        employeeId: 'EMP-001',
        leaveType: 'casual',
        startDate: baseDate,
        endDate: baseDate.add(const Duration(days: 2)),
        reason: 'Attending family wedding ceremony',
        isOnline: true,
      );
      expect(firstRequest.status, 'pending');

      // 2. Attempt overlapping leave: completely inside (Day 6 to Day 6)
      final overlapInside = provider.validateLeaveRequest(
        leaveType: 'casual',
        startDate: baseDate.add(const Duration(days: 1)),
        endDate: baseDate.add(const Duration(days: 1)),
        reason: 'Valid length reason for testing',
      );
      expect(overlapInside.isValid, isFalse);
      expect(overlapInside.errorMessage, contains('overlap'));

      // 3. Attempt overlapping leave: spanning across start (Day 4 to Day 6)
      final overlapStart = provider.validateLeaveRequest(
        leaveType: 'casual',
        startDate: baseDate.subtract(const Duration(days: 1)),
        endDate: baseDate.add(const Duration(days: 1)),
        reason: 'Valid length reason for testing',
      );
      expect(overlapStart.isValid, isFalse);
      expect(overlapStart.errorMessage, contains('overlap'));

      // 4. Attempt overlapping leave: spanning across end (Day 6 to Day 8)
      final overlapEnd = provider.validateLeaveRequest(
        leaveType: 'sick',
        startDate: baseDate.add(const Duration(days: 1)),
        endDate: baseDate.add(const Duration(days: 3)),
        reason: 'Valid length reason for testing',
      );
      expect(overlapEnd.isValid, isFalse);
      expect(overlapEnd.errorMessage, contains('overlap'));

      // 5. Submit call should throw ValidationException for overlapping dates
      expect(
        () => provider.submitLeaveRequest(
          employeeId: 'EMP-001',
          leaveType: 'casual',
          startDate: baseDate.add(const Duration(days: 1)),
          endDate: baseDate.add(const Duration(days: 1)),
          reason: 'Valid length reason for testing',
          isOnline: true,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Leave request exceeding available balance is rejected', () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = LeaveRepository(apiService: apiService);
      final provider = LeaveProvider(repository: repo);

      await provider.loadLeaveData(forceRefresh: true);
      final availableCasual = provider.balance.casualLeaveAvailable.toInt();

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day + 10);
      // Request 1 more day than available
      final endDate = startDate.add(Duration(days: availableCasual));

      final validation = provider.validateLeaveRequest(
        leaveType: 'casual',
        startDate: startDate,
        endDate: endDate,
        reason: 'Requesting extended family holiday',
      );

      expect(validation.isValid, isFalse);
      expect(validation.errorMessage, contains('exceeds your available'));

      expect(
        () => provider.submitLeaveRequest(
          employeeId: 'EMP-001',
          leaveType: 'casual',
          startDate: startDate,
          endDate: endDate,
          reason: 'Requesting extended family holiday',
          isOnline: true,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Reason under 10 non-whitespace characters is rejected', () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = LeaveRepository(apiService: apiService);
      final provider = LeaveProvider(repository: repo);

      await provider.loadLeaveData(forceRefresh: true);
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 2);

      // Short reason ("Sick" = 4 chars)
      final shortReason = provider.validateLeaveRequest(
        leaveType: 'sick',
        startDate: futureDate,
        endDate: futureDate,
        reason: 'Sick',
      );
      expect(shortReason.isValid, isFalse);
      expect(shortReason.errorMessage, contains('at least 10 non-whitespace'));

      // Whitespace padding ("   sick   " = 4 non-whitespace chars)
      final paddedReason = provider.validateLeaveRequest(
        leaveType: 'sick',
        startDate: futureDate,
        endDate: futureDate,
        reason: '   sick   ',
      );
      expect(paddedReason.isValid, isFalse);
      expect(paddedReason.errorMessage, contains('at least 10 non-whitespace'));
    });

    test('Past date and reversed date range are rejected', () async {
      final provider = LeaveProvider();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      // Past start date
      final pastDate = provider.validateLeaveRequest(
        leaveType: 'casual',
        startDate: yesterday,
        endDate: tomorrow,
        reason: 'Family emergency yesterday',
      );
      expect(pastDate.isValid, isFalse);
      expect(pastDate.errorMessage, contains('cannot be in the past'));

      // Reversed range (endDate < startDate)
      final reversedRange = provider.validateLeaveRequest(
        leaveType: 'casual',
        startDate: tomorrow,
        endDate: today,
        reason: 'Valid 10+ characters reason',
      );
      expect(reversedRange.isValid, isFalse);
      expect(reversedRange.errorMessage, contains('earlier than start date'));
    });

    test('Leave submission while offline throws NetworkException', () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = LeaveRepository(apiService: apiService);
      final provider = LeaveProvider(repository: repo);

      await provider.loadLeaveData(forceRefresh: true);
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 5);

      expect(
        () => provider.submitLeaveRequest(
          employeeId: 'EMP-001',
          leaveType: 'casual',
          startDate: futureDate,
          endDate: futureDate,
          reason: 'Valid appointment reason',
          isOnline: false, // OFFLINE
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('Server validation rejection scenario returns proper error', () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = LeaveRepository(apiService: apiService);
      final provider = LeaveProvider(repository: repo);

      await provider.loadLeaveData(forceRefresh: true);

      // Trigger Reviewer scenario: Leave validation rejection (422)
      MockScenarioManager.instance.setScenario(MockApiScenario.leaveValidationRejection);

      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 15);

      expect(
        () => provider.submitLeaveRequest(
          employeeId: 'EMP-001',
          leaveType: 'casual',
          startDate: futureDate,
          endDate: futureDate,
          reason: 'Valid character count for leave application',
          isOnline: true,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Offline viewing loads cached leave requests from SQLite', () async {
      final mockClient = MockHttpClient();
      final apiService = ApiService(client: mockClient);
      final repo = LeaveRepository(apiService: apiService);
      final provider = LeaveProvider(repository: repo);

      // 1. Fetch online to seed SQLite cache
      await provider.loadLeaveData(forceRefresh: true);
      expect(provider.requests.isNotEmpty, isTrue);

      // 2. Read directly from SQLite cache
      final cachedRequests = await repo.getLeaveRequests(forceRefresh: false);
      expect(cachedRequests.length, provider.requests.length);

      final cachedBalance = await repo.getLeaveBalance(forceRefresh: false);
      expect(cachedBalance.casualLeaveAvailable, provider.balance.casualLeaveAvailable);
    });
  });
}
