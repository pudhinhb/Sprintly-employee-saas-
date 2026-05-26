import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/office_location_model.dart';

class LocationService {
  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current user location with retry logic and fallback
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        print('❌ LocationService: Permission denied');
        return null;
      }

      print('📍 LocationService: Attempting to get location...');

      // Fallback 1: Try get last known position first (very fast) - Skip on Web
      if (!kIsWeb) {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && lastKnown.accuracy <= 500) {
          print(
              '✅ LocationService: Using last known position - Accuracy: ${lastKnown.accuracy.toInt()}m');
          return lastKnown;
        }
      }

      print('📍 LocationService: Getting fresh location with best accuracy...');

      // Try up to 3 times to get good accuracy
      for (int attempt = 1; attempt <= 3; attempt++) {
        print('📍 LocationService: Attempt $attempt/3');

        try {
          // Request HIGH accuracy (uses fused location: GPS + WiFi + Cell towers)
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: attempt == 1 ? 10 : 20),
          );

          print(
              '✅ LocationService: Got location - Lat: ${position.latitude}, Lng: ${position.longitude}, Accuracy: ${position.accuracy.toInt()}m');

          // Accept if accuracy is good enough (< 3000 meters for testing)
          if (position.accuracy <= 3000) {
            return position;
          }
        } catch (e) {
          print('⚠️ LocationService: Attempt $attempt failed: $e');
        }

        // If not the last attempt, wait a bit
        if (attempt < 3) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Final fallback: Use last known position regardless of accuracy if all fresh attempts failed
      if (!kIsWeb) {
        print(
            '⚠️ LocationService: Fresh GPS failed, using last known as final resort');
        return await Geolocator.getLastKnownPosition();
      }
      return null;
    } catch (e) {
      print('❌ LocationService: Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if user is within range of any office location
  Future<OfficeLocation?> isWithinOfficeRange(
    Position userPosition,
    List<OfficeLocation> officeLocations,
  ) async {
    print('📍 LocationService: Checking if within office range...');
    print(
        '📍 LocationService: User position - Lat: ${userPosition.latitude}, Lng: ${userPosition.longitude}');
    print(
        '📍 LocationService: Checking against ${officeLocations.length} office locations');

    for (var office in officeLocations) {
      double distance = calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        office.latitude,
        office.longitude,
      );

      print(
          '📍 LocationService: Distance to ${office.locationName}: ${distance.toStringAsFixed(2)}m (radius: ${office.radiusMeters}m)');

      if (distance <= office.radiusMeters) {
        print('✅ LocationService: Within range of ${office.locationName}');
        return office;
      }
    }

    print('❌ LocationService: Not within range of any office location');
    return null;
  }

  /// Get location permission status message
  String getPermissionStatusMessage(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission denied. Please enable it in settings.';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied. Please enable it in app settings.';
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return 'Location permission granted.';
      default:
        return 'Unknown permission status.';
    }
  }

  /// Get user-friendly error message for location issues
  String getLocationErrorMessage(Position? position) {
    if (position == null) {
      return 'Unable to get your location. Please enable GPS and location permissions.';
    }

    if (position.accuracy > 100) {
      return 'GPS accuracy too low (${position.accuracy.toInt()}m). Please move to an area with clear sky view or wait for better GPS signal.';
    }

    return 'Location error occurred.';
  }

  /// Get device's public IP address
  Future<String?> getPublicIP() async {
    try {
      print('🌐 LocationService: Getting public IP...');

      final response = await http
          .get(
            Uri.parse('https://api.ipify.org?format=json'),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ip = data['ip'] as String?;
        print('✅ LocationService: Public IP: $ip');
        return ip;
      }
    } catch (e) {
      print('❌ LocationService: Error getting public IP: $e');
    }
    return null;
  }

  /// Check if device is on office network by comparing public IP
  Future<bool> isOnOfficeNetwork(List<OfficeLocation> officeLocations) async {
    try {
      final myPublicIP = await getPublicIP();
      if (myPublicIP == null) {
        print('❌ LocationService: Could not get public IP');
        return false;
      }

      print('📍 LocationService: Checking if IP matches office...');
      final officeIps = officeLocations
          .where((o) => o.publicIp != null)
          .map((o) => '${o.locationName}: ${o.publicIp}')
          .toList();

      print('📍 LocationService: Authorized Office IPs: $officeIps');

      for (var office in officeLocations) {
        if (office.publicIp != null && office.publicIp == myPublicIP) {
          print('✅ LocationService: Public IP matches ${office.locationName}!');
          return true;
        }
      }

      print(
          '❌ LocationService: Public IP ($myPublicIP) does not match any authorized office IPs');
      return false;
    } catch (e) {
      print('❌ LocationService: Error checking office network: $e');
      return false;
    }
  }
}
