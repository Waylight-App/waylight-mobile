import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/notifications_api.dart';
import 'package:waylight_mobile/data/services/push/push_crypto.dart';
import 'package:waylight_mobile/data/services/push/push_token_source.dart';
import 'package:waylight_mobile/domain/models/push.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

final class _Tokens implements PushTokenSource {
  _Tokens(this._token);

  final String? _token;

  @override
  bool get available => true;

  @override
  PushPlatform get platform => PushPlatform.fcm;

  @override
  Future<String?> token() async => _token;
}

void main() {
  late List<http.Request> requests;
  late InMemoryKeyValueStore store;

  PushRepositoryRemote repository(PushTokenSource tokens) {
    requests = [];
    store = InMemoryKeyValueStore();
    final client = ApiClient(
      client: MockClient((request) async {
        requests.add(request);
        return request.method == 'PUT'
            ? http.Response('{"session":"s"}', 200)
            : http.Response('', 204);
      }),
    );
    return PushRepositoryRemote(
      api: NotificationsApi(client),
      crypto: PushCrypto(store),
      tokens: tokens,
      deviceName: 'Android',
    );
  }

  test('registers token and public key with the server', () async {
    final repo = repository(_Tokens('fcm-token'));

    expect(await repo.enable(testServer()), isA<Ok<void>>());
    final put = requests.single;
    expect(put.method, 'PUT');
    expect(put.url.path, '/api/notifications/app-device');
    final body = jsonDecode(put.body) as Map<String, Object?>;
    expect(body['platform'], 'fcm');
    expect(body['token'], 'fcm-token');
    expect(body['name'], 'Android');
    expect(base64Decode(body['publicKey']! as String), hasLength(32));
  });

  test('unregisters and forgets the key', () async {
    final repo = repository(_Tokens('fcm-token'));
    await repo.enable(testServer());

    expect(await repo.disable(testServer()), isA<Ok<void>>());
    expect(requests.last.method, 'DELETE');
    expect(store.values, isEmpty);
  });

  test('reports a denied permission and a build without push', () async {
    final denied = await repository(_Tokens(null)).enable(testServer());
    final none = await repository(const NoPushTokenSource())
        .enable(testServer());

    expect(
      ((denied as Error<void>).error as PushUnavailable).reason,
      PushUnavailableReason.permissionDenied,
    );
    expect(
      ((none as Error<void>).error as PushUnavailable).reason,
      PushUnavailableReason.notInBuild,
    );
    expect(requests, isEmpty);
  });
}
