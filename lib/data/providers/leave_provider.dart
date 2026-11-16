import 'package:flutter/foundation.dart';
import '../model/models.dart';
import '../repo/leave_repository.dart';

class LeaveProvider extends ChangeNotifier {
  final LeaveRepository repository;

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

  Future<LeaveRequest> submitLeaveRequest(
    LeaveRequest request, {
    required bool isOnline,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
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
