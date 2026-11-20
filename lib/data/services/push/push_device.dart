import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/push.dart';

/// The phone's push side, implemented natively (ADR 0008): the device ID
/// behind the notification permission and the public half of the device
/// key. The private keys never reach Dart; the platform holds the relay's
/// stream and decrypts incoming messages itself.
abstract interface class PushDevice {
  /// Whether this build can receive push notifications at all.
  Future<bool> available();

  /// The push service of the token.
  PushPlatform get platform;

  /// Asks for the notification permission if needed, starts receiving and
  /// returns the device token; `null` if the permission was denied.
  Future<String?> token();

  /// The device's X25519 public key, created on first use.
  Future<Uint8List> publicKey();

  /// Stops receiving and forgets the keys.
  Future<void> forget();

  /// Whether the system lets the app keep its connection without battery
  /// restrictions; without that, Android may cut the stream when idle.
  Future<bool> batteryUnrestricted();

  /// Asks the person to lift the battery restrictions for the app.
  Future<void> requestBatteryUnrestricted();
}

/// A [PushDevice] over the method channel `app.waylight/push`.
final class MethodChannelPushDevice implements PushDevice {
  /// Creates the adapter; the push service follows the platform unless a
  /// test names one.
  const MethodChannelPushDevice({
    this._channel = const MethodChannel('app.waylight/push'),
    this._platform,
  });

  final MethodChannel _channel;
  final PushPlatform? _platform;

  @override
  PushPlatform get platform =>
      _platform ??
      (defaultTargetPlatform == TargetPlatform.iOS
          ? PushPlatform.apns
          : PushPlatform.sse);

  @override
  Future<bool> available() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on MissingPluginException {
      // A platform without the channel, such as desktop builds.
      return false;
    }
  }

  @override
  Future<String?> token() => _channel.invokeMethod<String>('token');

  @override
  Future<Uint8List> publicKey() async =>
      base64Decode(await _channel.invokeMethod<String>('publicKey') ?? '');

  @override
  Future<void> forget() => _channel.invokeMethod<void>('forget');

  @override
  Future<bool> batteryUnrestricted() async {
    try {
      return await _channel.invokeMethod<bool>('batteryUnrestricted') ?? true;
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<void> requestBatteryUnrestricted() =>
      _channel.invokeMethod<void>('requestBatteryUnrestricted');
}
