import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [ServerRepository] that checks servers over the network and keeps the
/// address in a [KeyValueStore].
class ServerRepositoryRemote extends ServerRepository {
  /// Creates the repository.
  ServerRepositoryRemote({required this._platformApi, required this._store});

  /// The key under which the server address is stored.
  static const storageKey = 'server.address';

  /// The key of the list of servers used on this device (#51).
  static const knownKey = 'server.known';

  final PlatformApi _platformApi;
  final KeyValueStore _store;
  final Logger _log = Logger('ServerRepository');

  ServerAddress? _current;
  List<ServerAddress> _known = const [];

  @override
  List<ServerAddress> get known => _known;

  @override
  ServerAddress? get current => _current;

  @override
  Future<Result<void>> restore() async {
    try {
      _known = _decodeKnown(await _store.read(knownKey));
      final saved = await _store.read(storageKey);
      if (saved == null) return const Result.ok(null);
      switch (ServerAddress.parse(saved)) {
        case Ok(:final value):
          _setCurrent(value);
          await _remember(value);
        case Error():
          _log.warning('Ignoring a stored server address that is invalid.');
          await _store.delete(storageKey);
      }
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.severe('Could not read the stored server address.', e);
      return Result.error(e);
    }
  }

  @override
  Future<Result<ServerStatus>> connect(ServerAddress server) async {
    final result = await _platformApi.authStatus(server);
    switch (result) {
      case Ok(:final value):
        try {
          await _store.write(storageKey, server.toString());
        } on Exception catch (e) {
          _log.severe('Could not store the server address.', e);
          return Result.error(e);
        }
        _setCurrent(server);
        await _remember(server);
        return Result.ok(ServerStatus(setupRequired: value.setupRequired));
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  Future<Result<ServerStatus>> status() async {
    final server = _current;
    if (server == null) {
      return const Result.error(NotConnectedException());
    }
    final result = await _platformApi.authStatus(server);
    return switch (result) {
      Ok(:final value) => Result.ok(
        ServerStatus(
          setupRequired: value.setupRequired,
          username: value.username,
          role: value.role,
          demo: value.demo,
          demoPassword: value.demoPassword,
        ),
      ),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<String>> version() async {
    final server = _current;
    if (server == null) return const Result.error(NotConnectedException());
    return _platformApi.version(server);
  }

  @override
  Future<Result<void>> switchTo(ServerAddress server) async {
    try {
      await _store.write(storageKey, server.toString());
    } on Exception catch (e) {
      return Result.error(e);
    }
    _setCurrent(server);
    await _remember(server);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> leave() async {
    try {
      await _store.delete(storageKey);
    } on Exception catch (e) {
      return Result.error(e);
    }
    _setCurrent(null);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> forget(ServerAddress server) async {
    _known = [
      for (final s in _known)
        if (s != server) s,
    ];
    await _saveKnown();
    if (server == _current) return leave();
    notifyListeners();
    return const Result.ok(null);
  }

  Future<void> _remember(ServerAddress server) async {
    if (_known.contains(server)) return;
    _known = [..._known, server];
    await _saveKnown();
  }

  Future<void> _saveKnown() async {
    try {
      await _store.write(
        knownKey,
        jsonEncode([for (final s in _known) s.toString()]),
      );
    } on Exception catch (e) {
      _log.warning('Could not store the list of servers.', e);
    }
  }

  static List<ServerAddress> _decodeKnown(String? raw) {
    if (raw == null) return const [];
    try {
      return [
        for (final a in (jsonDecode(raw) as List<Object?>).whereType<String>())
          if (ServerAddress.parse(a) case Ok(:final value)) value,
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<Result<void>> disconnect() async {
    final server = _current;
    if (server != null) {
      _known = [
        for (final s in _known)
          if (s != server) s,
      ];
      await _saveKnown();
    }
    try {
      await _store.delete(storageKey);
    } on Exception catch (e) {
      _log.severe('Could not delete the server address.', e);
      return Result.error(e);
    }
    _setCurrent(null);
    return const Result.ok(null);
  }

  void _setCurrent(ServerAddress? server) {
    if (server == _current) return;
    _current = server;
    notifyListeners();
  }
}
