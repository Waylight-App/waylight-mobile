import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/data/services/cache/response_cache.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/in_memory_response_cache.dart';

void main() {
  group('file cache', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('offline_test'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('stores, reads, trims and clears answers', () async {
      final cache = FileResponseCache(() async => dir, maxBytes: 200);
      final at = DateTime.utc(2026, 11, 19, 8);
      final a = Uri.parse('https://h.example.org/api/notes');

      expect(await cache.read(a), isNull);
      await cache.write(a, '{"x":1}', at);
      expect(await cache.read(a), (body: '{"x":1}', storedAt: at));
      expect(
        dir.listSync().map((f) => f.path).join(),
        isNot(contains('notes')),
        reason: 'file names must not reveal the address',
      );

      for (var i = 0; i < 10; i++) {
        await cache.write(
          Uri.parse('https://h.example.org/api/x$i'),
          'y' * 40,
          at,
        );
      }
      final size = dir.listSync().whereType<File>().fold(
        0,
        (s, f) => s + f.lengthSync(),
      );
      expect(size, lessThanOrEqualTo(200));

      await cache.clear();
      expect(await cache.read(a), isNull);
    });
  });

  group('API client', () {
    final notes = Uri.parse('https://h.example.org/api/notes');
    final login = Uri.parse('https://h.example.org/api/auth/status');
    late InMemoryResponseCache cache;
    late OfflineStatus offline;
    late bool reachable;
    late DateTime now;

    ApiClient client() => ApiClient(
      cache: cache,
      offline: offline,
      now: () => now,
      client: MockClient((request) async {
        if (!reachable) throw http.ClientException('offline');
        return http.Response('[{"id":"1"}]', 200);
      }),
    );

    setUp(() {
      cache = InMemoryResponseCache();
      offline = OfflineStatus();
      reachable = true;
      now = DateTime.utc(2026, 11, 19, 8);
    });

    test('serves the last answer when the server cannot be reached', () async {
      await client().getJson(notes);
      reachable = false;
      now = now.add(const Duration(hours: 1));

      final result = await client().getJson(notes);

      expect((result as Ok<Object?>).value, [
        {'id': '1'},
      ]);
      expect(offline.showingDataFrom, DateTime.utc(2026, 11, 19, 8));
    });

    test('clears the offline note when the server answers again', () async {
      await client().getJson(notes);
      reachable = false;
      await client().getJson(notes);
      reachable = true;

      await client().getJson(notes);

      expect(offline.showingDataFrom, isNull);
    });

    test('never keeps sign-in answers', () async {
      await client().getJson(login);

      expect(cache.entries, isEmpty);
    });

    test('does not show answers older than seven days', () async {
      await client().getJson(notes);
      reachable = false;
      now = now.add(const Duration(days: 8));

      final result = await client().getJson(notes);

      expect(
        ((result as Error<Object?>).error as ApiException).failure,
        ApiFailure.unreachable,
      );
    });
  });
}
