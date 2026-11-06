class WeatherData {
  final String city;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final List<DailyWeather> forecast;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.forecast,
  });

  factory WeatherData.fromJson(
    String city,
    Map<String, dynamic> json,
  ) {
    final current = json['current'];
    final daily = json['daily'];

    final forecast = <DailyWeather>[];

    for (int i = 0; i < daily['time'].length; i++) {
      forecast.add(
        DailyWeather(
          date: daily['time'][i],
          max: (daily['temperature_2m_max'][i] as num).toDouble(),
          min: (daily['temperature_2m_min'][i] as num).toDouble(),
          code: daily['weather_code'][i] as int,
        ),
      );
    }

    return WeatherData(
      city: city,
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: current['relative_humidity_2m'] as int,
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      forecast: forecast,
    );
  }
}

class DailyWeather {
  final String date;
  final double max;
  final double min;
  final int code;

  DailyWeather({
    required this.date,
    required this.max,
    required this.min,
    required this.code,
  });
}
