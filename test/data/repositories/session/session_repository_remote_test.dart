import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/repositories/session/session_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/domain/models/session.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  late InMemoryKeyValueStore store;
  late ApiCredentials credentials;
  late ApiClient client;
  late List<http.Request> requests;
  late http.Response Function(http.Request) answer;

  SessionRepositoryRemote createRepository() => SessionRepositoryRemote(
    authApi: AuthApi(client),
    credentials: credentials,
    store: store,
    deviceName: 'Pixel',
  );

  // A server without app sessions (phase 1): 404 for app sessions, a
  // cookie for the login.
  http.Response signedInAnswer(http.Request request) =>
      request.url.path == '/api/auth/app-sessions'
      ? http.Response('{"error":{"code":"not_found"}}', 404)
      : http.Response(
          '{"csrfToken":"csrf"}',
          200,
          headers: {'set-cookie': 'waylight_session=tok; Path=/; HttpOnly'},
        );

  setUp(() {
    store = InMemoryKeyValueStore();
    credentials = ApiCredentials();
    requests = [];
    answer = signedInAnswer;
    client = ApiClient(
      credentials: credentials,
      client: MockClient((request) async {
        requests.add(request);
        return answer(request);
      }),
    );
  });

  test('signs in, stores the session and notifies', () async {
    final repository = createRepository();
    var notified = 0;
    repository.addListener(() => notified++);

    final result = await repository.signIn(testServer(), password: 'pw');

    expect((result as Ok<SignInResult>).value, isA<SignedIn>());
    expect(repository.signedIn, isTrue);
    expect(notified, 1);
    expect(
      (credentials.session! as BrowserSession).cookie,
      'waylight_session=tok',
    );
    expect(
      jsonDecode(store.values[SessionRepositoryRemote.storageKey]!),
      containsPair('csrfToken', 'csrf'),
    );
  });

  test('restores the session of the same server only', () async {
    await createRepository().signIn(testServer(), password: 'pw');

    final same = createRepository();
    await same.restore(testServer());
    expect(same.signedIn, isTrue);

    final other = createRepository();
    credentials.session = null;
    await other.restore(testServer('https://other.example.org'));
    expect(other.signedIn, isFalse);
    expect(store.values, isEmpty);
  });

  test('ignores a corrupt stored session', () async {
    store.values[SessionRepositoryRemote.storageKey] = '{not json';
    final repository = createRepository();

    expect(await repository.restore(testServer()), isA<Ok<void>>());
    expect(repository.signedIn, isFalse);
  });

  test('signs out on the server and on the device', () async {
    final repository = createRepository();
    await repository.signIn(testServer(), password: 'pw');
    answer = (_) => http.Response('', 204);

    await repository.signOut();

    expect(requests.last.url.path, '/api/auth/logout');
    expect(requests.last.headers['X-CSRF-Token'], 'csrf');
    expect(repository.signedIn, isFalse);
    expect(repository.expired, isFalse);
    expect(store.values, isEmpty);
  });

  test('signs out on the device when the server is unreachable', () async {
    final repository = createRepository();
    await repository.signIn(testServer(), password: 'pw');
    answer = (_) => throw http.ClientException('offline');

    expect(await repository.signOut(), isA<Ok<void>>());
    expect(repository.signedIn, isFalse);
    expect(store.values, isEmpty);
  });

  test('a 401 anywhere ends the session as expired', () async {
    final repository = createRepository();
    await repository.signIn(testServer(), password: 'pw');
    answer = (_) => http.Response('', 401);

    await client.getJson(testServer().resolve('/api/dashboard'));
    await Future<void>.delayed(Duration.zero);

    expect(repository.signedIn, isFalse);
    expect(repository.expired, isTrue);
    expect(store.values, isEmpty);
  });

  test('passes a second step on without storing anything', () async {
    answer = (_) => http.Response('{"secondFactor":{"totp":true}}', 202);
    final repository = createRepository();

    final result = await repository.signIn(testServer(), password: 'pw');

    final step = (result as Ok<SignInResult>).value as CodeRequired;
    expect(step.authenticatorApp, isTrue);
    expect(repository.signedIn, isFalse);
    expect(store.values, isEmpty);
  });

  test('removes spaces from the code', () async {
    await createRepository().signIn(
      testServer(),
      password: 'pw',
      code: '123 456',
    );

    expect(jsonDecode(requests.last.body), containsPair('code', '123456'));
  });

  group('app sessions', () {
    setUp(() {
      answer = (request) => request.url.path == '/api/auth/app-sessions'
          ? http.Response('{"token":"wa_t","device":"Pixel"}', 201)
          : http.Response('', 204);
    });

    test(
      'are created with the device name where the server offers them',
      () async {
        final repository = createRepository();

        final result = await repository.signIn(testServer(), password: 'pw');

        expect((result as Ok<SignInResult>).value, isA<SignedIn>());
        expect(requests.single.url.path, '/api/auth/app-sessions');
        expect(
          jsonDecode(requests.single.body),
          containsPair('device', 'Pixel'),
        );
        expect(
          credentials.session,
          AppSession(server: testServer(), token: 'wa_t'),
        );
      },
    );

    test('survive a restart and go out as bearer token', () async {
      await createRepository().signIn(testServer(), password: 'pw');
      credentials.session = null;

      final restored = createRepository();
      await restored.restore(testServer());
      await client.getJson(testServer().resolve('/api/dashboard'));

      expect(restored.signedIn, isTrue);
      expect(requests.last.headers['authorization'], 'Bearer wa_t');
      expect(requests.last.headers['cookie'], isNull);
    });

    test('a revoked app session signs out with an explanation', () async {
      final repository = createRepository();
      await repository.signIn(testServer(), password: 'pw');
      answer = (_) => http.Response('', 401);

      await client.getJson(testServer().resolve('/api/dashboard'));
      await Future<void>.delayed(Duration.zero);

      expect(repository.signedIn, isFalse);
      expect(repository.expired, isTrue);
    });
  });

  test('restores browser sessions stored before app sessions', () async {
    store.values[SessionRepositoryRemote.storageKey] = jsonEncode({
      'server': testServer().toString(),
      'cookie': 'waylight_session=old',
      'csrfToken': 'csrf',
    });
    final repository = createRepository();

    await repository.restore(testServer());

    expect(credentials.session, isA<BrowserSession>());
  });

  test('pairs with a code from the QR code', () async {
    answer = (_) => http.Response('{"token":"wa_p","device":"Pixel"}', 201);
    final repository = createRepository();

    final result = await repository.pair(testServer(), ' c0de ');

    expect(result, isA<Ok<void>>());
    expect(jsonDecode(requests.single.body), {
      'device': 'Pixel',
      'pairingCode': 'c0de',
    });
    expect(
      credentials.session,
      AppSession(server: testServer(), token: 'wa_p'),
    );
    expect(store.values, isNotEmpty);
  });

  test('passes a rejected pairing code on', () async {
    answer = (_) => http.Response('{"error":{"code":"unauthorized"}}', 401);
    final repository = createRepository();

    final result = await repository.pair(testServer(), 'old');

    expect(result, isA<Error<void>>());
    expect(repository.signedIn, isFalse);
  });
}
