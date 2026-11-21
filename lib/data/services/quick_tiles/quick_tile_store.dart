import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/quick_tile.dart';

/// Where the Quick Settings tiles read what they show (#192).
abstract interface class QuickTileStore {
  /// Saves [state] for the tile [kind] and redraws it.
  Future<void> save(QuickTileKind kind, QuickTileState state);

  /// Offers or hides the tile [kind] in the system's tile list.
  Future<void> offer(QuickTileKind kind, {required bool offered});

  /// Stores the entity the smart home tile switches.
  Future<void> choose(QuickTileEntity entity);

  /// The entity the smart home tile switches, if one was chosen.
  Future<QuickTileEntity?> choice();

  /// Removes every state and choice, e.g. after signing out.
  Future<void> clear();

  /// Reports the end of a tile's action to the native side.
  Future<void> finished();
}

/// A [QuickTileStore] on the native side of Android (`app.waylight/tiles`).
/// Other platforms have no tiles, so calls do nothing there.
class MethodChannelQuickTileStore implements QuickTileStore {
  /// Creates the store.
  MethodChannelQuickTileStore() : _supported = Platform.isAndroid;

  static const _channel = MethodChannel('app.waylight/tiles');
  final bool _supported;

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      // A tile that is not redrawn shows its older state; nothing to do.
      return null;
    } on MissingPluginException {
      // Builds without the native side, e.g. tests on the desktop.
      return null;
    }
  }

  @override
  Future<void> save(QuickTileKind kind, QuickTileState state) => _call<void>(
    'save',
    {'kind': kind.name, 'state': jsonEncode(state.toJson())},
  );

  @override
  Future<void> offer(QuickTileKind kind, {required bool offered}) =>
      _call<void>('offer', {'kind': kind.name, 'offered': offered});

  @override
  Future<void> choose(QuickTileEntity entity) =>
      _call<void>('choose', {'id': entity.id, 'name': entity.name});

  @override
  Future<QuickTileEntity?> choice() async {
    final map = await _call<Map<Object?, Object?>>('choice');
    return switch (map) {
      {'id': final String id, 'name': final String name} => QuickTileEntity(
        id: id,
        name: name,
      ),
      _ => null,
    };
  }

  @override
  Future<void> clear() => _call<void>('clear');

  @override
  Future<void> finished() => _call<void>('done');
}
