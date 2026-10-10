import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches real-time ambient outdoor temperature from the free Open-Meteo API
/// based on the phone's live GPS coordinates.
class WeatherService {
  static double? _cachedTemperature;
  static double? _cachedLatitude;
  static double? _cachedLongitude;
  static DateTime? _cachedTimestamp;

  /// Fetches ambient temperature in Celsius for given coordinates.
  /// Uses a 10-minute cache and proximity check to minimize network requests.
  static Future<double?> fetchAmbientTemperature({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    // Check cache validity (10 minutes and within ~1.5km)
    if (!forceRefresh &&
        _cachedTemperature != null &&
        _cachedTimestamp != null &&
        now.difference(_cachedTimestamp!) < const Duration(minutes: 10) &&
        _cachedLatitude != null &&
        _cachedLongitude != null) {
      final distKm = _approximateDistanceKm(
        latitude,
        longitude,
        _cachedLatitude!,
        _cachedLongitude!,
      );
      if (distKm < 1.5) {
        return _cachedTemperature;
      }
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${latitude.toStringAsFixed(4)}&longitude=${longitude.toStringAsFixed(4)}&current=temperature_2m',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = (data['current']?['temperature_2m'] as num?)?.toDouble();
        if (temp != null) {
          _cachedTemperature = temp;
          _cachedLatitude = latitude;
          _cachedLongitude = longitude;
          _cachedTimestamp = now;
          if (kDebugMode) {
            print('[WeatherService] Live GPS Ambient Temp updated: $temp°C at ($latitude, $longitude)');
          }
          return temp;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WeatherService] Could not fetch live weather, using fallback: $e');
      }
    }

    return _cachedTemperature;
  }

  static double _approximateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const d2r = math.pi / 180.0;
    final dLat = (lat2 - lat1) * d2r;
    final dLon = (lon2 - lon1) * d2r;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * d2r) * math.cos(lat2 * d2r) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return 6371.0 * c;
  }
}
