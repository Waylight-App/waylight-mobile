import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:waylight_mobile/data/repositories/server/address_selector.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/services/api/address_routes.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/address_check.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [ServerRepository] that checks servers over the network and keeps the
/// address in a [KeyValueStore].
class ServerRepositoryRemote extends ServerRepository {
  /// Creates the repository. With a selector and [routes] a server can
  /// have several addresses (#189); [signedIn] tells whether the device has
  /// a session on a server, and [networkChanges] triggers a new choice.
  ServerRepositoryRemote({
    required this._platformApi,
    required this._store,
    this._selector,
    AddressRoutes? routes,
    bool Function(ServerAddress server)? signedIn,
    Stream<void>? networkChanges,
  }) : _routes = routes ?? AddressRoutes(),
       _signedIn = signedIn ?? ((_) => false) {
    _network = networkChanges?.listen((_) => selectAddress().ignore());
  }

  /// The key under which the server address is stored.
  static const storageKey = 'server.address';

  /// The key of the list of servers used on this device (#51).
  static const knownKey = 'server.known';

  final PlatformApi _platformApi;
  final KeyValueStore _store;
  final AddressSelector? _selector;
  final AddressRoutes _routes;
  final bool Function(ServerAddress server) _signedIn;
  StreamSubscription<void>? _network;
  final Logger _log = Logger('ServerRepository');

  ServerAddress? _current;
  List<ServerAddress> _known = const [];
  List<ServerAddress> _addresses = const [];
  ServerAddress? _active;
  Map<ServerAddress, AddressCheck> _checks = const {};
  Future<void>? _selecting;

  static String _addressesKey(ServerAddress s) => 'server.addresses.$s';
  static String _activeKey(ServerAddress s) => 'server.active.$s';

  @override
  List<ServerAddress> get addresses =>
      _addresses.isEmpty ? [?_current] : _addresses;

  @override
  ServerAddress? get active => _current == null ? null : _active;

  @override
  Map<ServerAddress, AddressCheck> get checks => _checks;

  @override
  Future<Result<void>> setAddresses(List<ServerAddress> addresses) async {
    final server = _current;
    if (server == null) return const Result.error(NotConnectedException());
    if (addresses.isEmpty ||
        addresses.length > ServerRepository.maxAddresses ||
        addresses.toSet().length != addresses.length) {
      return const Result.error(InvalidAddressesException());
    }
    try {
      if (addresses.length == 1 && addresses.single == server) {
        await _store.delete(_addressesKey(server));
      } else {
        await _store.write(
          _addressesKey(server),
          jsonEncode([for (final a in addresses) a.toString()]),
        );
      }
    } on Exception catch (e) {
      return Result.error(e);
    }
    _addresses = addresses;
    notifyListeners();
    await selectAddress();
    return const Result.ok(null);
  }

  @override
  Future<void> selectAddress() =>
      _selecting ??= _select().whenComplete(() => _selecting = null);

  Future<void> _select() async {
    final server = _current;
    final selector = _selector;
    final candidates = addresses;
    if (server == null || selector == null || candidates.length < 2) {
      // Nothing to choose: requests go to the only address, which need not
      // be the one the server was connected with.
      final only = candidates.isEmpty ? server : candidates.first;
      final changed = _active != only || _checks.isNotEmpty;
      _useAddress(server, only);
      _checks = const {};
      if (changed) notifyListeners();
      return;
    }
    final result = await selector.select(
      server,
      candidates,
      signedIn: _signedIn(server),
    );
    // The server may have changed while the addresses were checked.
    if (server != _current) return;
    _checks = result.checks;
    final chosen = result.chosen;
    if (chosen != null) {
      _useAddress(server, chosen);
      try {
        await _store.write(_activeKey(server), chosen.toString());
      } on Exception catch (e) {
        _log.warning('Could not store the address in use.', e);
      }
    } else {
      // Nothing answers: keep the route, the offline copy is shown.
      _active = null;
    }
    notifyListeners();
  }

  void _useAddress(ServerAddress? server, ServerAddress? via) {
    _active = via;
    if (server != null) _routes.route(server, via);
  }

  /// Loads the addresses of [server] and the one used last, so requests go
  /// there before the first check finished (e.g. in background refresh).
  Future<void> _loadAddresses(ServerAddress? server) async {
    _addresses = const [];
    _checks = const {};
    _routes.clear();
    _active = server;
    if (server == null) return;
    _addresses = _decodeKnown(await _store.read(_addressesKey(server)));
    final last = await _store.read(_activeKey(server));
    if (last != null) {
      if (ServerAddress.parse(last) case Ok(:final value)
          when addresses.contains(value)) {
        _useAddress(server, value);
      }
    }
  }

  Future<void> _forgetAddresses(ServerAddress server) async {
    try {
      await _store.delete(_addressesKey(server));
      await _store.delete(_activeKey(server));
    } on Exception catch (e) {
      _log.warning('Could not delete the addresses of a server.', e);
    }
  }

  @override
  void dispose() {
    _network?.cancel().ignore();
    super.dispose();
  }

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
          await _loadAddresses(value);
          _setCurrent(value);
          await _remember(value);
          selectAddress().ignore();
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
        await _loadAddresses(server);
        _setCurrent(server);
        await _remember(server);
        selectAddress().ignore();
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
    await _loadAddresses(server);
    _setCurrent(server);
    await _remember(server);
    selectAddress().ignore();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> leave() async {
    try {
      await _store.delete(storageKey);
    } on Exception catch (e) {
      return Result.error(e);
    }
    await _loadAddresses(null);
    _setCurrent(null);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> forget(ServerAddress server) async {
    await _forgetAddresses(server);
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
      await _forgetAddresses(server);
    }
    try {
      await _store.delete(storageKey);
    } on Exception catch (e) {
      _log.severe('Could not delete the server address.', e);
      return Result.error(e);
    }
    await _loadAddresses(null);
    _setCurrent(null);
    return const Result.ok(null);
  }

  void _setCurrent(ServerAddress? server) {
    if (server == _current) return;
    _current = server;
    notifyListeners();
  }
}
