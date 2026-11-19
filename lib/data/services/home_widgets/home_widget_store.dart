import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/home_snapshot.dart';

/// Where the home screen widgets read their data from (#42).
abstract interface class HomeWidgetStore {
  /// Saves [card] for the widget [kind] and redraws it.
  Future<void> save(HomeWidgetKind kind, HomeWidgetCard card);

  /// Removes the data of every widget, e.g. after signing out.
  Future<void> clear();

  /// Turns the refresh in the background on or off (#48).
  Future<void> schedule({required bool enabled});

  /// Reports the end of a background refresh to the native job.
  Future<void> finished();
}

/// A [HomeWidgetStore] on the native side of Android
/// (`app.waylight/home`). Other platforms have no widgets yet, so calls do
/// nothing there.
class MethodChannelHomeWidgetStore implements HomeWidgetStore {
  /// Creates the store.
  MethodChannelHomeWidgetStore() : _supported = Platform.isAndroid;

  static const _channel = MethodChannel('app.waylight/home');
  final bool _supported;

  Future<void> _call(String method, [Object? arguments]) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // A widget that is not redrawn shows its older data; nothing to do.
    } on MissingPluginException {
      // Builds without the native side, e.g. tests on the desktop.
    }
  }

  @override
  Future<void> save(HomeWidgetKind kind, HomeWidgetCard card) =>
      _call('save', {'kind': kind.name, 'card': jsonEncode(card.toJson())});

  @override
  Future<void> clear() => _call('clear');

  @override
  Future<void> schedule({required bool enabled}) =>
      _call('schedule', {'enabled': enabled});

  @override
  Future<void> finished() => _call('done');
}
