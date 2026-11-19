import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  late InMemoryKeyValueStore store;
  late List<Uri> requests;

  ServerRepositoryRemote repository(http.Response Function() answer) {
    return ServerRepositoryRemote(
      platformApi: PlatformApi(
        ApiClient(
          client: MockClient((request) async {
            requests.add(request.url);
            return answer();
          }),
        ),
      ),
      store: store,
    );
  }

  http.Response waylight({bool setupRequired = false}) => http.Response(
    '{"setupRequired":$setupRequired,"authenticated":false}',
    200,
  );

  setUp(() {
    store = InMemoryKeyValueStore();
    requests = [];
  });

  group('connect', () {
    test('checks the auth status, saves and notifies', () async {
      final repo = repository(() => waylight(setupRequired: true));
      var notified = 0;
      repo.addListener(() => notified++);

      final result = await repo.connect(testServer());

      expect(
        (result as Ok<ServerStatus>).value,
        const ServerStatus(setupRequired: true),
      );
      expect(requests.single.path, '/api/auth/status');
      expect(repo.current, testServer());
      expect(
        store.values[ServerRepositoryRemote.storageKey],
        'https://home.example.org',
      );
      expect(notified, 1);
    });

    test('rejects an answer that is not from Waylight', () async {
      final repo = repository(() => http.Response('<html></html>', 200));

      final result = await repo.connect(testServer());

      final error = (result as Error<ServerStatus>).error as ApiException;
      expect(error.failure, ApiFailure.server);
      expect(repo.current, isNull);
      expect(store.values, isEmpty);
    });

    test('keeps nothing when the server is unreachable', () async {
      final repo = ServerRepositoryRemote(
        platformApi: PlatformApi(
          ApiClient(
            client: MockClient((_) => throw http.ClientException('down')),
          ),
        ),
        store: store,
      );

      final result = await repo.connect(testServer());

      expect(result, isA<Error<ServerStatus>>());
      expect(repo.current, isNull);
    });
  });

  group('restore', () {
    test('loads a saved address without a request', () async {
      store.values[ServerRepositoryRemote.storageKey] = 'https://a.example';
      final repo = repository(waylight);

      await repo.restore();

      expect(repo.current, testServer('https://a.example'));
      expect(requests, isEmpty);
    });

    test('drops a saved address that is invalid', () async {
      store.values[ServerRepositoryRemote.storageKey] = 'ftp://a.example';
      final repo = repository(waylight);

      await repo.restore();

      expect(repo.current, isNull);
      expect(store.values, isEmpty);
    });
  });

  test('status fails without a server', () async {
    final result = await repository(waylight).status();

    expect((result as Error<ServerStatus>).error, isA<NotConnectedException>());
  });

  test('disconnect forgets the server', () async {
    final repo = repository(waylight);
    await repo.connect(testServer());

    await repo.disconnect();

    expect(repo.current, isNull);
    expect(store.values[ServerRepositoryRemote.storageKey], isNull);
    expect(repo.known, isEmpty);
  });

  test('keeps a list of servers to switch between', () async {
    final repo = repository(waylight);
    final other = testServer('https://other.example.org');
    await repo.connect(testServer());
    await repo.leave();
    await repo.connect(other);

    expect(repo.known, [testServer(), other]);

    await repo.switchTo(testServer());
    expect(repo.current, testServer());

    final restarted = repository(waylight);
    await restarted.restore();
    expect(restarted.known, [testServer(), other]);
    expect(restarted.current, testServer());

    await restarted.forget(other);
    expect(restarted.known, [testServer()]);
    await restarted.forget(testServer());
    expect(restarted.current, isNull);
  });
}
