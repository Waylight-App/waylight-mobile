import 'dart:io';

import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/tag_action.dart';

/// Writes links onto NFC tags (#195).
abstract interface class NfcWriter {
  /// Whether NFC is there and on.
  Future<NfcState> state();

  /// Waits for a tag and writes [link] onto it.
  Future<TagWriteOutcome> write(Uri link);

  /// Stops waiting for a tag.
  Future<void> cancel();
}

/// An [NfcWriter] on the native side of Android (`app.waylight/nfc`).
/// Other platforms report that NFC is missing.
class MethodChannelNfcWriter implements NfcWriter {
  /// Creates the writer; [supported] defaults to whether this is Android
  /// and lets tests reach the channel.
  MethodChannelNfcWriter({bool? supported})
    : _supported = supported ?? Platform.isAndroid;

  static const _channel = MethodChannel('app.waylight/nfc');
  final bool _supported;

  Future<String?> _call(String method, [Object? arguments]) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<String>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // Builds without the native side, e.g. tests on the desktop.
      return null;
    }
  }

  @override
  Future<NfcState> state() async => switch (await _call('state')) {
    'ready' => NfcState.ready,
    'off' => NfcState.off,
    _ => NfcState.missing,
  };

  @override
  Future<TagWriteOutcome> write(Uri link) async {
    if (!_supported) return TagWriteOutcome.unavailable;
    return TagWriteOutcome.parse(
      await _call('write', {'link': link.toString()}),
    );
  }

  @override
  Future<void> cancel() => _call('cancel');
}
