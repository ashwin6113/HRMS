import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'mock_api_scenario.dart';

class MockHttpClient extends http.BaseClient {
  static const String baseUrl = 'https://api.rebs-hrms.local';

  final MockScenarioManager scenarioManager;
  final Duration defaultLatency;

  // In-memory state simulating server database
  static final Map<String, dynamic> _employeeData = {
    'id': 1,
    'employee_id': 'EMP-878',
    'name': 'Alex Smith',
    'department': 'Engineering',
    'office_latitude': 12.9716,
    'office_longitude': 77.5946,
    'geofence_radius_meters': 200.0,
    'timezone': 'Asia/Kolkata',
    'avatar_url': null,
  };

  static final Map<String, dynamic> _leaveBalance = {
    'casual_available': 10.0,
    'casual_total': 14.0,
    'sick_available': 7.0,
    'sick_total': 10.0,
  };

  static final List<Map<String, dynamic>> _attendanceRecords = [];
  static final List<Map<String, dynamic>> _leaveRequests = [];

  // Track processed client_event_id for Idempotency
  static final Map<String, Map<String, dynamic>> _processedEventMap = {};

  MockHttpClient({
    MockScenarioManager? scenarioManager,
    this.defaultLatency = const Duration(milliseconds: 250),
  }) : scenarioManager = scenarioManager ?? MockScenarioManager.instance {
    _seedInitialData();
  }

  static void resetServerData() {
    _attendanceRecords.clear();
    _leaveRequests.clear();
    _processedEventMap.clear();
    _leaveBalance['casual_available'] = 10.0;
    _leaveBalance['casual_total'] = 14.0;
    _leaveBalance['sick_available'] = 7.0;
    _leaveBalance['sick_total'] = 10.0;
    MockHttpClient()._seedInitialData();
  }

  void _seedInitialData() {
    if (_attendanceRecords.isNotEmpty) return;
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

    // Seed 5 past days of attendance history (excluding today and yesterday)
    for (int i = 6; i >= 2; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = formatter.format(date);
      final checkIn = DateTime(date.year, date.month, date.day, 9, 15);
      final checkOut = DateTime(date.year, date.month, date.day, 18, 30);

      _attendanceRecords.add({
        'id': 'att-$i',
        'employee_id': 'EMP-878',
        'date': dateStr,
        'check_in_time': checkIn.toIso8601String(),
        'check_out_time': checkOut.toIso8601String(),
        'status': 'Checked Out',
        'duration_minutes': 555,
        'sync_status': 'synced',
      });
    }

    // Seed sample leave requests
    _leaveRequests.add({
      'id': 'leave-1',
      'client_request_id': 'seed-req-1',
      'employee_id': 'EMP-878',
      'leave_type': 'sick',
      'start_date': formatter.format(now.subtract(const Duration(days: 14))),
      'end_date': formatter.format(now.subtract(const Duration(days: 13))),
      'days_count': 2,
      'reason': 'Viral fever and prescribed medical rest',
      'status': 'approved',
      'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
    });

    _leaveRequests.add({
      'id': 'leave-2',
      'client_request_id': 'seed-req-2',
      'employee_id': 'EMP-878',
      'leave_type': 'casual',
      'start_date': formatter.format(now.subtract(const Duration(days: 28))),
      'end_date': formatter.format(now.subtract(const Duration(days: 28))),
      'days_count': 1,
      'reason': 'Family emergency travel to hometown',
      'status': 'approved',
      'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
    });
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final scenario = scenarioManager.currentScenario;

    // Check simulated offline mode
    if (scenarioManager.isSimulateOffline ||
        scenario == MockApiScenario.networkOffline) {
      throw http.ClientException(
          'Simulated network offline: Connection refused', request.url);
    }

    // Check slow response scenario
    if (scenario == MockApiScenario.slowResponse) {
      await Future.delayed(const Duration(seconds: 8));
    } else {
      await Future.delayed(defaultLatency);
    }

    // Check 500 Server Error scenario
    if (scenario == MockApiScenario.serverError) {
      return _jsonResponse(
        statusCode: 500,
        body: {'error': 'Internal server error', 'code': 'INTERNAL_ERROR'},
      );
    }

    final path = request.url.path;
    final method = request.method.toUpperCase();

    // 1. GET /employee/me
    if (method == 'GET' && (path == '/employee/me' || path.endsWith('/employee/me'))) {
      return _jsonResponse(statusCode: 200, body: _employeeData);
    }

    // 2. GET /attendance (with optional month=YYYY-MM)
    if (method == 'GET' && (path == '/attendance' || path.endsWith('/attendance'))) {
      final month = request.url.queryParameters['month'];
      var list = _attendanceRecords;
      if (month != null && month.isNotEmpty) {
        list = list.where((r) => (r['date'] as String).startsWith(month)).toList();
      }
      return _jsonResponse(statusCode: 200, body: list);
    }

    // 3. POST /attendance/events
    if (method == 'POST' && (path == '/attendance/events' || path.endsWith('/attendance/events'))) {
      if (scenario == MockApiScenario.duplicateAttendanceConflict) {
        return _jsonResponse(
          statusCode: 409,
          body: {
            'error': 'Duplicate attendance event conflict.',
            'code': 'ATTENDANCE_ALREADY_EXISTS',
          },
        );
      }

      String bodyString = '';
      if (request is http.Request) {
        bodyString = request.body;
      }
      final payload = jsonDecode(bodyString) as Map<String, dynamic>;
      final clientEventId = payload['client_event_id'] as String? ?? '';
      final eventType = payload['event_type'] as String? ?? 'check_in';
      final timestampStr = payload['timestamp'] as String;
      final eventTime = DateTime.parse(timestampStr);
      final dateStr = DateFormat('yyyy-MM-dd').format(eventTime);

      // Check existing record for this date
      final existingIndex =
          _attendanceRecords.indexWhere((r) => r['date'] == dateStr);

      // IDEMPOTENCY CHECK:
      // If we already processed this client_event_id, return cached response
      if (_processedEventMap.containsKey(clientEventId)) {
        return _jsonResponse(
          statusCode: 200,
          body: _processedEventMap[clientEventId]!,
        );
      }

      if (eventType == 'check_in') {
        if (existingIndex != -1 &&
            _attendanceRecords[existingIndex]['check_in_time'] != null) {
          return _jsonResponse(
            statusCode: 409,
            body: {
              'error': 'Attendance check-in already recorded for this working day.',
              'code': 'ALREADY_CHECKED_IN',
            },
          );
        }

        final newRecord = {
          'id': 'att-${DateTime.now().millisecondsSinceEpoch}',
          'employee_id': _employeeData['employee_id'],
          'date': dateStr,
          'check_in_time': eventTime.toIso8601String(),
          'check_out_time': null,
          'status': 'Checked In',
          'duration_minutes': 0,
          'sync_status': 'synced',
        };

        if (existingIndex != -1) {
          _attendanceRecords[existingIndex] = newRecord;
        } else {
          _attendanceRecords.insert(0, newRecord);
        }

        _processedEventMap[clientEventId] = newRecord;
        return _jsonResponse(statusCode: 201, body: newRecord);
      } else if (eventType == 'check_out') {
        if (existingIndex == -1 ||
            _attendanceRecords[existingIndex]['check_in_time'] == null) {
          // If check-in record is not found in mock memory (e.g. app restart or client synced check-out),
          // synthesize/preserve check-in at 09:00 AM (or 1h before check-out) so offline sync succeeds gracefully.
          final defaultCheckIn = DateTime(
            eventTime.year,
            eventTime.month,
            eventTime.day,
            9,
            0,
          );
          final checkInTime = eventTime.isAfter(defaultCheckIn)
              ? defaultCheckIn
              : eventTime.subtract(const Duration(hours: 1));
          final durationMinutes = eventTime.difference(checkInTime).inMinutes;

          final newRecord = {
            'id': 'att-${DateTime.now().millisecondsSinceEpoch}',
            'employee_id': _employeeData['employee_id'],
            'date': dateStr,
            'check_in_time': checkInTime.toIso8601String(),
            'check_out_time': eventTime.toIso8601String(),
            'status': 'Checked Out',
            'duration_minutes': durationMinutes > 0 ? durationMinutes : 0,
            'sync_status': 'synced',
          };

          if (existingIndex != -1) {
            _attendanceRecords[existingIndex] = newRecord;
          } else {
            _attendanceRecords.insert(0, newRecord);
          }

          _processedEventMap[clientEventId] = newRecord;
          return _jsonResponse(statusCode: 200, body: newRecord);
        }

        final existing = _attendanceRecords[existingIndex];
        final checkInTime = DateTime.parse(existing['check_in_time'] as String);
        final durationMinutes = eventTime.difference(checkInTime).inMinutes;

        final updatedRecord = {
          ...existing,
          'check_out_time': eventTime.toIso8601String(),
          'status': 'Checked Out',
          'duration_minutes': durationMinutes > 0 ? durationMinutes : 0,
          'sync_status': 'synced',
        };

        _attendanceRecords[existingIndex] = updatedRecord;
        _processedEventMap[clientEventId] = updatedRecord;
        return _jsonResponse(statusCode: 200, body: updatedRecord);
      }
    }

    // 4. GET /leave/balance
    if (method == 'GET' && (path == '/leave/balance' || path.endsWith('/leave/balance'))) {
      return _jsonResponse(statusCode: 200, body: _leaveBalance);
    }

    // 5. GET /leave/requests
    if (method == 'GET' && (path == '/leave/requests' || path.endsWith('/leave/requests'))) {
      return _jsonResponse(statusCode: 200, body: _leaveRequests);
    }

    // 6. POST /leave/requests
    if (method == 'POST' && (path == '/leave/requests' || path.endsWith('/leave/requests'))) {
      if (scenario == MockApiScenario.leaveValidationRejection) {
        return _jsonResponse(
          statusCode: 422,
          body: {
            'error': 'Leave application rejected: Policy constraint violated.',
            'code': 'LEAVE_POLICY_VIOLATION',
          },
        );
      }

      String bodyString = '';
      if (request is http.Request) {
        bodyString = request.body;
      }
      final payload = jsonDecode(bodyString) as Map<String, dynamic>;
      final leaveType = payload['leave_type'] as String? ?? 'casual';
      final startDateStr = payload['start_date'] as String;
      final endDateStr = payload['end_date'] as String;
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);
      final daysCount = (payload['days_count'] as int?) ??
          endDate.difference(startDate).inDays + 1;
      final reason = payload['reason'] as String? ?? '';

      // Server-side validation: Reason length >= 10 non-whitespace characters
      if (reason.replaceAll(RegExp(r'\s+'), '').length < 10) {
        return _jsonResponse(
          statusCode: 422,
          body: {
            'error': 'Reason must contain at least 10 non-whitespace characters.',
            'code': 'INVALID_REASON',
          },
        );
      }

      // Server-side validation: Available balance check
      final available = (leaveType == 'sick')
          ? (_leaveBalance['sick_available'] as num).toDouble()
          : (_leaveBalance['casual_available'] as num).toDouble();

      if (daysCount > available) {
        return _jsonResponse(
          statusCode: 422,
          body: {
            'error': 'Requested days ($daysCount) exceed available $leaveType balance ($available).',
            'code': 'BALANCE_EXCEEDED',
          },
        );
      }

      // Server-side validation: Overlapping request check
      for (final existing in _leaveRequests) {
        final existingStatus = existing['status'] as String;
        if (existingStatus == 'pending' || existingStatus == 'approved') {
          final existingStart = DateTime.parse(existing['start_date'] as String);
          final existingEnd = DateTime.parse(existing['end_date'] as String);

          final overlaps = !(endDate.isBefore(existingStart) ||
              startDate.isAfter(existingEnd));
          if (overlaps) {
            return _jsonResponse(
              statusCode: 422,
              body: {
                'error': 'Requested dates overlap with an existing $existingStatus leave request.',
                'code': 'DATE_OVERLAP',
              },
            );
          }
        }
      }

      // Create new request
      final newRequest = {
        'id': 'leave-${DateTime.now().millisecondsSinceEpoch}',
        'client_request_id':
            payload['client_request_id'] ?? 'client-${DateTime.now().millisecondsSinceEpoch}',
        'employee_id': _employeeData['employee_id'],
        'leave_type': leaveType,
        'start_date': startDateStr,
        'end_date': endDateStr,
        'days_count': daysCount,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      _leaveRequests.insert(0, newRequest);

      // Deduct balance provisionally
      if (leaveType == 'sick') {
        _leaveBalance['sick_available'] = available - daysCount;
      } else {
        _leaveBalance['casual_available'] = available - daysCount;
      }

      return _jsonResponse(statusCode: 201, body: newRequest);
    }

    // Unknown endpoint
    return _jsonResponse(
      statusCode: 404,
      body: {'error': 'Endpoint not found', 'path': path},
    );
  }

  http.StreamedResponse _jsonResponse({
    required int statusCode,
    required dynamic body,
  }) {
    final bodyString = jsonEncode(body);
    final bodyBytes = utf8.encode(bodyString);
    return http.StreamedResponse(
      Stream.value(bodyBytes),
      statusCode,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'content-length': bodyBytes.length.toString(),
      },
    );
  }
}
