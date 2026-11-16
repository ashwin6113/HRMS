import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../api/mock_api_scenario.dart';
import '../repo/attendance_repository.dart';
import 'attendance_provider.dart';

class SyncProvider extends ChangeNotifier {
  final Connectivity _connectivity;
  final MockScenarioManager _scenarioManager;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hasRealConnectivity = true;
  bool _isSyncing = false;
  String? _lastSyncMessage;
  DateTime? _lastSyncTime;

  SyncProvider({
    Connectivity? connectivity,
    MockScenarioManager? scenarioManager,
  })  : _connectivity = connectivity ?? Connectivity(),
        _scenarioManager = scenarioManager ?? MockScenarioManager.instance {
    _initConnectivity();
    _scenarioManager.addListener(_onScenarioChanged);
  }

  bool get isSyncing => _isSyncing;
  String? get lastSyncMessage => _lastSyncMessage;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Effective online state considering real connectivity and simulated offline mode
  bool get isOnline =>
      _hasRealConnectivity && !_scenarioManager.isSimulateOffline;

  bool get isOffline => !isOnline;

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
    } on MissingPluginException {
      // Platform channels not linked yet (e.g. during hot-reload after adding plugin)
      _hasRealConnectivity = true;
    } catch (_) {
      _hasRealConnectivity = true;
    }

    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivity,
        onError: (dynamic error) {
          // Gracefully handle channel errors without crashing
          _hasRealConnectivity = true;
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Platform stream not implemented on current platform or requires full rebuild
      _hasRealConnectivity = true;
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final hasNet = results.any((r) => r != ConnectivityResult.none);
    if (_hasRealConnectivity != hasNet) {
      _hasRealConnectivity = hasNet;
      notifyListeners();
    }
  }

  void _onScenarioChanged() {
    notifyListeners();
  }

  Future<SyncResult?> syncNow(AttendanceProvider attendanceProvider) async {
    if (!isOnline) {
      _lastSyncMessage = 'Cannot synchronize: Currently offline';
      notifyListeners();
      return null;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final result = await attendanceProvider.syncPending();
      _lastSyncTime = DateTime.now();

      if (result.total == 0) {
        _lastSyncMessage = 'Everything is up to date.';
      } else if (result.hasErrors) {
        _lastSyncMessage =
            'Synced ${result.synced} of ${result.total} events. (${result.rejected} rejected, ${result.failed} failed)';
      } else {
        _lastSyncMessage = 'Successfully synced ${result.synced} events.';
      }

      return result;
    } catch (e) {
      _lastSyncMessage = 'Sync failed: $e';
      return null;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _scenarioManager.removeListener(_onScenarioChanged);
    super.dispose();
  }
}
