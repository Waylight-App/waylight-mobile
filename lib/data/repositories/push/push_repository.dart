import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Why push notifications could not be turned on.
final class PushUnavailable implements Exception {
  /// Creates the failure.
  const PushUnavailable(this.reason);

  /// What failed.
  final PushUnavailableReason reason;
}

/// The reasons of [PushUnavailable].
enum PushUnavailableReason {
  /// This platform has no push notifications yet (iOS, ADR 0010).
  notInBuild,

  /// The person denied the notification permission.
  permissionDenied,
}

/// Push notifications from the server (#59, server ADR 0025 and 0027).
abstract interface class PushRepository {
  /// Whether this build can receive push notifications.
  Future<bool> available();

  /// Asks for the permission, creates the device key and registers the
  /// phone with the server.
  Future<Result<void>> enable(ServerAddress server);

  /// Unregisters the phone and forgets its key.
  Future<Result<void>> disable(ServerAddress server);

  /// Whether the person turned notifications on for this phone.
  Future<bool> isOn();

  /// Registers again when notifications are on, e.g. after the server
  /// forgot the device; does nothing otherwise.
  Future<void> refresh(ServerAddress server);

  /// Whether the app may keep its connection without battery restrictions.
  Future<bool> batteryUnrestricted();

  /// Asks the person to lift the battery restrictions for the app.
  Future<void> requestBatteryUnrestricted();
}
