import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/push.dart';

/// The phone's push side, implemented natively (ADR 0008): the push token
/// behind the notification permission and the public half of the device
/// key. The private key never reaches Dart; the platform decrypts incoming
/// messages itself.
abstract interface class PushDevice {
  /// Whether this build can receive push notifications at all.
  Future<bool> available();

  /// The push service of the token.
  PushPlatform get platform;

  /// Asks for the notification permission if needed and returns the
  /// token; `null` if the permission was denied or no token is available.
  Future<String?> token();

  /// The device's X25519 public key, created on first use.
  Future<Uint8List> publicKey();

  /// Forgets the key pair and the token.
  Future<void> forget();
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
          : PushPlatform.fcm);

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
}
