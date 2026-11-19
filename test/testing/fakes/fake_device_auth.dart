import 'package:waylight_mobile/data/services/platform/device_auth.dart';

/// A [DeviceAuth] that answers as told, for tests.
class FakeDeviceAuth implements DeviceAuth {
  /// Creates the fake.
  FakeDeviceAuth({this.isAvailable = true, this.succeeds = true});

  /// What [available] answers.
  bool isAvailable;

  /// What [confirm] answers.
  bool succeeds;

  /// How often the person was asked.
  int asked = 0;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<bool> confirm(String reason) async {
    asked++;
    return succeeds;
  }
}
