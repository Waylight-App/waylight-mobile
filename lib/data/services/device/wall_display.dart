import 'package:flutter/services.dart';

/// The screen of a wall display (#193): full screen without system bars,
/// kept on while the kiosk shows.
abstract interface class WallDisplay {
  /// Hides the system bars and keeps the screen on.
  Future<void> enter();

  /// Shows the system bars again and lets the screen sleep.
  Future<void> exit();
}

/// A [WallDisplay] of the phone; the native side (`app.waylight/device`)
/// sets the window flag that keeps the screen on.
final class PlatformWallDisplay implements WallDisplay {
  /// Creates the adapter.
  const PlatformWallDisplay({
    this._channel = const MethodChannel('app.waylight/device'),
  });

  final MethodChannel _channel;

  @override
  Future<void> enter() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await _keepOn(on: true);
  }

  @override
  Future<void> exit() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await _keepOn(on: false);
  }

  Future<void> _keepOn({required bool on}) async {
    try {
      await _channel.invokeMethod<void>('keepScreenOn', {'on': on});
    } on MissingPluginException {
      // No native side on this platform.
    }
  }
}
