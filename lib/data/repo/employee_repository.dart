import '../../api/api.dart';
import '../local/database_helper.dart';
import '../model/models.dart';

class EmployeeRepository {
  final ApiService apiService;
  final DatabaseHelper dbHelper;

  EmployeeRepository({
    ApiService? apiService,
    DatabaseHelper? dbHelper,
  })  : apiService = apiService ?? ApiService(),
        dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Employee> getEmployee({bool forceRefresh = false}) async {
    // 1. Return cached employee if available and refresh not forced
    if (!forceRefresh) {
      final cached = await dbHelper.getEmployee();
      if (cached != null) {
        return cached;
      }
    }

    // 2. Fetch from API and cache locally
    try {
      final employee = await apiService.getEmployeeMe();
      await dbHelper.saveEmployee(employee);
      return employee;
    } catch (e) {
      // 3. Fallback to cached employee or default fallback
      final cached = await dbHelper.getEmployee();
      if (cached != null) {
        return cached;
      }
      return Employee.defaultEmployee;
    }
  }

  Future<void> updateOfficeCoordinates({
    required double latitude,
    required double longitude,
    double radius = 200.0,
  }) async {
    final current = await getEmployee();
    final updated = current.copyWith(
      officeLatitude: latitude,
      officeLongitude: longitude,
      geofenceRadiusMeters: radius,
    );
    await dbHelper.saveEmployee(updated);
  }
}
