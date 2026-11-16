import 'package:flutter/foundation.dart';

/// Repeatable mock scenarios as mandated by the assignment specification.
enum MockApiScenario {
  /// Standard 200/201 responses with normal network latency.
  success,

  /// Simulates slow network latency / client-side timeout (~8-10 seconds).
  slowResponse,

  /// Returns HTTP 500 Internal Server Error.
  serverError,

  /// Returns HTTP 409 Conflict (e.g. attendance already exists for the day).
  duplicateAttendanceConflict,

  /// Returns HTTP 422 Unprocessable Entity (e.g. leave policy violation).
  leaveValidationRejection,

  /// Simulates zero network connectivity (throws SocketException / Timeout).
  networkOffline,
}

class MockScenarioManager extends ChangeNotifier {
  static final MockScenarioManager instance = MockScenarioManager._init();

  MockScenarioManager._init();

  MockApiScenario _currentScenario = MockApiScenario.success;
  bool _simulateOffline = false;

  MockApiScenario get currentScenario => _currentScenario;
  bool get isSimulateOffline => _simulateOffline;

  void setScenario(MockApiScenario scenario) {
    if (_currentScenario != scenario) {
      _currentScenario = scenario;
      notifyListeners();
    }
  }

  void setSimulateOffline(bool offline) {
    if (_simulateOffline != offline) {
      _simulateOffline = offline;
      notifyListeners();
    }
  }

  void resetToSuccess() {
    _currentScenario = MockApiScenario.success;
    _simulateOffline = false;
    notifyListeners();
  }
}
