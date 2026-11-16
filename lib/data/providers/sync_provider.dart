import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
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
    bool isNativePluginAvailable = false;

    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
      isNativePluginAvailable = true;
    } catch (e) {
      // Platform channels not linked (e.g. desktop/simulator without full re-run/pod install)
      debugPrint('Connectivity check unavailable or missing plugin: $e');
      _hasRealConnectivity = true;
      isNativePluginAvailable = false;
    }

    // Only subscribe to the platform stream if the native plugin check succeeded
    if (isNativePluginAvailable) {
      try {
        _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
          _updateConnectivity,
          onError: (dynamic error) {
            debugPrint('Connectivity stream error: $error');
            _hasRealConnectivity = true;
          },
          cancelOnError: false,
        );
      } catch (e) {
        debugPrint('Failed to subscribe to connectivity changes: $e');
        _hasRealConnectivity = true;
      }
    }
  }

  Future<void> Function()? _autoSyncCallback;

  void registerAutoSyncCallback(Future<void> Function() callback) {
    _autoSyncCallback = callback;
  }

  void unregisterAutoSyncCallback() {
    _autoSyncCallback = null;
  }

  void _triggerAutoSync() {
    if (_autoSyncCallback != null && !_isSyncing) {
      _isSyncing = true;
      notifyListeners();
      _autoSyncCallback!().then((_) {
        _lastSyncTime = DateTime.now();
        _lastSyncMessage = 'Auto-sync completed.';
      }).catchError((e) {
        _lastSyncMessage = 'Auto-sync failed: $e';
      }).whenComplete(() {
        _isSyncing = false;
        notifyListeners();
      });
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final hasNet = results.any((r) => r != ConnectivityResult.none);
    final wasOffline = isOffline;
    if (_hasRealConnectivity != hasNet) {
      _hasRealConnectivity = hasNet;
      notifyListeners();
      if (wasOffline && isOnline) {
        _triggerAutoSync();
      }
    }
  }

  void _onScenarioChanged() {
    final wasOffline = isOffline;
    notifyListeners();
    if (wasOffline && isOnline) {
      _triggerAutoSync();
    }
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
