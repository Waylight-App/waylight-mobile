import 'package:local_auth/local_auth.dart';

/// The phone's own way to confirm the owner: biometrics or the device PIN.
abstract interface class DeviceAuth {
  /// Whether the phone has a screen lock the app can ask for.
  Future<bool> available();

  /// Asks the person to confirm with [reason] shown; `true` on success.
  Future<bool> confirm(String reason);
}

/// [DeviceAuth] through the platform's local authentication (#46).
final class LocalDeviceAuth implements DeviceAuth {
  /// Creates the service.
  LocalDeviceAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> confirm(String reason) async {
    try {
      // Not biometric only: the device PIN works as well (#46).
      return await _auth.authenticate(localizedReason: reason);
    } on Exception {
      return false;
    }
  }
}
