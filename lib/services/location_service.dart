import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static String? _cachedCityName;
  static bool _hasAttempted = false;

  static Future<String?> getCityName() async {
    if (_hasAttempted) {
      return _cachedCityName;
    }
    _hasAttempted = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        return null;
      }

      final apiKey = dotenv.env['WEATHER_CALENDAR'] ?? '';
      if (apiKey.isEmpty || apiKey == 'YOUR_KEY_HERE') {
        return null;
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&result_type=locality'
        '&key=$apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final firstResult = results[0] as Map<String, dynamic>;
      final addressComponents = firstResult['address_components'] as List<dynamic>?;
      if (addressComponents == null) return null;

      // Try to find "locality" first
      for (final component in addressComponents) {
        if (component is Map<String, dynamic>) {
          final types = component['types'] as List<dynamic>?;
          if (types != null && types.contains('locality')) {
            final longName = component['long_name'] as String?;
            if (longName != null && longName.isNotEmpty) {
              _cachedCityName = longName;
              return _cachedCityName;
            }
          }
        }
      }

      // If not found, try "administrative_area_level_2"
      for (final component in addressComponents) {
        if (component is Map<String, dynamic>) {
          final types = component['types'] as List<dynamic>?;
          if (types != null && types.contains('administrative_area_level_2')) {
            final longName = component['long_name'] as String?;
            if (longName != null && longName.isNotEmpty) {
              _cachedCityName = longName;
              return _cachedCityName;
            }
          }
        }
      }
    } catch (_) {
      // Catch any unexpected exceptions
    }

    return null;
  }
}
