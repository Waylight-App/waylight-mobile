import 'package:flutter/services.dart';

/// The phone, through the native channel `app.waylight/device` (#197).
abstract interface class DeviceInfo {
  /// Operating system and model, e.g. "Android 14 (API 34), Pixel 8".
  Future<String> describe();

  /// Opens the system share sheet with [text]; nothing is sent otherwise.
  Future<void> shareText(String text, {required String subject});
}

/// A [DeviceInfo] over the method channel.
final class MethodChannelDeviceInfo implements DeviceInfo {
  /// Creates the adapter.
  const MethodChannelDeviceInfo({
    this._channel = const MethodChannel('app.waylight/device'),
  });

  final MethodChannel _channel;

  @override
  Future<String> describe() async {
    try {
      return await _channel.invokeMethod<String>('describe') ?? 'unknown';
    } on MissingPluginException {
      return 'unknown';
    }
  }

  @override
  Future<void> shareText(String text, {required String subject}) =>
      _channel.invokeMethod<void>('share', {'text': text, 'subject': subject});
}
