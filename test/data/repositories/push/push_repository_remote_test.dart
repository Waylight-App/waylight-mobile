import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/notifications_api.dart';
import 'package:waylight_mobile/data/services/push/push_device.dart';
import 'package:waylight_mobile/domain/models/push.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

final class _Device implements PushDevice {
  _Device({this.isAvailable = true, this.tokenValue = 'fcm-token'});

  final bool isAvailable;
  final String? tokenValue;
  bool forgotten = false;

  @override
  Future<bool> available() async => isAvailable;

  @override
  PushPlatform get platform => PushPlatform.fcm;

  @override
  Future<String?> token() async => tokenValue;

  @override
  Future<Uint8List> publicKey() async => Uint8List(32)..[0] = 7;

  @override
  Future<void> forget() async => forgotten = true;
}

void main() {
  late List<http.Request> requests;

  PushRepositoryRemote repository(PushDevice device) {
    requests = [];
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
      device: device,
      deviceName: 'Android',
    );
  }

  test('registers token and public key with the server', () async {
    final repo = repository(_Device());

    expect(await repo.enable(testServer()), isA<Ok<void>>());
    final put = requests.single;
    expect(put.method, 'PUT');
    expect(put.url.path, '/api/notifications/app-device');
    final body = jsonDecode(put.body) as Map<String, Object?>;
    expect(body['platform'], 'fcm');
    expect(body['token'], 'fcm-token');
    expect(body['name'], 'Android');
    expect(base64Decode(body['publicKey']! as String)[0], 7);
  });

  test('unregisters and forgets the key', () async {
    final device = _Device();
    final repo = repository(device);

    expect(await repo.disable(testServer()), isA<Ok<void>>());
    expect(requests.single.method, 'DELETE');
    expect(device.forgotten, isTrue);
  });

  test('reports a denied permission and a build without push', () async {
    final denied = await repository(_Device(tokenValue: null))
        .enable(testServer());
    final none = await repository(_Device(isAvailable: false))
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
