import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/device/wall_display.dart';
import 'package:waylight_mobile/data/services/platform/device_auth.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/kiosk.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The app as a wall display (#193): signed in with a kiosk link, it shows
/// the kiosk's tabs read-only until someone with the device credential
/// leaves the mode. The mode survives restarts.
class KioskRepository extends ChangeNotifier {
  /// Creates the repository.
  KioskRepository({
    required this._servers,
    required this._sessions,
    required this._api,
    required this._store,
    required this._auth,
    this._display,
  }) {
    _sessions.addListener(_onSession);
  }

  final ServerRepository _servers;
  final SessionRepository _sessions;
  final ModuleApi _api;
  final KeyValueStore _store;
  final DeviceAuth _auth;
  final WallDisplay? _display;
  final Logger _log = Logger('KioskRepository');

  static const _activeKey = 'kiosk.active';

  bool _active = false;
  KioskOptions _options = const KioskOptions();

  /// Whether the app is a wall display.
  bool get active => _active;

  /// The display options from the server.
  KioskOptions get options => _options;

  /// Reads the stored mode; call once at start, after the session.
  Future<void> restore() async {
    _active = await _store.read(_activeKey) == '1' && _sessions.signedIn;
    notifyListeners();
  }

  /// Turns the app into a wall display with a kiosk [link].
  Future<Result<void>> enter(String link) async {
    final KioskLink parsed;
    switch (parseKioskLink(link)) {
      case Ok(:final value):
        parsed = value;
      case Error(:final error):
        return Result.error(error);
    }
    final connected = await _servers.connect(parsed.server);
    if (connected case Error(:final error)) return Result.error(error);
    final signedIn = await _sessions.signInKiosk(parsed.server, parsed.token);
    if (signedIn case Error(:final error)) return Result.error(error);
    await _store.write(_activeKey, '1');
    _active = true;
    notifyListeners();
    await refreshOptions();
    return const Result.ok(null);
  }

  /// Reads rotation and night dimming again; failures keep the last ones.
  Future<void> refreshOptions() async {
    final server = _servers.current;
    if (!_active || server == null) return;
    final result = await _api.read(server, '/api/auth/kiosk', (json) {
      if (json is! Map<String, Object?>) return null;
      return KioskOptions(
        rotateSeconds: switch (json['rotateSeconds']) {
          final int s => s,
          _ => 0,
        },
        nightFrom: switch (json['nightFrom']) {
          final String s => s,
          _ => '',
        },
        nightTo: switch (json['nightTo']) {
          final String s => s,
          _ => '',
        },
      );
    });
    if (result case Ok(:final value) when value != _options) {
      _options = value;
      notifyListeners();
    }
  }

  /// Turns the screen into a wall display: no system bars, kept on.
  Future<void> showDisplay() async => _display?.enter();

  /// Gives the screen back to the system.
  Future<void> hideDisplay() async => _display?.exit();

  /// Leaves the wall display after the device credential: signs out and
  /// forgets the server, so the connect screen shows. `false` when the
  /// credential was not given.
  Future<bool> leave(String reason) async {
    if (await _auth.available() && !await _auth.confirm(reason)) return false;
    await _end();
    await _sessions.signOut();
    await _servers.disconnect();
    return true;
  }

  // A disabled or renewed link ends the session on the server: the tablet
  // then shows the connect screen, not a password sign-in.
  void _onSession() {
    if (!_active || _sessions.signedIn) return;
    _log.info('The kiosk session ended.');
    _end().then((_) => _servers.disconnect()).ignore();
  }

  Future<void> _end() async {
    _active = false;
    _options = const KioskOptions();
    await _store.delete(_activeKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _sessions.removeListener(_onSession);
    super.dispose();
  }
}
