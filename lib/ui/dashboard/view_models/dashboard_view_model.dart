import 'package:flutter/foundation.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/repositories/quick_tiles/quick_tiles_repository.dart';
import 'package:waylight_mobile/data/repositories/reminders/reminder_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';
import 'package:waylight_mobile/domain/models/quick_tile.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/arrange_view_model.dart';
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
    HomeWidgetsRepository? homeWidgetsRepository,
    this._homeWidgetFormatter,
    ReminderRepository? reminderRepository,
    this._reminderFormatter,
    QuickTilesRepository? quickTilesRepository,
    this._quickTileFormatter,
  }) : _offline = offlineRepository,
       _quickTiles = quickTilesRepository,
       _push = pushRepository,
       _theme = themeRepository,
       _homeWidgets = homeWidgetsRepository,
       _reminders = reminderRepository {
    _offline?.addListener(notifyListeners);
    load = Command0(_load)..execute().ignore();
    _loadDemo().ignore();
  }

  final ServerRepository _serverRepository;
  final DashboardRepository _dashboardRepository;
  final OfflineRepository? _offline;
  final PushRepository? _push;
  final ThemeRepository? _theme;
  final HomeWidgetsRepository? _homeWidgets;
  final HomeWidgetFormatter? _homeWidgetFormatter;
  final ReminderRepository? _reminders;
  final ReminderFormatter? _reminderFormatter;
  final QuickTilesRepository? _quickTiles;
  final QuickTileFormatter? _quickTileFormatter;
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

  ArrangeViewModel? _arranging;

  /// The edit mode of the tab being arranged (#209), or `null`.
  ArrangeViewModel? get arranging => _arranging;

  /// Switches [tab] into the edit mode; team tabs cannot be arranged.
  void arrange(DashboardTab tab) {
    if (!tab.mine || _arranging != null) return;
    _arranging = ArrangeViewModel(
      tab: tab,
      serverRepository: _serverRepository,
      dashboardRepository: _dashboardRepository,
    );
    notifyListeners();
  }

  /// Leaves the edit mode; with [reload] after saving, so the dashboard
  /// shows the new layout.
  void stopArranging({bool reload = false}) {
    final arranging = _arranging;
    if (arranging == null) return;
    _arranging = null;
    arranging.dispose();
    notifyListeners();
    if (reload) load.execute().ignore();
  }

  /// The address of [tabId] in the web interface, for widgets without a
  /// native view; `null` without a server. It uses the server address that
  /// answers right now (#189).
  Uri? webUrl(String tabId) =>
      (_serverRepository.active ?? _serverRepository.current)
          ?.resolve('/')
          .replace(queryParameters: {'tab': tabId});

  Future<Result<Dashboard>> _load() async {
    final server = _serverRepository.current;
    if (server == null) {
      return const Result.error(NotConnectedException());
    }
    // Once per start: register the push token again in case the push
    // service replaced it while the app was closed (#59), and follow a
    // theme changed in the web interface (#157).
    if (!_pushRefreshed) {
      _pushRefreshed = true;
      _push?.refresh(server).ignore();
      _theme?.refresh(server).ignore();
      _homeWidgets?.schedule().ignore();
      // The Quick Settings tiles show whether the server has presence and
      // the current states (#192).
      if (_quickTileFormatter case final format?) {
        _quickTiles?.refresh(server, format: format).ignore();
      }
    }
    final result = await _dashboardRepository.dashboard(server);
    // The home screen widgets follow every load of the dashboard (#42).
    if ((result, _homeWidgets, _homeWidgetFormatter) case (
      Ok(:final value),
      final widgets?,
      final format?,
    )) {
      widgets.refresh(server, format: format, dashboard: value).ignore();
    }
    // Reminders on the device follow the loaded data (#190); the repository
    // limits how often it reloads.
    if ((result, _reminders, _reminderFormatter) case (
      Ok(),
      final reminders?,
      final format?,
    )) {
      reminders.reschedule(server, format).ignore();
    }
    return result;
  }

  @override
  void dispose() {
    _arranging?.dispose();
    _offline?.removeListener(notifyListeners);
    load.dispose();
    super.dispose();
  }
}
