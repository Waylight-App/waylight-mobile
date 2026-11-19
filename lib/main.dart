import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/config/dependencies.dart';
import 'package:waylight_mobile/config/logging.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/shortcuts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  final repositories = createRepositories();
  // A failure only means the user has to enter the address or sign in
  // again. The session needs the restored server to check it belongs to it.
  await repositories.server.restore();
  await repositories.session.restore(repositories.server.current);
  await repositories.preferences.restore();
  await repositories.lock.restore();
  // The app lock counts the time in the background (#46).
  AppLifecycleListener(
    onHide: repositories.lock.onHidden,
    onResume: repositories.lock.onResumed,
  );

  final router = createRouter(
    repositories.server,
    repositories.session,
    lock: repositories.lock,
  );
  runApp(
    MultiProvider(
      providers: providers(repositories),
      // Theme and language apply as soon as they change in the settings.
      child: ListenableBuilder(
        listenable: repositories.preferences,
        builder: (context, _) => WaylightApp(
          router: router,
          appearance: repositories.preferences.appearance,
          onShortcut: (shortcut) => router.go(shortcutLocation(shortcut)),
        ),
      ),
    ),
  );
}
