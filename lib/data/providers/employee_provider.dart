import 'package:flutter/foundation.dart';
import '../model/models.dart';
import '../repo/employee_repository.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeRepository repository;

  Employee? _employee;
  bool _isLoading = false;
  String? _errorMessage;

  EmployeeProvider({EmployeeRepository? repository})
      : repository = repository ?? EmployeeRepository();

  Employee? get employee => _employee ?? Employee.defaultEmployee;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEmployee({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _employee = await repository.getEmployee(forceRefresh: forceRefresh);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOfficeCoordinates({
    required double latitude,
    required double longitude,
    double radius = 200.0,
  }) async {
    await repository.updateOfficeCoordinates(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
    _employee = await repository.getEmployee(forceRefresh: false);
    notifyListeners();
  }
}
