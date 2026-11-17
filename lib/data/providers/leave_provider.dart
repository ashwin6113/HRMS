import 'package:flutter/foundation.dart';
import '../model/models.dart';
import '../repo/leave_repository.dart';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../api/core/api_exceptions.dart';
import '../model/models.dart';
import '../repo/leave_repository.dart';

class LeaveValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int daysCount;

  const LeaveValidationResult({
    required this.isValid,
    this.errorMessage,
    this.daysCount = 0,
  });
}

class LeaveProvider extends ChangeNotifier {
  final LeaveRepository repository;
  final Uuid _uuid = const Uuid();

  LeaveBalance? _balance;
  List<LeaveRequest> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  LeaveProvider({LeaveRepository? repository})
      : repository = repository ?? LeaveRepository();

  LeaveBalance get balance => _balance ?? LeaveBalance.defaultBalance;
  List<LeaveRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<LeaveRequest> get pendingRequests =>
      _requests.where((r) => r.status.toLowerCase() == 'pending').toList();

  List<LeaveRequest> get approvedRequests =>
      _requests.where((r) => r.status.toLowerCase() == 'approved').toList();

  List<LeaveRequest> get rejectedRequests =>
      _requests.where((r) => r.status.toLowerCase() == 'rejected').toList();

  Future<void> loadLeaveData({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _balance = await repository.getLeaveBalance(forceRefresh: forceRefresh);
      _requests = await repository.getLeaveRequests(forceRefresh: forceRefresh);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Device-side validation engine for leave requests
  LeaveValidationResult validateLeaveRequest({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) {
    // 1. Normalize dates to eliminate time of day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    // Rule 1: startDate cannot be before current date
    if (normalizedStart.isBefore(today)) {
      return const LeaveValidationResult(
        isValid: false,
        errorMessage: 'Leave start date cannot be in the past.',
      );
    }

    // Rule 2: endDate cannot be before startDate
    if (normalizedEnd.isBefore(normalizedStart)) {
      return const LeaveValidationResult(
        isValid: false,
        errorMessage: 'End date cannot be earlier than start date.',
      );
    }

    // Rule 3: Calendar days count
    final daysCount = normalizedEnd.difference(normalizedStart).inDays + 1;

    // Rule 4: Leave balance check
    final available = (leaveType.toLowerCase() == 'sick')
        ? balance.sickLeaveAvailable
        : balance.casualLeaveAvailable;

    if (daysCount > available) {
      return LeaveValidationResult(
        isValid: false,
        daysCount: daysCount,
        errorMessage:
            'Requested $daysCount day(s) exceeds your available $leaveType balance ($available day(s)).',
      );
    }

    // Rule 5: Overlapping requests check (pending or approved)
    for (final existing in _requests) {
      final status = existing.status.toLowerCase();
      if (status == 'pending' || status == 'approved') {
        final exStart = DateTime(
          existing.startDate.year,
          existing.startDate.month,
          existing.startDate.day,
        );
        final exEnd = DateTime(
          existing.endDate.year,
          existing.endDate.month,
          existing.endDate.day,
        );

        final overlaps = !(normalizedEnd.isBefore(exStart) ||
            normalizedStart.isAfter(exEnd));

        if (overlaps) {
          final rangeStr =
              '${existing.startDate.toIso8601String().substring(0, 10)} to ${existing.endDate.toIso8601String().substring(0, 10)}';
          return LeaveValidationResult(
            isValid: false,
            daysCount: daysCount,
            errorMessage:
                'Selected dates overlap with an existing ${existing.status} leave ($rangeStr).',
          );
        }
      }
    }

    // Rule 6: Reason minimum 10 non-whitespace characters
    final nonWhitespaceReason = reason.replaceAll(RegExp(r'\s+'), '');
    if (nonWhitespaceReason.length < 10) {
      return LeaveValidationResult(
        isValid: false,
        daysCount: daysCount,
        errorMessage:
            'Reason must contain at least 10 non-whitespace characters (${nonWhitespaceReason.length}/10 entered).',
      );
    }

    return LeaveValidationResult(
      isValid: true,
      daysCount: daysCount,
    );
  }

  Future<LeaveRequest> submitLeaveRequest({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required bool isOnline,
  }) async {
    // 1. Device-side validation
    final validation = validateLeaveRequest(
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    if (!validation.isValid) {
      throw ValidationException(validation.errorMessage ?? 'Invalid leave application.');
    }

    // 2. Connectivity check
    if (!isOnline) {
      throw const NetworkException(
        'Leave submission requires an active internet connection. Please connect to the internet to submit.',
      );
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LeaveRequest(
        id: 'leave-${DateTime.now().millisecondsSinceEpoch}',
        clientRequestId: _uuid.v4(),
        employeeId: employeeId,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        daysCount: validation.daysCount,
        reason: reason.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final created = await repository.submitLeaveRequest(
        request,
        isOnline: isOnline,
      );

      _requests = await repository.getLeaveRequests(forceRefresh: false);
      _balance = await repository.getLeaveBalance(forceRefresh: false);
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
