import 'dart:convert';
import 'dart:typed_data';

import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/push.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The push device endpoints of the server (`api/modules/backup.yaml`,
/// notifications; server #564).
class NotificationsApi {
  /// Creates the service on top of an [ApiClient].
  const NotificationsApi(this._client);

  final ApiClient _client;

  /// Registers this phone for push notifications with `PUT
  /// /api/notifications/app-device`; only app sessions of admins may.
  Future<Result<void>> register(
    ServerAddress server, {
    required String name,
    required PushPlatform platform,
    required String token,
    required Uint8List publicKey,
  }) async {
    final result = await _client.putJson(
      server.resolve('/api/notifications/app-device'),
      body: {
        'name': name,
        'platform': platform.name,
        'token': token,
        'publicKey': base64Encode(publicKey),
      },
    );
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  /// Stops push notifications to this phone (`DELETE
  /// /api/notifications/app-device`).
  Future<Result<void>> unregister(ServerAddress server) =>
      _client.delete(server.resolve('/api/notifications/app-device'));
}
