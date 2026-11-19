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

  final PlatformApi _platformApi;
  final KeyValueStore _store;
  final Logger _log = Logger('ServerRepository');

  ServerAddress? _current;

  @override
  ServerAddress? get current => _current;

  @override
  Future<Result<void>> restore() async {
    try {
      final saved = await _store.read(storageKey);
      if (saved == null) return const Result.ok(null);
      switch (ServerAddress.parse(saved)) {
        case Ok(:final value):
          _setCurrent(value);
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
  Future<Result<void>> disconnect() async {
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
