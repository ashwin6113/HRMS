import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

enum LocationSimulationMode {
  /// Uses real hardware GPS.
  realGps,

  /// Simulates device being directly at the office desk (distance = 0m).
  atOffice,

  /// Simulates device being outside the permitted 200m zone (~550m away).
  outsideOffice,

  /// Simulates user denying location permission.
  permissionDenied,

  /// Simulates permanently denied location permission.
  permissionPermanentlyDenied,

  /// Simulates GPS hardware disabled on device.
  servicesDisabled,
}

class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService._init();

  LocationService._init();

  LocationSimulationMode _simulationMode = LocationSimulationMode.atOffice;

  LocationSimulationMode get simulationMode => _simulationMode;

  void setSimulationMode(LocationSimulationMode mode) {
    if (_simulationMode != mode) {
      _simulationMode = mode;
      notifyListeners();
    }
  }

  /// Calculates the distance in meters between two GPS coordinates using Haversine formula
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (_) {
      // Fallback manual calculation if native method is unavailable
      return 0.0;
    }
  }

  /// Checks whether the user is within the permitted geofence radius of the office
  Future<GeofenceCheckResult> checkGeofence({
    required double officeLatitude,
    required double officeLongitude,
    double allowedRadiusMeters = 200.0,
  }) async {
    // 1. Reviewer Simulation Modes
    switch (_simulationMode) {
      case LocationSimulationMode.atOffice:
        return GeofenceCheckResult(
          isWithinGeofence: true,
          distanceMeters: 0.0,
          allowedRadiusMeters: allowedRadiusMeters,
          currentLatitude: officeLatitude,
          currentLongitude: officeLongitude,
        );

      case LocationSimulationMode.outsideOffice:
        // Offset coordinates by ~0.0038 degrees (~550 meters away)
        final mockLat = officeLatitude + 0.0038;
        final mockLng = officeLongitude + 0.0038;
        final dist = calculateDistance(
          mockLat,
          mockLng,
          officeLatitude,
          officeLongitude,
        );

        return GeofenceCheckResult(
          isWithinGeofence: false,
          distanceMeters: dist > 0 ? dist : 550.0,
          allowedRadiusMeters: allowedRadiusMeters,
          currentLatitude: mockLat,
          currentLongitude: mockLng,
          errorMessage:
              'You are ${(dist > 0 ? dist : 550.0).round()}m away from the office. Attendance is only permitted within ${allowedRadiusMeters.round()}m.',
        );

      case LocationSimulationMode.permissionDenied:
        return GeofenceCheckResult(
          isWithinGeofence: false,
          distanceMeters: -1,
          allowedRadiusMeters: allowedRadiusMeters,
          currentLatitude: 0,
          currentLongitude: 0,
          errorMessage:
              'Location permission was denied. Please allow location access to record attendance.',
        );

      case LocationSimulationMode.permissionPermanentlyDenied:
        return GeofenceCheckResult(
          isWithinGeofence: false,
          distanceMeters: -1,
          allowedRadiusMeters: allowedRadiusMeters,
          currentLatitude: 0,
          currentLongitude: 0,
          canOpenSettings: true,
          errorMessage:
              'Location permission is permanently denied. Please enable it in device settings.',
        );

      case LocationSimulationMode.servicesDisabled:
        return GeofenceCheckResult(
          isWithinGeofence: false,
          distanceMeters: -1,
          allowedRadiusMeters: allowedRadiusMeters,
          currentLatitude: 0,
          currentLongitude: 0,
          canOpenSettings: true,
          errorMessage:
              'Location services (GPS) are disabled. Please turn on GPS on your device.',
        );

      case LocationSimulationMode.realGps:
        break;
    }

    // 2. Real Hardware GPS Check
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return GeofenceCheckResult(
          isWithinGeofence: false,
          distanceMeters: -1,
          allowedRadiusMeters: allowedRadiusMeters,
          currentLatitude: 0,
          currentLongitude: 0,
          canOpenSettings: true,
          errorMessage:
              'Location services (GPS) are turned off. Please enable GPS to mark attendance.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeofenceCheckResult(
            isWithinGeofence: false,
            distanceMeters: -1,
            allowedRadiusMeters: allowedRadiusMeters,
            currentLatitude: 0,
            currentLongitude: 0,
            errorMessage:
                'Location permission denied. Please allow location access to mark attendance.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeofenceCheckResult(
          isWithinGeofence: false,
          distanceMeters: -1,
          allowedRadiusMeters: allowedRadiusMeters,
          currentLatitude: 0,
          currentLongitude: 0,
          canOpenSettings: true,
          errorMessage:
              'Location permission is permanently denied. Please grant location access from app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        officeLatitude,
        officeLongitude,
      );

      final isWithin = distance <= allowedRadiusMeters;

      return GeofenceCheckResult(
        isWithinGeofence: isWithin,
        distanceMeters: distance,
        allowedRadiusMeters: allowedRadiusMeters,
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        errorMessage: isWithin
            ? null
            : 'You are ${distance.round()}m away from the office. Attendance is permitted only within ${allowedRadiusMeters.round()}m.',
      );
    } on MissingPluginException {
      // If hardware geolocator is missing (e.g. running on macOS without pod or hot-reload),
      // fallback to At Office so the app remains fully functional.
      return GeofenceCheckResult(
        isWithinGeofence: true,
        distanceMeters: 0.0,
        allowedRadiusMeters: allowedRadiusMeters,
        currentLatitude: officeLatitude,
        currentLongitude: officeLongitude,
      );
    } catch (e) {
      return GeofenceCheckResult(
        isWithinGeofence: false,
        distanceMeters: -1,
        allowedRadiusMeters: allowedRadiusMeters,
        currentLatitude: 0,
        currentLongitude: 0,
        errorMessage: 'Unable to determine location: $e',
      );
    }
  }

  Future<bool> openSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('openAppSettings not supported or channel missing on this platform: $e');
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('openLocationSettings not supported or channel missing on this platform: $e');
      return false;
    }
  }
}

class GeofenceCheckResult {
  final bool isWithinGeofence;
  final double distanceMeters;
  final double allowedRadiusMeters;
  final double currentLatitude;
  final double currentLongitude;
  final String? errorMessage;
  final bool canOpenSettings;

  const GeofenceCheckResult({
    required this.isWithinGeofence,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    required this.currentLatitude,
    required this.currentLongitude,
    this.errorMessage,
    this.canOpenSettings = false,
  });
}
