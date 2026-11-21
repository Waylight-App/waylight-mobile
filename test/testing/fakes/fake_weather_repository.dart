import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [WeatherRepository] without network for tests.
class FakeWeatherRepository implements WeatherRepository {
  /// Creates the fake answering with [result], or [sampleWeather].
  FakeWeatherRepository([Result<Weather>? result])
    : result = result ?? Result.ok(sampleWeather());

  /// What [weather] returns.
  Result<Weather> result;

  /// The places [weather] was asked for.
  final List<(double, double)> calls = [];

  @override
  Future<Result<Weather>> weather(
    ServerAddress server, {
    required double lat,
    required double lon,
  }) async {
    calls.add((lat, lon));
    return result;
  }

  /// What [places] returns.
  Result<List<Place>> placesResult = const Result.ok([]);

  @override
  Future<Result<List<Place>>> places(
    ServerAddress server,
    String query,
  ) async => placesResult;
}

/// Weather with four forecast days from 19 November 2026, for tests.
Weather sampleWeather() => Weather(
  temperature: 14.2,
  apparentTemperature: 12.8,
  condition: WeatherCondition.partlyCloudy,
  days: [
    for (final (i, condition, rain) in [
      (0, WeatherCondition.partlyCloudy, 10),
      (1, WeatherCondition.overcast, 40),
      (2, WeatherCondition.rain, 80),
      (3, WeatherCondition.clearSky, 0),
    ])
      ForecastDay(
        date: DateTime(2026, 11, 19 + i),
        min: 8.0 - i,
        max: 16.0 - i,
        condition: condition,
        precipitationProbability: rain,
      ),
  ],
);
