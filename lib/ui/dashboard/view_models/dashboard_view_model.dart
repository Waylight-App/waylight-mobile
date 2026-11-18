import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state and actions of the dashboard (#16).
class DashboardViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading the dashboard.
  DashboardViewModel({
    required this._serverRepository,
    required this._sessionRepository,
    required this._dashboardRepository,
  }) {
    load = Command0(_load)..execute().ignore();
    signOut = Command0(_sessionRepository.signOut);
    disconnect = Command0(_disconnect);
  }

  final ServerRepository _serverRepository;
  final SessionRepository _sessionRepository;
  final DashboardRepository _dashboardRepository;

  /// Loads the tabs and widgets; run again to reload.
  late final Command0<Dashboard> load;

  /// Signs out; the router then shows the sign-in screen.
  late final Command0<void> signOut;

  /// Signs out and forgets the server; the router then shows the connect
  /// screen.
  late final Command0<void> disconnect;

  Future<Result<Dashboard>> _load() {
    final server = _serverRepository.current;
    if (server == null) {
      return Future.value(const Result.error(NotConnectedException()));
    }
    return _dashboardRepository.dashboard(server);
  }

  // A session must never outlive its server in the app (#13).
  Future<Result<void>> _disconnect() async {
    await _sessionRepository.signOut();
    return _serverRepository.disconnect();
  }

  @override
  void dispose() {
    load.dispose();
    signOut.dispose();
    disconnect.dispose();
    super.dispose();
  }
}
