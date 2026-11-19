import 'dart:typed_data';

import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/services/api/notifications_api.dart';
import 'package:waylight_mobile/data/services/push/push_crypto.dart';
import 'package:waylight_mobile/data/services/push/push_token_source.dart';
import 'package:waylight_mobile/domain/models/push.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [PushRepository] that registers with the server's notifications
/// module.
class PushRepositoryRemote implements PushRepository {
  /// Creates the repository; the device name names the phone in the
  /// settings of the web interface.
  PushRepositoryRemote({
    required this._api,
    required this._crypto,
    required this._tokens,
    required this._deviceName,
  });

  final NotificationsApi _api;
  final PushCrypto _crypto;
  final PushTokenSource _tokens;
  final String _deviceName;

  @override
  bool get available => _tokens.available;

  @override
  Future<Result<void>> enable(ServerAddress server) async {
    if (!_tokens.available) {
      return const Result.error(
        PushUnavailable(PushUnavailableReason.notInBuild),
      );
    }
    final token = await _tokens.token();
    if (token == null) {
      return const Result.error(
        PushUnavailable(PushUnavailableReason.permissionDenied),
      );
    }
    return _api.register(
      server,
      name: _deviceName,
      platform: _tokens.platform,
      token: token,
      publicKey: await _crypto.publicKey(),
    );
  }

  @override
  Future<Result<void>> disable(ServerAddress server) async {
    final result = await _api.unregister(server);
    // The key is forgotten even if the server cannot be reached: the
    // server drops the device with the session anyway (#564).
    await _crypto.forget();
    return result;
  }

  @override
  Future<PushContent?> open(Uint8List sealed) => _crypto.open(sealed);
}
