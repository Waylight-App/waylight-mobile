import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/kiosk/kiosk_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The wall display (#193): the kiosk's tabs, rotated and dimmed at night
/// as the server's options say.
class KioskViewModel extends ChangeNotifier {
  /// Creates the view model and loads the tabs.
  KioskViewModel({
    required this._servers,
    required this._dashboard,
    required this._kiosk,
    this._compact,
    DateTime Function()? now,
    this.reload = const Duration(minutes: 10),
  }) : _now = now ?? DateTime.now {
    _kiosk.showDisplay().ignore();
    load = Command0(_load)..execute().ignore();
    _kiosk.addListener(_onOptions);
    _onOptions();
    // Tabs and options may change on the server; the wall display follows.
    _reloadTimer = Timer.periodic(reload, (_) {
      load.execute().ignore();
      _kiosk.refreshOptions().ignore();
    });
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _tickNight());
  }

  final ServerRepository _servers;
  final DashboardRepository _dashboard;
  final KioskRepository _kiosk;
  final CompactStateRepository? _compact;
  final DateTime Function() _now;

  /// How often tabs and options are read again.
  final Duration reload;

  Timer? _rotate;
  Timer? _reloadTimer;
  Timer? _clock;
  int _index = 0;
  bool _night = false;

  /// Loads the kiosk's tabs.
  late final Command0<Dashboard> load;

  /// The tab shown now.
  int get index => _index;

  /// Whether the screen is dimmed.
  bool get night => _night;

  /// The tabs, empty while loading.
  List<DashboardTab> get tabs => switch (load.result) {
    Ok(:final value) => value.tabs,
    _ => const [],
  };

  /// Shows the next tab; wraps around.
  void next() {
    final count = tabs.length;
    if (count < 2) return;
    _index = (_index + 1) % count;
    notifyListeners();
  }

  /// Leaves the wall display after the device credential.
  Future<bool> leave(String reason) => _kiosk.leave(reason);

  Future<Result<Dashboard>> _load() async {
    final server = _servers.current;
    if (server == null) return const Result.error(NotConnectedException());
    // The module list decides which small tiles show a compact state.
    final (result, _) = await (
      _dashboard.dashboard(server),
      _compact?.load(server) ?? Future<void>.value(),
    ).wait;
    if (_index >= tabs.length) _index = 0;
    notifyListeners();
    return result;
  }

  void _onOptions() {
    _rotate?.cancel();
    final seconds = _kiosk.options.rotateSeconds;
    if (seconds > 0) {
      _rotate = Timer.periodic(Duration(seconds: seconds), (_) => next());
    }
    _tickNight();
  }

  void _tickNight() {
    final night = _kiosk.options.nightAt(_now());
    if (night == _night) return;
    _night = night;
    notifyListeners();
  }

  @override
  void dispose() {
    _kiosk.hideDisplay().ignore();
    _kiosk.removeListener(_onOptions);
    _rotate?.cancel();
    _reloadTimer?.cancel();
    _clock?.cancel();
    load.dispose();
    super.dispose();
  }
}
