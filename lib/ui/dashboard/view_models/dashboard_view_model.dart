import 'package:flutter/foundation.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
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
    this.initialTabId = '',
    this.initialWidgetKind = '',
    OfflineRepository? offlineRepository,
    PushRepository? pushRepository,
    ThemeRepository? themeRepository,
  }) : _offline = offlineRepository,
       _push = pushRepository,
       _theme = themeRepository {
    _offline?.addListener(notifyListeners);
    load = Command0(_load)..execute().ignore();
    _loadDemo().ignore();
  }

  final ServerRepository _serverRepository;
  final DashboardRepository _dashboardRepository;
  final OfflineRepository? _offline;
  final PushRepository? _push;
  final ThemeRepository? _theme;
  bool _pushRefreshed = false;

  /// When the server cannot be reached: the time of the stored data shown.
  DateTime? get offlineSince => _offline?.showingDataFrom;

  /// The tab to open instead of the server's default, e.g. from the search;
  /// empty for the default.
  final String initialTabId;

  /// A widget kind whose tab opens first, e.g. `transit` from a shortcut
  /// (#50); empty for none.
  final String initialWidgetKind;

  /// The tab to open first in [dashboard].
  int initialIndexIn(Dashboard dashboard) {
    if (initialWidgetKind.isNotEmpty) {
      final i = dashboard.tabs.indexWhere(
        (t) => t.widgets.any((w) => w.kind == initialWidgetKind),
      );
      if (i >= 0) return i;
    }
    return Dashboard(
      tabs: dashboard.tabs,
      defaultTabId: initialTabId.isEmpty
          ? dashboard.defaultTabId
          : initialTabId,
    ).initialIndex;
  }

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
    // Once per start: register the push token again in case the push
    // service replaced it while the app was closed (#59), and follow a
    // theme changed in the web interface (#157).
    if (!_pushRefreshed) {
      _pushRefreshed = true;
      _push?.refresh(server).ignore();
      _theme?.refresh(server).ignore();
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
