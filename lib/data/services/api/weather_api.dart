import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The weather endpoint of the server (`api/modules/weather.yaml`).
class WeatherApi {
  /// Creates the service on top of an [ApiClient].
  const WeatherApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/weather` for a place.
  Future<Result<Weather>> weather(
    ServerAddress server, {
    required double lat,
    required double lon,
  }) async {
    final uri = server
        .resolve('/api/weather')
        .replace(queryParameters: {'lat': '$lat', 'lon': '$lon'});
    final result = await _client.getJson(uri);
    switch (result) {
      case Ok(:final value):
        final weather = parseWeather(value);
        return weather == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(weather);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Searches places by name (`GET /api/weather/places?q=`).
  Future<Result<List<Place>>> places(ServerAddress server, String query) async {
    final uri = server
        .resolve('/api/weather/places')
        .replace(queryParameters: {'q': query});
    return switch (await _client.getJson(uri)) {
      Ok(:final value) => switch (parsePlaces(value)) {
        final places? => Result.ok(places),
        null => const Result.error(ApiException(ApiFailure.server)),
      },
      Error(:final error) => Result.error(error),
    };
  }
}

/// Maps the JSON of `GET /api/weather/places`; `null` if it does not
/// match.
List<Place>? parsePlaces(Object? json) => switch (json) {
  final List<Object?> places => [
    for (final p in places)
      if (p
          case {
                'name': final String name,
                'lat': final num lat,
                'lon': final num lon,
              } &&
              final Map<String, Object?> o)
        Place(
          name: name,
          lat: lat.toDouble(),
          lon: lon.toDouble(),
          region: switch (o['region']) {
            final String r => r,
            _ => '',
          },
          country: switch (o['country']) {
            final String c => c,
            _ => '',
          },
        ),
  ],
  _ => null,
};

/// Maps the JSON of `GET /api/weather`; `null` if it does not match.
Weather? parseWeather(Object? json) {
  if (json case {
    'temperature': final num temperature,
    'apparentTemperature': final num apparent,
    'weatherCode': final int code,
    'days': final List<Object?> days,
  }) {
    final parsed = <ForecastDay>[];
    for (final day in days) {
      if (day case {
        'date': final String date,
        'temperatureMin': final num min,
        'temperatureMax': final num max,
        'weatherCode': final int dayCode,
      }) {
        final parsedDate = DateTime.tryParse(date);
        if (parsedDate == null) return null;
        parsed.add(
          ForecastDay(
            date: parsedDate,
            min: min.toDouble(),
            max: max.toDouble(),
            condition: WeatherCondition.fromCode(dayCode),
            precipitationProbability: switch (day['precipitationProbability']) {
              final int p => p,
              _ => 0,
            },
          ),
        );
      } else {
        return null;
      }
    }
    return Weather(
      temperature: temperature.toDouble(),
      apparentTemperature: apparent.toDouble(),
      condition: WeatherCondition.fromCode(code),
      days: parsed,
    );
  }
  return null;
}
