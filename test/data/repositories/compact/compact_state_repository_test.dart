import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_transit_repository.dart';
import '../../../testing/fakes/fake_waste_repository.dart';
import '../../../testing/fakes/fake_weather_repository.dart';
import '../../../testing/fakes/in_memory_response_cache.dart';

/// The compact state of a widget (#228), in the server's shape.
void main() {
  final todos = File('test/fixtures/todos_compact_demo.json')
      .readAsStringSync();
  final presence = File('test/fixtures/presence_compact_example.json')
      .readAsStringSync();

  test('parses title, detail, level, count and time', () {
    final state = parseCompactState(jsonDecode(todos))!;
    expect(state.title.text, '3 open · 1 overdue');
    expect(state.title.key, 'srv_1a2b3c4d5e6f7081');
    expect(state.title.params, {'open': '3', 'overdue': '1'});
    expect(state.detail?.text, 'Next: Tax return');
    expect(state.level, CompactLevel.attention);
    expect(state.count, 3);
    expect(state.updatedAt, DateTime.utc(2026, 11, 21, 10, 15));
    expect(state.action, isNull);
  });

  test('parses an action with choices', () {
    final state = parseCompactState(jsonDecode(presence))!;
    final action = state.action!;
    expect(state.detail, isNull);
    expect(state.count, isNull);
    expect(state.level, CompactLevel.none);
    expect(action.id, 'presence.set');
    expect(action.method, 'PUT');
    expect(action.path, '/api/presence/me');
    expect(action.choices.map((c) => c.id), ['office', 'home']);
    expect(action.choices.first.selected, isTrue);
    expect(action.choices.last.body, {'status': 'home'});
  });

  test('rejects other shapes and actions outside the API', () {
    expect(parseCompactState({'level': 'ok'}), isNull);
    expect(parseCompactState({'title': 'plain'}), isNull);
    final state = parseCompactState({
      'title': {'text': 'x'},
      'level': 'later',
      'action': {'id': 'a', 'method': 'POST', 'path': 'https://evil.example'},
    })!;
    expect(state.level, CompactLevel.none);
    expect(state.action, isNull);
  });

  test('reads the kinds the server offers, offline from the copy', () async {
    var online = true;
    final requests = <Uri>[];
    final repo = CompactStateRepositoryRemote(
      api: ModuleApi(
        ApiClient(
          client: MockClient((r) async {
            requests.add(r.url);
            if (!online) throw const SocketException('offline');
            return http.Response.bytes(
              utf8.encode(todos),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
          cache: InMemoryResponseCache(),
          offline: OfflineStatus(),
        ),
      ),
    );
    expect(repo.supports('todos'), isTrue);
    expect(repo.supports('weather'), isFalse);

    expect(await repo.state(testServer(), 'todos'), isA<Ok<CompactState>>());
    expect(requests.single.path, '/api/todos/compact');

    online = false;
    final offline = await repo.state(testServer(), 'todos');
    expect(
      (offline as Ok<CompactState>).value.title.text,
      '3 open · 1 overdue',
    );
  });

  group('derived states (#242)', () {
    late FakeWeatherRepository weather;
    late FakeTransitRepository transit;
    late FakeWasteRepository waste;
    late CompactStateRepositoryRemote repo;

    setUp(() {
      weather = FakeWeatherRepository();
      transit = FakeTransitRepository();
      waste = FakeWasteRepository()
        ..result = const Result.ok([
          WasteCollection(label: 'Paper', dates: [], daysUntil: 1),
        ]);
      repo = CompactStateRepositoryRemote(
        api: ModuleApi(
          ApiClient(
            client: MockClient((_) async => http.Response('', 500)),
            cache: InMemoryResponseCache(),
            offline: OfflineStatus(),
          ),
        ),
        weather: weather,
        transit: transit,
        waste: waste,
        clock: () => DateTime(2026, 11, 19, 10),
      );
    });

    test('weather, transit and waste have one', () {
      expect(repo.supports('weather'), isTrue);
      expect(repo.supports('transit'), isTrue);
      expect(repo.supports('waste'), isTrue);
      expect(repo.supports('clock'), isFalse);
    });

    test('weather reads the configured place', () async {
      final state = await repo.state(
        testServer(),
        'weather',
        config: {'lat': 53.1, 'lon': 8.2},
      );
      expect(weather.calls.single, (53.1, 8.2));
      expect(
        (state as Ok<CompactState>).value.title.text,
        '14 °C, feels like 13 °C',
      );
    });

    test('transit reads the configured stop', () async {
      final state = await repo.state(
        testServer(),
        'transit',
        config: {'stopId': 'de:1'},
      );
      expect(transit.calls.single, (
        'de:1',
        CompactStateRepositoryRemote.departureCount,
      ));
      expect((state as Ok<CompactState>).value.title.text, 'No departures');
    });

    test('waste reads the next collection', () async {
      final state = await repo.state(testServer(), 'waste');
      expect((state as Ok<CompactState>).value.level, CompactLevel.attention);
    });

    test('a missing place or stop is an error without a request', () async {
      expect(
        (await repo.state(testServer(), 'weather') as Error).error,
        isA<CompactConfigMissing>(),
      );
      expect(
        (await repo.state(testServer(), 'transit') as Error).error,
        isA<CompactConfigMissing>(),
      );
      expect(weather.calls, isEmpty);
      expect(transit.calls, isEmpty);
    });

    test('a failed read passes the error on', () async {
      waste.result = const Result.error(CompactConfigMissing());
      expect(
        await repo.state(testServer(), 'waste'),
        isA<Error<CompactState>>(),
      );
    });
  });
}
