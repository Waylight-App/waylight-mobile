import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';

/// Creates the router of the app.
///
/// Redirects follow the repositories: without a server every route leads to
/// [Routes.connect], without a session to [Routes.signIn]. Each route hosts
/// its view model in a [ViewModelHost], so the view model lives exactly as
/// long as the screen.
GoRouter createRouter(
  ServerRepository serverRepository,
  SessionRepository sessionRepository,
) => GoRouter(
  initialLocation: Routes.home,
  refreshListenable: Listenable.merge([serverRepository, sessionRepository]),
  redirect: (context, state) => redirectFor(
    location: state.matchedLocation,
    connected: serverRepository.current != null,
    signedIn: sessionRepository.signedIn,
  ),
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => ViewModelHost(
        create: (context) => DashboardViewModel(
          serverRepository: context.read(),
          sessionRepository: context.read(),
          dashboardRepository: context.read(),
        ),
        builder: (context, viewModel) =>
            DashboardScreen(viewModel: viewModel, registry: nativeWidgets),
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
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => ViewModelHost(
        create: (context) => SignInViewModel(
          serverRepository: context.read(),
          sessionRepository: context.read(),
        ),
        builder: (context, viewModel) => SignInScreen(viewModel: viewModel),
      ),
    ),
  ],
);

/// Where the router sends the user at [location]: the connect screen
/// without a server, the sign-in screen without a session, otherwise away
/// from both. `null` keeps the location.
@visibleForTesting
String? redirectFor({
  required String location,
  required bool connected,
  required bool signedIn,
}) {
  final target = !connected
      ? Routes.connect
      : !signedIn
      ? Routes.signIn
      : null;
  if (target != null) return location == target ? null : target;
  final onEntry = location == Routes.connect || location == Routes.signIn;
  return onEntry ? Routes.home : null;
}
