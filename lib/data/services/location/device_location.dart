import 'package:flutter/services.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Reads the approximate position of the phone (#295).
abstract interface class DeviceLocation {
  /// Whether this platform can tell its position.
  bool get available;

  /// The coarse position. Asks for the permission when it is missing, so
  /// call it only after a tap. Fails with [LocationDenied] or
  /// [LocationUnavailable].
  Future<Result<Coordinates>> coarse();
}

/// A [DeviceLocation] over the channel `app.waylight/location`, which uses
/// the platform's LocationManager and no Google service.
final class MethodChannelDeviceLocation implements DeviceLocation {
  /// Creates the adapter; [available] says whether the channel exists.
  const MethodChannelDeviceLocation({
    required this.available,
    this._channel = const MethodChannel('app.waylight/location'),
  });

  @override
  final bool available;

  final MethodChannel _channel;

  @override
  Future<Result<Coordinates>> coarse() async {
    try {
      final answer = await _channel.invokeMapMethod<String, Object?>('coarse');
      return switch (answer) {
        {'status': 'ok', 'lat': final num lat, 'lon': final num lon} =>
          Result.ok((lat: lat.toDouble(), lon: lon.toDouble())),
        {'status': 'denied'} => const Result.error(LocationDenied()),
        _ => const Result.error(LocationUnavailable()),
      };
    } on MissingPluginException {
      return const Result.error(LocationUnavailable());
    } on PlatformException {
      return const Result.error(LocationUnavailable());
    }
  }
}
