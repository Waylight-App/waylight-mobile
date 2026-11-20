import 'package:waylight_mobile/data/services/device/device_info.dart';

/// A [DeviceInfo] for tests that records what was shared.
class FakeDeviceInfo implements DeviceInfo {
  /// The texts passed to the share sheet.
  final List<String> shared = [];

  @override
  Future<String> describe() async => 'Android 15 (API 35), Test Phone';

  @override
  Future<void> shareText(String text, {required String subject}) async =>
      shared.add(text);
}
