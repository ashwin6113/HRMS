import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../data/model/models.dart';
import 'core/api_exceptions.dart';
import 'mock_http_client.dart';

class ApiService {
  final http.Client client;
  final String baseUrl;

  ApiService({
    http.Client? client,
    this.baseUrl = MockHttpClient.baseUrl,
  }) : client = client ?? MockHttpClient();

  Future<Employee> getEmployeeMe() async {
    final response = await _get('/employee/me');
    final data = _handleResponse(response);
    return Employee.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AttendanceRecord>> getAttendanceHistory({String? month}) async {
    final uri = month != null && month.isNotEmpty
        ? '/attendance?month=$month'
        : '/attendance';
    final response = await _get(uri);
    final data = _handleResponse(response);
    final list = data as List<dynamic>;
    return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AttendanceRecord> submitAttendanceEvent(AttendanceEvent event) async {
    final response = await _post(
      '/attendance/events',
      body: event.toJson(),
    );
    final data = _handleResponse(response);
    return AttendanceRecord.fromJson(data as Map<String, dynamic>);
  }

  Future<LeaveBalance> getLeaveBalance() async {
    final response = await _get('/leave/balance');
    final data = _handleResponse(response);
    return LeaveBalance.fromJson(data as Map<String, dynamic>);
  }

  Future<List<LeaveRequest>> getLeaveRequests() async {
    final response = await _get('/leave/requests');
    final data = _handleResponse(response);
    final list = data as List<dynamic>;
    return list.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request) async {
    final response = await _post(
      '/leave/requests',
      body: request.toJson(),
    );
    final data = _handleResponse(response);
    return LeaveRequest.fromJson(data as Map<String, dynamic>);
  }

  // ================= Private HTTP Helpers =================

  Future<http.Response> _get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      return await client.get(
        url,
        headers: {'Accept': 'application/json'},
      );
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<http.Response> _post(String endpoint, {required Map<String, dynamic> body}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      return await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;
    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      body = {'error': response.body};
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    final errorMessage = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'HTTP Error $statusCode';

    switch (statusCode) {
      case 400:
        throw ApiException(errorMessage, statusCode: 400);
      case 401:
        throw UnauthorizedException(errorMessage);
      case 408:
        throw const TimeoutException();
      case 409:
        throw ConflictException(errorMessage, details: body);
      case 422:
        throw ValidationException(errorMessage, details: body);
      case 500:
      case 502:
      case 503:
        throw ServerException(errorMessage);
      default:
        throw ApiException(errorMessage, statusCode: statusCode);
    }
  }
}
