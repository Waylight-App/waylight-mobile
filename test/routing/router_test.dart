import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/config/dependencies.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/repositories/device_controls/device_controls_repository.dart';
import 'package:waylight_mobile/data/repositories/diagnostics/diagnostics_repository.dart';
import 'package:waylight_mobile/data/repositories/first_start/first_start_repository.dart';
import 'package:waylight_mobile/data/repositories/focus/focus_timer_repository.dart';
import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/data/repositories/kiosk/kiosk_repository.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/nfc/nfc_repository.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/repositories/quick_tiles/quick_tiles_repository.dart';
import 'package:waylight_mobile/data/repositories/reminders/reminder_repository.dart';
import 'package:waylight_mobile/data/repositories/scanner/scanner_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_outbox.dart';
import 'package:waylight_mobile/data/repositories/watch/watch_pairing_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/data/services/focus/focus_timer_service.dart';
import 'package:waylight_mobile/data/services/watch/watch_handover.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/first_start/widgets/first_start_screen.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_index.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_area_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_screen.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';

import '../testing/fakes/fake_absences_repository.dart';
import '../testing/fakes/fake_action_repositories.dart';
import '../testing/fakes/fake_announcements_repository.dart';
import '../testing/fakes/fake_attention_repository.dart';
import '../testing/fakes/fake_barcode_scanner.dart';
import '../testing/fakes/fake_bookmarks_repository.dart';
import '../testing/fakes/fake_compact_state_repository.dart';
import '../testing/fakes/fake_dashboard_repository.dart';
import '../testing/fakes/fake_device_auth.dart';
import '../testing/fakes/fake_device_controls_store.dart';
import '../testing/fakes/fake_device_info.dart';
import '../testing/fakes/fake_habits_repository.dart';
import '../testing/fakes/fake_handover_sealer.dart';
import '../testing/fakes/fake_help_repository.dart';
import '../testing/fakes/fake_home_widget_store.dart';
import '../testing/fakes/fake_log_store.dart';
import '../testing/fakes/fake_nfc_writer.dart';
import '../testing/fakes/fake_notes_repository.dart';
import '../testing/fakes/fake_preferences_repository.dart';
import '../testing/fakes/fake_presence_repository.dart';
import '../testing/fakes/fake_quick_tile_store.dart';
import '../testing/fakes/fake_reminder_scheduler.dart';
import '../testing/fakes/fake_search_repository.dart';
import '../testing/fakes/fake_server_repository.dart';
import '../testing/fakes/fake_session_repository.dart';
import '../testing/fakes/fake_shopping_repository.dart';
import '../testing/fakes/fake_todos_repository.dart';
import '../testing/fakes/fake_transit_repository.dart';
import '../testing/fakes/fake_waste_repository.dart';
import '../testing/fakes/fake_weather_repository.dart';
import '../testing/fakes/fake_widget_data_repository.dart';
import '../testing/fakes/in_memory_key_value_store.dart';

void main() {
  Future<GoRouter> pumpApp(
    WidgetTester tester,
    FakeServerRepository servers,
    FakeSessionRepository sessions, {
    FirstStartRepository? firstStart,
  }) async {
    final router = createRouter(servers, sessions, firstStart: firstStart);
    await tester.pumpWidget(
      MultiProvider(
        providers: providers((
          server: servers,
          session: sessions,
          dashboard: FakeDashboardRepository(),
          weather: FakeWeatherRepository(),
          todos: TodosRepositoryOutbox(
            remote: FakeTodosRepository(),
            store: InMemoryKeyValueStore(),
            offline: OfflineStatus(),
            server: () => null,
          ),
          notes: FakeNotesRepository(),
          bookmarks: FakeBookmarksRepository(),
          transit: FakeTransitRepository(),
          waste: FakeWasteRepository(),
          widgetData: FakeWidgetDataRepository(),
          shopping: FakeShoppingRepository(),
          habits: FakeHabitsRepository(),
          rss: FakeRssRepository(),
          parcels: FakeParcelsRepository(),
          smartHome: FakeSmartHomeRepository(),
          focus: FakeFocusRepository(),
          presence: FakePresenceRepository(),
          attention: FakeAttentionRepository(),
          compact: FakeCompactStateRepository(),
          quickTiles: QuickTilesRepository(
            smartHome: FakeSmartHomeRepository(),
            presence: FakePresenceRepository(),
            store: FakeQuickTileStore(),
          ),
          deviceControls: DeviceControlsRepository(
            smartHome: FakeSmartHomeRepository(),
            store: FakeDeviceControlsStore(),
          ),
          nfc: NfcRepository(writer: FakeNfcWriter()),
          absences: FakeAbsencesRepository(),
          announcements: FakeAnnouncementsRepository(),
          scanner: ScannerRepository(scanner: FakeBarcodeScanner()),
          watch: WatchPairingRepository(
            api: ModuleApi(
              ApiClient(
                client: MockClient((_) async => http.Response('{}', 200)),
              ),
            ),
            scanner: FakeBarcodeScanner(),
            sealer: FakeHandoverSealer(),
            watch: WatchClient(MockClient((_) async => http.Response('', 204))),
          ),
          focusTimer: FocusTimerRepository(
            timer: InAppFocusTimer(),
            sessions: FakeFocusRepository(),
            store: InMemoryKeyValueStore(),
          ),
          homeServer: FakeHomeServerActions(),
          calendar: FakeCalendarRepository(),
          readLater: FakeReadLaterRepository(),
          drop: FakeDropRepository(),
          security: FakeAccountSecurity(),
          push: FakePushRepository(),
          theme: ThemeRepository(
            api: ModuleApi(
              ApiClient(
                client: MockClient((_) async => http.Response('{}', 200)),
              ),
            ),
            store: InMemoryKeyValueStore(),
          ),
          summary: FakeSummaryRepository(),
          homeWidgets: HomeWidgetsRepository(
            dashboard: FakeDashboardRepository(),
            todos: FakeTodosRepository(),
            transit: FakeTransitRepository(),
            store: FakeHomeWidgetStore(),
          ),
          preferences: FakePreferencesRepository(),
          offline: OfflineRepository(OfflineStatus()),
          search: FakeSearchRepository(),
          help: FakeHelpRepository(),
          lock: AppLockRepository(
            auth: FakeDeviceAuth(),
            store: InMemoryKeyValueStore(),
          ),
          kiosk: KioskRepository(
            servers: servers,
            sessions: sessions,
            api: ModuleApi(
              ApiClient(
                client: MockClient((_) async => http.Response('', 404)),
              ),
            ),
            store: InMemoryKeyValueStore(),
            auth: FakeDeviceAuth(),
          ),
          firstStart:
              firstStart ??
              FirstStartRepository(store: InMemoryKeyValueStore()),
          logs: FakeLogStore(),
          reminders: ReminderRepository(
            scheduler: FakeReminderScheduler(),
            store: InMemoryKeyValueStore(),
            todos: FakeTodosRepository(),
            data: FakeWidgetDataRepository(),
          ),
          diagnostics: DiagnosticsRepository(
            logs: FakeLogStore(),
            device: FakeDeviceInfo(),
            server: servers,
            data: FakeWidgetDataRepository(),
          ),
        )),
        child: WaylightApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('starts on the connect screen without a server', (tester) async {
    await pumpApp(tester, FakeServerRepository(), FakeSessionRepository());

    expect(find.byType(ConnectServerScreen), findsOneWidget);
  });

  testWidgets('asks to sign in on a connected server', (tester) async {
    await pumpApp(
      tester,
      FakeServerRepository(current: testServer()),
      FakeSessionRepository(),
    );

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('follows connecting, signing in and out', (tester) async {
    final servers = FakeServerRepository();
    final sessions = FakeSessionRepository();
    await pumpApp(tester, servers, sessions);

    await servers.connect(testServer());
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    await sessions.signIn(testServer(), password: 'pw');
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    await sessions.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    await servers.disconnect();
    await tester.pumpAndSettle();
    expect(find.byType(ConnectServerScreen), findsOneWidget);
  });

  testWidgets('asks the first-start questions once per server (#287)', (
    tester,
  ) async {
    final servers = FakeServerRepository(current: testServer());
    final sessions = FakeSessionRepository();
    final firstStart = FirstStartRepository(store: InMemoryKeyValueStore());
    await pumpApp(tester, servers, sessions, firstStart: firstStart);

    await sessions.signIn(testServer(), password: 'pw');
    await tester.pumpAndSettle();
    expect(find.byType(FirstStartScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('firstStart.skipAll')));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    await sessions.signOut();
    await tester.pumpAndSettle();
    await sessions.signIn(testServer(), password: 'pw');
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('opens a settings area and goes back to the start (#231)', (
    tester,
  ) async {
    final router = await pumpApp(
      tester,
      FakeServerRepository(current: testServer()),
      FakeSessionRepository(signedIn: true),
    );

    router.go(Routes.settingsServer);
    await tester.pumpAndSettle();
    final screen = tester.widget<SettingsAreaScreen>(
      find.byType(SettingsAreaScreen),
    );
    expect(screen.area, SettingsArea.server);
    expect(screen.focus, isNull);

    router.go('${Routes.settingsAbout}?focus=licences');
    await tester.pumpAndSettle();
    expect(
      tester.widget<SettingsAreaScreen>(find.byType(SettingsAreaScreen)).focus,
      SettingsItem.licences,
    );

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings.area.account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings.security')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.security);
  });

  String? at(
    String location, {
    bool connected = true,
    bool signedIn = true,
    bool firstStart = false,
  }) => redirectFor(
    uri: Uri.parse(location),
    connected: connected,
    signedIn: signedIn,
    firstStart: firstStart,
  );

  test('redirects by server and session', () {
    expect(at(Routes.home, connected: false, signedIn: false), Routes.connect);
    expect(at(Routes.connect, connected: false, signedIn: false), isNull);
    expect(at(Routes.home, signedIn: false), Routes.signIn);
    expect(at(Routes.connect, signedIn: false), Routes.signIn);
    expect(at(Routes.signIn, signedIn: false), isNull);
    expect(at(Routes.signIn), Routes.home);
    expect(at(Routes.connect), Routes.home);
    expect(at(Routes.home), isNull);
  });

  test('opens links from outside', () {
    expect(at('waylight://settings'), Routes.settings);
    expect(at('waylight://settings?tab=1'), '/settings?tab=1');
    for (final area in SettingsArea.values) {
      expect(at('waylight://settings/${area.segment}'), area.path);
    }
    expect(at('waylight://nowhere'), Routes.home);
    expect(
      at('waylight://auth?code=c&state=s', signedIn: false),
      '/auth?code=c&state=s',
    );
    expect(at('/nowhere'), Routes.home);
  });

  test('continues to the link after the sign-in', () {
    final gate = at('waylight://settings', signedIn: false)!;
    expect(gate, '/sign-in?from=%2Fsettings');

    expect(at(gate), Routes.settings);
    expect(at('/sign-in?from=%2F%2Fevil.example.org'), Routes.home);
    expect(
      at('waylight://settings', connected: false, signedIn: false),
      '/connect?from=%2Fsettings',
    );
  });

  test('puts the first-start questions before the dashboard (#287)', () {
    expect(at(Routes.home, firstStart: true), Routes.welcome);
    expect(at(Routes.signIn, firstStart: true), Routes.welcome);
    expect(at(Routes.welcome, firstStart: true), isNull);
    expect(at(Routes.welcome), Routes.home);
    // Links still open what they point to.
    expect(at(Routes.settings, firstStart: true), isNull);
    expect(at('/?tab=t1', firstStart: true), isNull);
    expect(at('/sign-in?from=%2Fsettings', firstStart: true), Routes.settings);
    expect(at(Routes.home, signedIn: false, firstStart: true), Routes.signIn);
  });
}
