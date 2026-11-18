import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/home/view_models/home_view_model.dart';
import 'package:waylight_mobile/ui/home/widgets/home_screen.dart';

/// Creates the router of the app.
///
/// Redirects follow the [ServerRepository]: without a server every route
/// leads to [Routes.connect]. Each route hosts its view model in a
/// [ViewModelHost], so the view model lives exactly as long as the screen.
GoRouter createRouter(ServerRepository serverRepository) => GoRouter(
  initialLocation: Routes.home,
  refreshListenable: serverRepository,
  redirect: (context, state) {
    final connected = serverRepository.current != null;
    final onConnect = state.matchedLocation == Routes.connect;
    if (!connected) return onConnect ? null : Routes.connect;
    if (onConnect) return Routes.home;
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => ViewModelHost(
        create: (context) => HomeViewModel(serverRepository: context.read()),
        builder: (context, viewModel) => HomeScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.connect,
      builder: (context, state) => ViewModelHost(
        create: (context) =>
            ConnectServerViewModel(serverRepository: context.read()),
        builder: (context, viewModel) =>
            ConnectServerScreen(viewModel: viewModel),
      ),
    ),
  ],
);
