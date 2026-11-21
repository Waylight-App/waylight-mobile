import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/presence/presence_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the presence widget (#200): today's board and the
/// account's own status, set with one tap.
class PresenceViewModel extends ChangeNotifier {
  /// Creates the view model for [group] and starts loading.
  PresenceViewModel({
    required this._serverRepository,
    required this._presenceRepository,
    this.group = '',
  }) {
    load = Command0(_load)..execute().ignore();
  }

  final ServerRepository _serverRepository;
  final PresenceRepository _presenceRepository;

  /// The group of the widget's settings; empty means everyone.
  final String group;

  PresenceBoard? _board;
  bool _off = false;
  bool _busy = false;
  Exception? _lastError;

  /// Loads the board; run again to reload.
  late final Command0<void> load;

  /// Today's board, once loaded.
  PresenceBoard? get board => _board;

  /// Whether presence is switched off on the server (HTTP 404).
  bool get off => _off;

  /// Whether the account may set its status; guests and kiosk displays
  /// get no own entry from the server.
  bool get canSet => _board?.mine != null && !_busy;

  /// The account's own status.
  PresenceStatus get mine => _board?.mine?.status ?? PresenceStatus.none;

  /// The last refused change, once.
  Exception? takeLastError() {
    final e = _lastError;
    _lastError = null;
    return e;
  }

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    switch (await _presenceRepository.board(server, group: group)) {
      case Ok(:final value):
        _board = value;
        _off = false;
        notifyListeners();
        return const Result.ok(null);
      case Error(error: ApiException(failure: ApiFailure.notFound)):
        _board = null;
        _off = true;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Sets [status]; choosing the active one again clears it, as on the
  /// server's widget. [returnOn] is the day of return when away.
  Future<void> choose(PresenceStatus status, {DateTime? returnOn}) async {
    final server = _serverRepository.current;
    if (server == null || !canSet) return;
    final next = status == mine ? PresenceStatus.none : status;
    _busy = true;
    notifyListeners();
    final result = await _presenceRepository.setMine(
      server,
      next,
      returnOn: returnOn,
    );
    _busy = false;
    if (result case Error(:final error)) {
      _lastError = error;
      notifyListeners();
      return;
    }
    // The server decides the final state (an absence may win).
    await load.execute();
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
