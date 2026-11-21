import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:waylight_mobile/data/repositories/absences/absences_repository.dart';
import 'package:waylight_mobile/data/repositories/account/account_security_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/drop_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/focus_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/parcels_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/summary_repository.dart';
import 'package:waylight_mobile/data/repositories/announcements/announcements_repository.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/repositories/attention/attention_repository.dart';
import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository.dart';
import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/calendar/calendar_repository.dart';
import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/diagnostics/diagnostics_repository.dart';
import 'package:waylight_mobile/data/repositories/focus/focus_timer_repository.dart';
import 'package:waylight_mobile/data/repositories/habits/habits_repository.dart';
import 'package:waylight_mobile/data/repositories/habits/habits_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/data/repositories/kiosk/kiosk_repository.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/nfc/nfc_repository.dart';
import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/repositories/notes/notes_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository_local.dart';
import 'package:waylight_mobile/data/repositories/presence/presence_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/quick_tiles/quick_tiles_repository.dart';
import 'package:waylight_mobile/data/repositories/reminders/reminder_repository.dart';
import 'package:waylight_mobile/data/repositories/scanner/scanner_repository.dart';
import 'package:waylight_mobile/data/repositories/search/search_repository.dart';
import 'package:waylight_mobile/data/repositories/search/search_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/server/address_selector.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_outbox.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/watch/watch_pairing_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/address_routes.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/data/services/api/bookmarks_api.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/api/notes_api.dart';
import 'package:waylight_mobile/data/services/api/notifications_api.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/data/services/api/search_api.dart';
import 'package:waylight_mobile/data/services/api/todos_api.dart';
import 'package:waylight_mobile/data/services/api/transit_api.dart';
import 'package:waylight_mobile/data/services/api/waste_api.dart';
import 'package:waylight_mobile/data/services/api/weather_api.dart';
import 'package:waylight_mobile/data/services/cache/response_cache.dart';
import 'package:waylight_mobile/data/services/device/device_info.dart';
import 'package:waylight_mobile/data/services/device/wall_display.dart';
import 'package:waylight_mobile/data/services/focus/focus_timer_service.dart';
import 'package:waylight_mobile/data/services/home_widgets/home_widget_store.dart';
import 'package:waylight_mobile/data/services/logging/log_store.dart';
import 'package:waylight_mobile/data/services/network/network_changes.dart';
import 'package:waylight_mobile/data/services/nfc/nfc_writer.dart';
import 'package:waylight_mobile/data/services/platform/device_auth.dart';
import 'package:waylight_mobile/data/services/platform/device_name.dart';
import 'package:waylight_mobile/data/services/push/push_device.dart';
import 'package:waylight_mobile/data/services/quick_tiles/quick_tile_store.dart';
import 'package:waylight_mobile/data/services/reminders/reminder_scheduler.dart';
import 'package:waylight_mobile/data/services/scanner/barcode_scanner.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/data/services/system_colors/system_colors.dart';
import 'package:waylight_mobile/data/services/watch/watch_handover.dart';

/// The repositories of the app. Server and session are needed by the
/// router before the app starts.
typedef Repositories = ({
  ServerRepository server,
  SessionRepository session,
  DashboardRepository dashboard,
  WeatherRepository weather,
  TodosRepositoryOutbox todos,
  NotesRepository notes,
  BookmarksRepository bookmarks,
  TransitRepository transit,
  WasteRepository waste,
  WidgetDataRepository widgetData,
  ShoppingRepository shopping,
  HabitsRepository habits,
  RssRepository rss,
  ParcelsRepository parcels,
  SmartHomeRepository smartHome,
  FocusRepository focus,
  PresenceRepository presence,
  AttentionRepository attention,
  CompactStateRepository compact,
  AbsencesRepository absences,
  AnnouncementsRepository announcements,
  ScannerRepository scanner,
  WatchPairingRepository watch,
  FocusTimerRepository focusTimer,
  HomeServerActionsRepository homeServer,
  CalendarRepository calendar,
  ReadLaterRepository readLater,
  DropRepository drop,
  AccountSecurityRepository security,
  PushRepository push,
  ThemeRepository theme,
  SummaryRepository summary,
  HomeWidgetsRepository homeWidgets,
  QuickTilesRepository quickTiles,
  NfcRepository nfc,
  ReminderRepository reminders,
  LogStore logs,
  DiagnosticsRepository diagnostics,
  PreferencesRepository preferences,
  OfflineRepository offline,
  SearchRepository search,
  AppLockRepository lock,
  KioskRepository kiosk,
});

/// The services and repositories of the app: the composition root.
///
/// Only this file knows the concrete classes. Everything else depends on
/// the abstract repositories, so tests can provide fakes instead.
List<SingleChildWidget> providers(Repositories repositories) => [
  ChangeNotifierProvider<ServerRepository>.value(value: repositories.server),
  ChangeNotifierProvider<SessionRepository>.value(value: repositories.session),
  Provider<DashboardRepository>.value(value: repositories.dashboard),
  Provider<WeatherRepository>.value(value: repositories.weather),
  Provider<TodosRepository>.value(value: repositories.todos),
  ChangeNotifierProvider<TodoOutbox>.value(value: repositories.todos.outbox),
  Provider<NotesRepository>.value(value: repositories.notes),
  Provider<BookmarksRepository>.value(value: repositories.bookmarks),
  Provider<TransitRepository>.value(value: repositories.transit),
  Provider<WasteRepository>.value(value: repositories.waste),
  Provider<WidgetDataRepository>.value(value: repositories.widgetData),
  Provider<ShoppingRepository>.value(value: repositories.shopping),
  Provider<HabitsRepository>.value(value: repositories.habits),
  Provider<RssRepository>.value(value: repositories.rss),
  Provider<ParcelsRepository>.value(value: repositories.parcels),
  Provider<SmartHomeRepository>.value(value: repositories.smartHome),
  Provider<FocusRepository>.value(value: repositories.focus),
  Provider<PresenceRepository>.value(value: repositories.presence),
  ListenableProvider<AttentionRepository>.value(value: repositories.attention),
  Provider<CompactStateRepository>.value(value: repositories.compact),
  Provider<AbsencesRepository>.value(value: repositories.absences),
  Provider<ScannerRepository>.value(value: repositories.scanner),
  Provider<WatchPairingRepository>.value(value: repositories.watch),
  Provider<AnnouncementsRepository>.value(value: repositories.announcements),
  ChangeNotifierProvider<FocusTimerRepository>.value(
    value: repositories.focusTimer,
  ),
  Provider<HomeServerActionsRepository>.value(value: repositories.homeServer),
  Provider<CalendarRepository>.value(value: repositories.calendar),
  Provider<ReadLaterRepository>.value(value: repositories.readLater),
  Provider<DropRepository>.value(value: repositories.drop),
  Provider<AccountSecurityRepository>.value(value: repositories.security),
  Provider<PushRepository>.value(value: repositories.push),
  ChangeNotifierProvider<ThemeRepository>.value(value: repositories.theme),
  Provider<SummaryRepository>.value(value: repositories.summary),
  Provider<HomeWidgetsRepository>.value(value: repositories.homeWidgets),
  Provider<QuickTilesRepository>.value(value: repositories.quickTiles),
  Provider<NfcRepository>.value(value: repositories.nfc),
  ChangeNotifierProvider<ReminderRepository>.value(
    value: repositories.reminders,
  ),
  Provider<DiagnosticsRepository>.value(value: repositories.diagnostics),
  Provider<SearchRepository>.value(value: repositories.search),
  ChangeNotifierProvider<AppLockRepository>.value(value: repositories.lock),
  ChangeNotifierProvider<KioskRepository>.value(value: repositories.kiosk),
  ChangeNotifierProvider<PreferencesRepository>.value(
    value: repositories.preferences,
  ),
  ChangeNotifierProvider<OfflineRepository>.value(value: repositories.offline),
];

/// Creates the repositories with their real services. They share one API
/// client, so every request carries the current session.
Repositories createRepositories() {
  final credentials = ApiCredentials();
  final offline = OfflineStatus();
  final cache = FileResponseCache(
    () async =>
        Directory('${(await getApplicationSupportDirectory()).path}/offline'),
  );
  final routes = AddressRoutes();
  final client = ApiClient(
    client: http.Client(),
    credentials: credentials,
    routes: routes,
    cache: cache,
    offline: offline,
  );
  const store = SecureKeyValueStore();
  final modules = ModuleApi(client);
  final theme = ThemeRepository(
    api: modules,
    store: store,
    systemColors: const MethodChannelSystemColors(),
  );
  final platform = PlatformApi(client);
  final server = ServerRepositoryRemote(
    platformApi: platform,
    store: store,
    selector: AddressSelector(api: platform),
    routes: routes,
    signedIn: (s) => credentials.session?.server == s,
    networkChanges: networkChanges(),
  );
  final todos = TodosRepositoryOutbox(
    remote: TodosRepositoryRemote(api: TodosApi(client)),
    store: store,
    offline: offline,
    server: () => server.current,
  );
  final dashboard = DashboardRepositoryRemote(
    api: DashboardApi(client),
    store: store,
  );
  final transit = TransitRepositoryRemote(api: TransitApi(client));
  final homeWidgets = HomeWidgetsRepository(
    dashboard: dashboard,
    todos: todos,
    transit: transit,
    store: MethodChannelHomeWidgetStore(),
  );
  final widgetData = WidgetDataRepositoryRemote(api: modules);
  final smartHome = SmartHomeRepositoryRemote(api: modules);
  final presence = PresenceRepositoryRemote(api: modules);
  final attention = AttentionRepositoryRemote(api: modules);
  final quickTiles = QuickTilesRepository(
    smartHome: smartHome,
    presence: presence,
    store: MethodChannelQuickTileStore(),
  );
  final focusSessions = FocusRepositoryRemote(api: modules);
  final reminders = ReminderRepository(
    scheduler: const MethodChannelReminderScheduler(),
    store: store,
    todos: todos,
    data: widgetData,
  );
  final logs = FileLogStore(
    () async => File(
      '${(await getApplicationSupportDirectory()).path}/diagnostics.log',
    ),
  );
  final session = SessionRepositoryRemote(
    authApi: AuthApi(client),
    credentials: credentials,
    store: store,
    deviceName: deviceName(),
    cache: cache,
    onForget: [
      attention.clear,
      reminders.clear,
      todos.clear,
      theme.clear,
      homeWidgets.clear,
      quickTiles.clear,
      dashboard.clear,
      logs.clear,
    ],
  );
  final lock = AppLockRepository(auth: LocalDeviceAuth(), store: store);
  final kiosk = KioskRepository(
    servers: server,
    sessions: session,
    api: modules,
    store: store,
    auth: LocalDeviceAuth(),
    display: const PlatformWallDisplay(),
  );
  return (
    server: server,
    session: session,
    dashboard: dashboard,
    weather: WeatherRepositoryRemote(api: WeatherApi(client)),
    todos: todos,
    notes: NotesRepositoryRemote(api: NotesApi(client)),
    bookmarks: BookmarksRepositoryRemote(api: BookmarksApi(client)),
    transit: transit,
    waste: WasteRepositoryRemote(api: WasteApi(client)),
    widgetData: widgetData,
    shopping: ShoppingRepositoryRemote(api: modules),
    habits: HabitsRepositoryRemote(api: modules),
    rss: RssRepositoryRemote(api: modules),
    parcels: ParcelsRepositoryRemote(api: modules),
    smartHome: smartHome,
    focus: focusSessions,
    presence: presence,
    attention: attention,
    compact: CompactStateRepositoryRemote(api: modules),
    absences: AbsencesRepositoryRemote(api: modules),
    announcements: AnnouncementsRepositoryRemote(api: modules),
    scanner: const ScannerRepository(scanner: MethodChannelBarcodeScanner()),
    watch: WatchPairingRepository(
      api: modules,
      scanner: const MethodChannelBarcodeScanner(),
      sealer: const MethodChannelHandoverSealer(),
      watch: WatchClient(http.Client()),
    ),
    focusTimer: FocusTimerRepository(
      timer: MethodChannelFocusTimer(),
      sessions: focusSessions,
      store: store,
      askPermission: const MethodChannelReminderScheduler().requestPermission,
    ),
    homeServer: HomeServerActionsRepositoryRemote(api: modules),
    calendar: CalendarRepositoryRemote(api: modules),
    readLater: ReadLaterRepositoryRemote(api: modules),
    drop: DropRepositoryRemote(api: modules),
    security: AccountSecurityRepositoryRemote(api: modules),
    push: PushRepositoryRemote(
      api: NotificationsApi(client),
      device: const MethodChannelPushDevice(),
      deviceName: deviceName(),
      store: store,
    ),
    theme: theme,
    summary: SummaryRepositoryRemote(api: modules),
    homeWidgets: homeWidgets,
    quickTiles: quickTiles,
    nfc: NfcRepository(writer: MethodChannelNfcWriter()),
    reminders: reminders,
    logs: logs,
    diagnostics: DiagnosticsRepository(
      logs: logs,
      device: const MethodChannelDeviceInfo(),
      server: server,
      data: widgetData,
    ),
    preferences: PreferencesRepositoryLocal(store: store),
    offline: OfflineRepository(offline),
    search: SearchRepositoryRemote(api: SearchApi(client)),
    lock: lock,
    kiosk: kiosk,
  );
}
