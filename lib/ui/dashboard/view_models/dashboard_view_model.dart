import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state and actions of the dashboard (#16).
class DashboardViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading the dashboard.
  DashboardViewModel({
    required this._serverRepository,
    required this._dashboardRepository,
    OfflineRepository? offlineRepository,
  }) : _offline = offlineRepository {
    _offline?.addListener(notifyListeners);
    load = Command0(_load)..execute().ignore();
    _loadDemo().ignore();
  }

  final ServerRepository _serverRepository;
  final DashboardRepository _dashboardRepository;
  final OfflineRepository? _offline;

  /// When the server cannot be reached: the time of the stored data shown.
  DateTime? get offlineSince => _offline?.showingDataFrom;

  bool _demo = false;

  /// Whether the server is the public demo, whose data is reset.
  bool get demo => _demo;

  Future<void> _loadDemo() async {
    if (await _serverRepository.status() case Ok(:final value)
        when value.demo) {
      _demo = true;
      notifyListeners();
    }
  }

  /// Loads the tabs and widgets; run again to reload.
  late final Command0<Dashboard> load;

  /// The address of [tabId] in the web interface, for widgets without a
  /// native view; `null` without a server.
  Uri? webUrl(String tabId) => _serverRepository.current
      ?.resolve('/')
      .replace(queryParameters: {'tab': tabId});

  Future<Result<Dashboard>> _load() {
    final server = _serverRepository.current;
    if (server == null) {
      return Future.value(const Result.error(NotConnectedException()));
    }
    return _dashboardRepository.dashboard(server);
  }

  @override
  void dispose() {
    _offline?.removeListener(notifyListeners);
    load.dispose();
    super.dispose();
  }
}
