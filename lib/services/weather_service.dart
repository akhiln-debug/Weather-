
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherService {
  static Future<WeatherData> getWeather(String city) async {
    final geoUrl = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': city,
        'count': '1',
        'language': 'en',
        'format': 'json',
      },
    );

    final geoResponse = await http.get(geoUrl);

    if (geoResponse.statusCode != 200) {
      throw Exception('Unable to search city');
    }

    final geoData = jsonDecode(geoResponse.body);
    final results = geoData['results'];

    if (results == null || results.isEmpty) {
      throw Exception('City not found');
    }

    final place = results[0];

    final latitude = place['latitude'];
    final longitude = place['longitude'];

    final forecastUrl = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'is_day,precipitation,weather_code,wind_speed_10m',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    final weatherResponse = await http.get(forecastUrl);

    if (weatherResponse.statusCode != 200) {
      throw Exception('Unable to load weather');
    }

    final data = jsonDecode(weatherResponse.body);

    return WeatherData.fromJson(
      place['name'],
      data,
    );
  }
}
