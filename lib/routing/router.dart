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
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_screen.dart';
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
    uri: state.uri,
    connected: serverRepository.current != null,
    signedIn: sessionRepository.signedIn,
  ),
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => ViewModelHost(
        create: (context) => DashboardViewModel(
          serverRepository: context.read(),
          dashboardRepository: context.read(),
        ),
        builder: (context, viewModel) =>
            DashboardScreen(viewModel: viewModel, registry: nativeWidgets),
      ),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => ViewModelHost(
        create: (context) => SettingsViewModel(
          serverRepository: context.read(),
          sessionRepository: context.read(),
          preferencesRepository: context.read(),
        ),
        builder: (context, viewModel) => SettingsScreen(viewModel: viewModel),
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

/// The app's scheme for links from outside, e.g. `waylight://settings`
/// (#47). Android and iOS register it.
const deepLinkScheme = 'waylight';

/// The route of a link from outside: `waylight://settings?x=1` becomes
/// `/settings?x=1`, because the target is in the host part there. Other
/// locations stay as they are.
@visibleForTesting
Uri routeOf(Uri uri) {
  if (uri.scheme != deepLinkScheme) {
    return uri.path.isEmpty ? uri.replace(path: Routes.home) : uri;
  }
  return Uri(
    path: '/${uri.host}${uri.path}',
    query: uri.hasQuery ? uri.query : null,
  );
}

/// Where the router sends the user for [uri]: the connect screen without a
/// server, the sign-in screen without a session, otherwise away from both.
/// The location the user wanted travels along in `?from=` and is opened
/// after the sign-in. Unknown paths open the dashboard. `null` keeps [uri].
@visibleForTesting
String? redirectFor({
  required Uri uri,
  required bool connected,
  required bool signedIn,
}) {
  final link = routeOf(uri);
  if (!Routes.all.contains(link.path)) return Routes.home;
  final onEntry = link.path == Routes.connect || link.path == Routes.signIn;
  final from = onEntry ? link.queryParameters['from'] : link.toString();

  if (!connected || !signedIn) {
    final gate = connected ? Routes.signIn : Routes.connect;
    if (link.path == gate) return link == uri ? null : link.toString();
    final keep = from != null && from != Routes.home;
    return Uri(
      path: gate,
      queryParameters: keep ? {'from': from} : null,
    ).toString();
  }
  if (onEntry) return _isLocal(from) ? from : Routes.home;
  return link == uri ? null : link.toString();
}

// Only paths inside the app may come from `?from=`.
bool _isLocal(String? from) =>
    from != null && from.startsWith('/') && !from.startsWith('//');
