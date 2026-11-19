import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/weather_api.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  // Recorded from https://demo.getwaylight.app (GET /api/weather).
  final demo = File('test/fixtures/weather_demo.json').readAsStringSync();

  test('reads the weather of the demo', () {
    final weather = parseWeather(jsonDecode(demo))!;

    expect(weather.temperature, 14.2);
    expect(weather.condition, WeatherCondition.partlyCloudy);
    expect(weather.days, isNotEmpty);
    expect(weather.days.first.date, DateTime(2026, 11, 19));
    expect(weather.days.first.max, 16);
  });

  test('rejects other JSON', () {
    expect(parseWeather(null), isNull);
    expect(parseWeather({'temperature': 'warm'}), isNull);
  });

  test('asks the server for the place', () async {
    late Uri asked;
    final api = WeatherApi(
      ApiClient(
        client: MockClient((request) async {
          asked = request.url;
          return http.Response(demo, 200);
        }),
      ),
    );

    final result = await api.weather(testServer(), lat: 52.52, lon: 13.41);

    expect(result, isA<Ok<Weather>>());
    expect(asked.path, '/api/weather');
    expect(asked.queryParameters, {'lat': '52.52', 'lon': '13.41'});
  });

  test('maps WMO codes like the web interface', () {
    expect(WeatherCondition.fromCode(0), WeatherCondition.clearSky);
    expect(WeatherCondition.fromCode(57), WeatherCondition.freezingDrizzle);
    expect(
      WeatherCondition.fromCode(99),
      WeatherCondition.thunderstormWithHail,
    );
    expect(WeatherCondition.fromCode(42), WeatherCondition.unknown);
  });
}
