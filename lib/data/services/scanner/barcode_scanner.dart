import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads a barcode or QR code with the camera (#196). Recognition happens
/// on the device (ADR 0014); no image is kept or sent.
abstract interface class BarcodeScanner {
  /// Whether this platform can scan.
  Future<bool> available();

  /// Opens the camera and returns the text of the code, or `null` when the
  /// person cancelled. [prompt] is shown over the camera.
  Future<String?> scan({String prompt = ''});
}

/// A [BarcodeScanner] over the channel `app.waylight/scan`.
final class MethodChannelBarcodeScanner implements BarcodeScanner {
  /// Creates the adapter.
  const MethodChannelBarcodeScanner({
    this._channel = const MethodChannel('app.waylight/scan'),
  });

  final MethodChannel _channel;

  @override
  Future<bool> available() async =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<String?> scan({String prompt = ''}) async {
    try {
      return await _channel.invokeMethod<String>('scan', {'prompt': prompt});
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
