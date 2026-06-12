import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  // ── Permission & Position ──────────────────────────────────────────────────

  /// Request permission and return current position.
  /// Returns null if permission denied.
  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await _ensurePermission();
      if (!permission) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastPosition = pos;
      return pos;
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e');
      return null;
    }
  }

  /// Stream of position updates (for live tracking).
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // metres
        ),
      );

  /// Check and request permission. Returns true if granted.
  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── Distance Calculation ───────────────────────────────────────────────────

  /// Haversine distance in kilometres between two lat/lng points.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth radius km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

  /// Human-readable distance string: "0.3 km" or "1.2 km".
  static String distanceLabel(double lat1, double lon1, double lat2, double lon2) {
    final km = distanceKm(lat1, lon1, lat2, lon2);
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  /// Open device navigation to a location (Google Maps deep link).
  static String googleMapsUrl(double lat, double lng, String label) =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label';
}
