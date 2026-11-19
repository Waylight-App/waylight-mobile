import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/services/api/notifications_api.dart';
import 'package:waylight_mobile/data/services/push/push_device.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [PushRepository] that registers with the server's notifications
/// module.
class PushRepositoryRemote implements PushRepository {
  /// Creates the repository; the device name names the phone in the
  /// settings of the web interface.
  PushRepositoryRemote({
    required this._api,
    required this._device,
    required this._deviceName,
  });

  final NotificationsApi _api;
  final PushDevice _device;
  final String _deviceName;

  @override
  Future<bool> available() => _device.available();

  @override
  Future<Result<void>> enable(ServerAddress server) async {
    if (!await _device.available()) {
      return const Result.error(
        PushUnavailable(PushUnavailableReason.notInBuild),
      );
    }
    final token = await _device.token();
    if (token == null) {
      return const Result.error(
        PushUnavailable(PushUnavailableReason.permissionDenied),
      );
    }
    return _api.register(
      server,
      name: _deviceName,
      platform: _device.platform,
      token: token,
      publicKey: await _device.publicKey(),
    );
  }

  @override
  Future<Result<void>> disable(ServerAddress server) async {
    final result = await _api.unregister(server);
    // The key is forgotten even if the server cannot be reached: the
    // server drops the device with the session anyway.
    await _device.forget();
    return result;
  }
}
