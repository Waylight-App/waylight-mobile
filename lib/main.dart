import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/config/dependencies.dart';
import 'package:waylight_mobile/config/logging.dart';
import 'package:waylight_mobile/routing/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  final serverRepository = createServerRepository();
  // A failure only means the user has to enter the address again.
  await serverRepository.restore();

  runApp(
    MultiProvider(
      providers: providers(serverRepository: serverRepository),
      child: WaylightApp(router: createRouter(serverRepository)),
    ),
  );
}
