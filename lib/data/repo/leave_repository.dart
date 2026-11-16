import '../../api/api.dart';
import '../local/database_helper.dart';
import '../model/models.dart';

class LeaveRepository {
  final ApiService apiService;
  final DatabaseHelper dbHelper;

  LeaveRepository({
    ApiService? apiService,
    DatabaseHelper? dbHelper,
  })  : apiService = apiService ?? ApiService(),
        dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<LeaveBalance> getLeaveBalance({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await dbHelper.getLeaveBalance();
      if (cached != null) {
        return cached;
      }
    }

    try {
      final balance = await apiService.getLeaveBalance();
      await dbHelper.saveLeaveBalance(balance);
      return balance;
    } catch (e) {
      final cached = await dbHelper.getLeaveBalance();
      if (cached != null) {
        return cached;
      }
      return LeaveBalance.defaultBalance;
    }
  }

  Future<List<LeaveRequest>> getLeaveRequests({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await dbHelper.getLeaveRequests();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final list = await apiService.getLeaveRequests();
      await dbHelper.saveLeaveRequests(list);
      return list;
    } catch (e) {
      return await dbHelper.getLeaveRequests();
    }
  }

  Future<LeaveRequest> submitLeaveRequest(
    LeaveRequest request, {
    required bool isOnline,
  }) async {
    if (!isOnline) {
      throw const NetworkException(
        'Leave submission requires an active internet connection.',
      );
    }

    // Submit to API (server-side validation will run)
    final created = await apiService.submitLeaveRequest(request);
    await dbHelper.upsertLeaveRequest(created);

    // Refresh balance after successful submission
    try {
      final updatedBalance = await apiService.getLeaveBalance();
      await dbHelper.saveLeaveBalance(updatedBalance);
    } catch (_) {}

    return created;
  }
}
