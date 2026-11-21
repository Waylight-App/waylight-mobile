import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/device_control.dart';

/// Where Android's device controls read what they show (#194).
abstract interface class DeviceControlsStore {
  /// Saves [snapshot] and updates the controls on screen.
  Future<void> save(DeviceControlsSnapshot snapshot);

  /// Forgets every control, e.g. after signing out.
  Future<void> clear();

  /// Reports the end of a background run to the native side.
  Future<void> finished();
}

/// A [DeviceControlsStore] on the native side of Android
/// (`app.waylight/controls`). Other platforms have no device controls, so
/// calls do nothing there.
class MethodChannelDeviceControlsStore implements DeviceControlsStore {
  /// Creates the store; [supported] defaults to whether this is Android
  /// and lets tests reach the channel.
  MethodChannelDeviceControlsStore({bool? supported})
    : _supported = supported ?? Platform.isAndroid;

  static const _channel = MethodChannel('app.waylight/controls');
  final bool _supported;

  Future<void> _call(String method, [Object? arguments]) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // The controls keep what they showed; the next refresh tries again.
    } on MissingPluginException {
      // Builds without the native side, e.g. tests on the desktop.
    }
  }

  @override
  Future<void> save(DeviceControlsSnapshot snapshot) =>
      _call('save', {'state': jsonEncode(snapshot.toJson())});

  @override
  Future<void> clear() => _call('clear');

  @override
  Future<void> finished() => _call('finished');
}
