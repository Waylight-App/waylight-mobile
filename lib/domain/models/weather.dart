/// The weather at a place: now and the next days (`GET /api/weather`).
final class Weather {
  /// Creates the weather.
  const Weather({
    required this.temperature,
    required this.apparentTemperature,
    required this.condition,
    required this.days,
  });

  /// The temperature now, in °C.
  final double temperature;

  /// How warm it feels now, in °C.
  final double apparentTemperature;

  /// The weather now.
  final WeatherCondition condition;

  /// Today and the next days.
  final List<ForecastDay> days;
}

/// The forecast for one day.
final class ForecastDay {
  /// Creates the day.
  const ForecastDay({
    required this.date,
    required this.min,
    required this.max,
    required this.condition,
    required this.precipitationProbability,
  });

  /// The local date of the day.
  final DateTime date;

  /// The lowest temperature, in °C.
  final double min;

  /// The highest temperature, in °C.
  final double max;

  /// The weather of the day.
  final WeatherCondition condition;

  /// The chance of rain or snow, 0–100 %.
  final int precipitationProbability;
}

/// The kinds of weather the web interface tells apart.
enum WeatherCondition {
  /// Clear sky.
  clearSky,

  /// Mainly clear.
  mainlyClear,

  /// Partly cloudy.
  partlyCloudy,

  /// Overcast.
  overcast,

  /// Fog.
  fog,

  /// Rime fog.
  rimeFog,

  /// Light drizzle.
  lightDrizzle,

  /// Drizzle.
  drizzle,

  /// Dense drizzle.
  denseDrizzle,

  /// Freezing drizzle.
  freezingDrizzle,

  /// Light rain.
  lightRain,

  /// Rain.
  rain,

  /// Heavy rain.
  heavyRain,

  /// Freezing rain.
  freezingRain,

  /// Light snow.
  lightSnow,

  /// Snow.
  snow,

  /// Heavy snow.
  heavySnow,

  /// Snow grains.
  snowGrains,

  /// Rain showers.
  rainShowers,

  /// Violent showers.
  violentShowers,

  /// Snow showers.
  snowShowers,

  /// Thunderstorm.
  thunderstorm,

  /// Thunderstorm with hail.
  thunderstormWithHail,

  /// A code the app does not know.
  unknown;

  /// The condition of a WMO weather code, as the server sends it.
  static WeatherCondition fromCode(int code) => switch (code) {
    0 => clearSky,
    1 => mainlyClear,
    2 => partlyCloudy,
    3 => overcast,
    45 => fog,
    48 => rimeFog,
    51 => lightDrizzle,
    53 => drizzle,
    55 => denseDrizzle,
    56 || 57 => freezingDrizzle,
    61 => lightRain,
    63 => rain,
    65 => heavyRain,
    66 || 67 => freezingRain,
    71 => lightSnow,
    73 => snow,
    75 => heavySnow,
    77 => snowGrains,
    80 || 81 => rainShowers,
    82 => violentShowers,
    85 || 86 => snowShowers,
    95 => thunderstorm,
    96 || 99 => thunderstormWithHail,
    _ => unknown,
  };
}

/// An official weather warning (`GET /api/weather/warnings`, DWD).
final class WeatherWarning {
  /// Creates the warning.
  const WeatherWarning({
    required this.headline,
    required this.severity,
    this.description = '',
    this.expires,
  });

  /// The headline, such as "Amtliche WARNUNG vor STARKEN WINDBÖEN".
  final String headline;

  /// "minor", "moderate", "severe" or "extreme".
  final String severity;

  /// The full text.
  final String description;

  /// When it ends.
  final DateTime? expires;
}

/// Pollen and UV of the configured region and city
/// (`GET /api/weather/health`).
final class WeatherHealth {
  /// Creates the report.
  const WeatherHealth({
    this.pollen = const [],
    this.uvToday,
    this.uvLevel = '',
  });

  /// Each allergen with today's burden, such as ("Birke", "1-2").
  final List<(String, String)> pollen;

  /// Today's UV index, if known.
  final int? uvToday;

  /// Its level: low, moderate, high, very_high or extreme.
  final String uvLevel;
}
