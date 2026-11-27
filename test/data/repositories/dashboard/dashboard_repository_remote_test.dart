import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  late InMemoryKeyValueStore store;
  late List<http.Request> sent;

  Map<String, Object?> dashboardJson({
    required bool withSizes,
    bool withFavourites = false,
  }) => {
    'tabs': [
      {
        'id': 't',
        'name': 'Home',
        'position': 0,
        'widgets': [
          {'id': 'a', 'kind': 'clock', 'x': 0, 'y': 0},
          {'id': 'b', 'kind': 'todos', 'x': 6, 'y': 0},
        ],
        'mobile': [
          {
            'id': 'a',
            'hidden': false,
            'rows': 1,
            if (withSizes) 'size': 'small',
            if (withFavourites) 'favourite': true,
          },
          {
            'id': 'b',
            'hidden': false,
            'rows': 1,
            if (withSizes) 'size': '',
            if (withFavourites) 'favourite': false,
          },
        ],
      },
    ],
  };

  DashboardRepositoryRemote repository({
    required bool withSizes,
    bool withFavourites = false,
  }) => DashboardRepositoryRemote(
    api: DashboardApi(
      ApiClient(
        client: MockClient((request) async {
          sent.add(request);
          return http.Response(
            request.method == 'GET'
                ? jsonEncode(
                    dashboardJson(
                      withSizes: withSizes,
                      withFavourites: withFavourites,
                    ),
                  )
                : '{}',
            200,
          );
        }),
      ),
    ),
    store: store,
  );

  Future<DashboardTab> tab(DashboardRepositoryRemote repo) async =>
      ((await repo.dashboard(testServer())) as Ok<Dashboard>).value.tabs.single;

  setUp(() {
    store = InMemoryKeyValueStore();
    sent = [];
  });

  group('server without sizes', () {
    test('keeps sizes on the device and never sends them', () async {
      final repo = repository(withSizes: false);
      final layout = (await tab(repo)).layout;

      await repo.saveLayout(testServer(), 't', [
        layout.first.withSize(WidgetSize.medium),
        layout.last,
      ]);

      final body = jsonDecode(sent.last.body) as Map<String, Object?>;
      expect(
        (body['items']! as List<Object?>).every(
          (i) => !(i! as Map<String, Object?>).containsKey('size'),
        ),
        isTrue,
      );
      final reloaded = await tab(repo);
      expect(reloaded.sizes, {'a': WidgetSize.medium});
      expect(reloaded.layout.first.size, WidgetSize.medium);
      expect(reloaded.sizesOnServer, isFalse);
    });

    test('a tab without sizes reads as before (#336)', () async {
      final repo = repository(withSizes: false);
      final layout = (await tab(repo)).layout;
      await repo.saveLayout(testServer(), 't', layout);

      final reloaded = await tab(repo);
      expect(reloaded.sizes, isEmpty);
      expect(reloaded.layout.map((i) => i.size), everyElement(isNull));
    });

    test('keeps default sizes given to every widget (#336)', () async {
      final repo = repository(withSizes: false);
      final layout = (await tab(repo)).layout;
      await repo.saveLayout(testServer(), 't', [
        for (final item in layout) item.withSize(WidgetSize.medium),
      ]);

      expect((await tab(repo)).sizes, {
        'a': WidgetSize.medium,
        'b': WidgetSize.medium,
      });
    });

    test('forgets the sizes of a tab on reset', () async {
      final repo = repository(withSizes: false);
      final layout = (await tab(repo)).layout;
      await repo.saveLayout(testServer(), 't', [
        layout.first.withSize(WidgetSize.small),
        layout.last,
      ]);

      await repo.resetLayout(testServer(), 't');

      expect((await tab(repo)).sizes, isEmpty);
    });

    test('forgets everything on clear', () async {
      final repo = repository(withSizes: false);
      final layout = (await tab(repo)).layout;
      await repo.saveLayout(testServer(), 't', [
        layout.first.withSize(WidgetSize.small),
        layout.last,
      ]);

      await repo.clear();

      expect(store.values, isEmpty);
    });
  });

  group('server with sizes', () {
    test('reads and sends the sizes of the server', () async {
      final repo = repository(withSizes: true);
      final loaded = await tab(repo);
      expect(loaded.sizesOnServer, isTrue);
      expect(loaded.sizes, {'a': WidgetSize.small});

      await repo.saveLayout(testServer(), 't', [
        loaded.layout.first.withSize(WidgetSize.large),
        loaded.layout.last,
      ]);

      final body = jsonDecode(sent.last.body) as Map<String, Object?>;
      expect(body['items'], [
        {'id': 'a', 'hidden': false, 'rows': 1, 'size': 'large'},
        {'id': 'b', 'hidden': false, 'rows': 1, 'size': ''},
      ]);
      expect(store.values, isEmpty, reason: 'nothing kept on the device');
    });
  });

  group('favourites (#333)', () {
    test('kept on the device for servers without them', () async {
      final repo = repository(withSizes: true);
      final layout = (await tab(repo)).layout;
      expect((await tab(repo)).favouritesOnServer, isFalse);

      await repo.saveLayout(testServer(), 't', [
        layout.first,
        layout.last.copyWith(favourite: true),
      ]);

      final body = jsonDecode(sent.last.body) as Map<String, Object?>;
      expect(
        (body['items']! as List<Object?>).every(
          (i) => !(i! as Map<String, Object?>).containsKey('favourite'),
        ),
        isTrue,
        reason: 'older servers reject unknown fields',
      );
      // A new repository reads what an earlier start stored.
      final reloaded = await tab(repository(withSizes: true));
      expect(reloaded.favourites, {'b'});
      expect(reloaded.layout.last.favourite, isTrue);

      await repo.resetLayout(testServer(), 't');
      expect((await tab(repo)).favourites, isEmpty);
    });

    test('read from and sent to servers with them', () async {
      final repo = repository(withSizes: true, withFavourites: true);
      final loaded = await tab(repo);
      expect(loaded.favouritesOnServer, isTrue);
      expect(loaded.favourites, {'a'});

      await repo.saveLayout(testServer(), 't', [
        loaded.layout.first.copyWith(favourite: false),
        loaded.layout.last.copyWith(favourite: true),
      ]);

      final body = jsonDecode(sent.last.body) as Map<String, Object?>;
      expect(body['items'], [
        {
          'id': 'a',
          'hidden': false,
          'rows': 1,
          'size': 'small',
          'favourite': false,
        },
        {'id': 'b', 'hidden': false, 'rows': 1, 'size': '', 'favourite': true},
      ]);
      expect(store.values, isEmpty, reason: 'nothing kept on the device');
    });
  });
}
