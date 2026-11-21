import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/config/dependencies.dart';
import 'package:waylight_mobile/config/logging.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/shortcuts.dart';
import 'package:waylight_mobile/ui/home_widgets/background_refresh.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repositories = createRepositories();
  setupLogging(store: repositories.logs);
  // A failure only means the user has to enter the address or sign in
  // again. The session needs the restored server to check it belongs to it.
  await repositories.server.restore();
  await repositories.session.restore(repositories.server.current);
  await repositories.preferences.restore();
  await repositories.lock.restore();
  await repositories.theme.restore(server: repositories.server.current);
  await repositories.todos.restore();
  await repositories.reminders.restore();
  await repositories.kiosk.restore();
  // The app lock counts the time in the background (#46).
  AppLifecycleListener(
    onHide: repositories.lock.onHidden,
    onResume: repositories.lock.onResumed,
  );

  final router = createRouter(
    repositories.server,
    repositories.session,
    lock: repositories.lock,
    kiosk: repositories.kiosk,
  );
  // Coming back to the app may mean another network: check which server
  // address answers (#189). The listener lives as long as the app.
  AppLifecycleListener(
    onResume: () {
      repositories.server.selectAddress().ignore();
      // Records focus phases the phone finished while the app was away.
      repositories.focusTimer.refresh(repositories.server.current).ignore();
    },
  );
  runApp(
    MultiProvider(
      providers: providers(repositories),
      // Theme and language apply as soon as they change in the settings.
      child: ListenableBuilder(
        listenable: Listenable.merge([
          repositories.preferences,
          repositories.theme,
        ]),
        builder: (context, _) => WaylightApp(
          router: router,
          appearance: repositories.preferences.appearance,
          palette: repositories.theme.palette,
          wallpaperSeed: repositories.theme.wallpaperSeed,
          onShortcut: (shortcut) => router.go(shortcutLocation(shortcut)),
        ),
      ),
    ),
  );
}

/// Refreshes the home screen widgets in a headless engine that Android's
/// WorkManager starts while the app is closed (#48, ADR 0009).
@pragma('vm:entry-point')
Future<void> backgroundRefresh() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();
  final repositories = createRepositories();
  await refreshHomeWidgetsInBackground(
    server: repositories.server,
    session: repositories.session,
    preferences: repositories.preferences,
    homeWidgets: repositories.homeWidgets,
    reminders: repositories.reminders,
    quickTiles: repositories.quickTiles,
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
}

/// Runs the action of a Quick Settings tile in a headless engine the tile
/// starts (#192); the first argument names the tile.
@pragma('vm:entry-point')
Future<void> quickTileAction(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();
  final repositories = createRepositories();
  await runQuickTileInBackground(
    server: repositories.server,
    session: repositories.session,
    preferences: repositories.preferences,
    quickTiles: repositories.quickTiles,
    tile: args.firstOrNull,
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
}

/// Reads or changes Android's device controls in a headless engine the
/// controls start (#194): `refresh`, or `act` and an entity id.
@pragma('vm:entry-point')
Future<void> deviceControlsAction(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();
  final repositories = createRepositories();
  await runDeviceControlsInBackground(
    server: repositories.server,
    session: repositories.session,
    preferences: repositories.preferences,
    deviceControls: repositories.deviceControls,
    args: args,
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
}
