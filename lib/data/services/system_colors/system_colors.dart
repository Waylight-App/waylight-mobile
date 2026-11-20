import 'package:flutter/services.dart';

/// The colours the system takes from the wallpaper (Android 12 and newer,
/// #198), through the native channel `app.waylight/colors`.
abstract interface class SystemColors {
  /// The system's accent as ARGB, or `null` where the system offers no
  /// wallpaper colours.
  Future<int?> accent();
}

/// A [SystemColors] over the method channel. The native side reads
/// `system_accent1_500`, the seed Android derives its own palettes from;
/// the app builds its scheme from it with `ColorScheme.fromSeed`, so no
/// extra package is needed (ADR 0003).
final class MethodChannelSystemColors implements SystemColors {
  /// Creates the adapter.
  const MethodChannelSystemColors({
    this._channel = const MethodChannel('app.waylight/colors'),
  });

  final MethodChannel _channel;

  @override
  Future<int?> accent() async {
    try {
      return await _channel.invokeMethod<int>('accent');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
