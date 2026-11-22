import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/places/places_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/location/device_location.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

class _Location implements DeviceLocation {
  _Location(this.result);

  final Result<Coordinates> result;

  @override
  bool get available => true;

  @override
  Future<Result<Coordinates>> coarse() async => result;
}

void main() {
  final requests = <http.Request>[];
  var saved = '[]';

  PlacesRepositoryRemote repository(Result<Coordinates> position) =>
      PlacesRepositoryRemote(
        api: ModuleApi(
          ApiClient(
            client: MockClient((request) async {
              requests.add(request);
              return request.method == 'POST'
                  ? http.Response(
                      '{"id":"new","name":"My location","lat":52.372,'
                      '"lon":9.736,"label":"","usedBy":[]}',
                      201,
                    )
                  : http.Response(saved, 200);
            }),
          ),
        ),
        location: _Location(position),
      );

  setUp(() {
    requests.clear();
    saved = '[]';
  });

  test('saves the position rounded to three decimals as a place', () async {
    final result = await repository(
      const Result.ok((lat: 52.37249, lon: 9.73561)),
    ).useMyLocation(testServer(), 'My location');

    expect((result as Ok<Place>).value.id, 'new');
    final body = jsonDecode(requests.last.body) as Map<String, Object?>;
    expect(body, {'name': 'My location', 'lat': 52.372, 'lon': 9.736});
  });

  test('reuses a place saved at the same spot', () async {
    saved =
        '[{"id":"home","name":"Home","label":"","lat":52.372,"lon":9.736,'
        '"usedBy":[]}]';
    final result = await repository(
      const Result.ok((lat: 52.37249, lon: 9.73561)),
    ).useMyLocation(testServer(), 'My location');

    expect((result as Ok<Place>).value.id, 'home');
    expect(requests.every((r) => r.method == 'GET'), isTrue);
  });

  test('passes on a refused permission and saves nothing', () async {
    final result = await repository(const Result.error(LocationDenied()))
        .useMyLocation(testServer(), 'My location');

    expect((result as Error<Place>).error, isA<LocationDenied>());
    expect(requests, isEmpty);
  });
}
