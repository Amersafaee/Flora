import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double temperatureCelsius;
  final double humidity;
  final String description;
  final String cityName;
  final DateTime fetchedAt;

  WeatherData({
    required this.temperatureCelsius,
    required this.humidity,
    required this.description,
    required this.cityName,
    required this.fetchedAt,
  });

  double get temperatureFahrenheit => (temperatureCelsius * 9 / 5) + 32;

  Map<String, dynamic> toMap() => {
    'temperatureCelsius': temperatureCelsius,
    'humidity': humidity,
    'description': description,
    'cityName': cityName,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory WeatherData.fromMap(Map<String, dynamic> map) => WeatherData(
    temperatureCelsius: (map['temperatureCelsius'] as num).toDouble(),
    humidity: (map['humidity'] as num).toDouble(),
    description: map['description'] as String? ?? '',
    cityName: map['cityName'] as String? ?? '',
    fetchedAt: DateTime.parse(map['fetchedAt'] as String),
  );
}

class WeatherService {
  static const String _cacheKey = 'cached_weather';
  static const String _cityKey = 'user_city';
  static const Duration _cacheExpiry = Duration(hours: 3);

  String get _apiKey => dotenv.env['WEATHER_CALENDAR'] ?? '';

  Future<String?> getSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey);
  }

  Future<void> saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, city);
    await clearCache();
  }

  Future<WeatherData?> getCurrentWeather() async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_KEY_HERE') return null;

    final cached = await _getCachedWeather();
    if (cached != null) return cached;

    final city = await getSavedCity();
    if (city == null || city.isEmpty) return null;

    return await fetchWeatherForCity(city);
  }

  Future<WeatherData?> fetchWeatherForCity(String city) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_KEY_HERE') return null;
    try {
      // Step 1: Geocode city name to coordinates using Google Geocoding API
      final geocodeUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(city)}&key=$_apiKey',
      );
      final geocodeResponse = await http.get(geocodeUrl).timeout(const Duration(seconds: 10));
      if (geocodeResponse.statusCode != 200) return null;

      final geocodeJson = jsonDecode(geocodeResponse.body) as Map<String, dynamic>;
      final results = geocodeJson['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final location = results[0]['geometry']['location'] as Map<String, dynamic>;
      final lat = (location['lat'] as num).toDouble();
      final lon = (location['lng'] as num).toDouble();

      // Step 2: Get weather from Google Weather API
      final weatherUrl = Uri.parse(
        'https://weather.googleapis.com/v1/currentConditions:lookup?key=$_apiKey',
      );

      final weatherResponse = await http.post(
        weatherUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'location': {'latitude': lat, 'longitude': lon}}),
      ).timeout(const Duration(seconds: 10));

      if (weatherResponse.statusCode != 200) return null;

      final weatherJson = jsonDecode(weatherResponse.body) as Map<String, dynamic>;

      final tempC = (weatherJson['temperature']?['degrees'] as num?)?.toDouble() ?? 20.0;
      final humidity = (weatherJson['relativeHumidity'] as num?)?.toDouble() ?? 50.0;
      final description = weatherJson['weatherCondition']?['description']?['text'] as String? ?? 'Clear';

      final weather = WeatherData(
        temperatureCelsius: tempC,
        humidity: humidity,
        description: description,
        cityName: city,
        fetchedAt: DateTime.now(),
      );

      await _cacheWeather(weather);
      return weather;
    } catch (e) {
      return null;
    }
  }

  Future<WeatherData?> _getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null) return null;
      final data = WeatherData.fromMap(jsonDecode(cached) as Map<String, dynamic>);
      if (DateTime.now().difference(data.fetchedAt) > _cacheExpiry) return null;
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheWeather(WeatherData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data.toMap()));
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
