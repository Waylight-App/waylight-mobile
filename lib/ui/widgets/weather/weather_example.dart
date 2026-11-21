import 'package:waylight_mobile/domain/models/weather.dart';

/// Example weather for the gallery preview (#251): a mild, partly cloudy
/// day and three more days from [today] on.
Weather exampleWeather(DateTime today) => Weather(
  temperature: 14,
  apparentTemperature: 12,
  condition: WeatherCondition.partlyCloudy,
  days: [
    for (final (i, condition, rain, min, max) in const [
      (0, WeatherCondition.partlyCloudy, 10, 8.0, 16.0),
      (1, WeatherCondition.rainShowers, 60, 7.0, 13.0),
      (2, WeatherCondition.clearSky, 0, 5.0, 15.0),
    ])
      ForecastDay(
        date: DateTime(today.year, today.month, today.day + i),
        min: min,
        max: max,
        condition: condition,
        precipitationProbability: rain,
      ),
  ],
);
