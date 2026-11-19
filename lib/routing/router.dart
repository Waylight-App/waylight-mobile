import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/auth_callback/view_models/auth_callback_view_model.dart';
import 'package:waylight_mobile/ui/auth_callback/widgets/auth_callback_screen.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/edit_tab/view_models/edit_tab_view_model.dart';
import 'package:waylight_mobile/ui/edit_tab/widgets/edit_tab_screen.dart';
import 'package:waylight_mobile/ui/lock/view_models/lock_view_model.dart';
import 'package:waylight_mobile/ui/lock/widgets/lock_screen.dart';
import 'package:waylight_mobile/ui/pair/view_models/pair_view_model.dart';
import 'package:waylight_mobile/ui/pair/widgets/pair_screen.dart';
import 'package:waylight_mobile/ui/search/view_models/search_view_model.dart';
import 'package:waylight_mobile/ui/search/widgets/search_screen.dart';
import 'package:waylight_mobile/ui/settings/view_models/security_view_model.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/security_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_screen.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_screen.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/notes/note_editor_screen.dart';
import 'package:waylight_mobile/ui/widgets/notes/note_editor_view_model.dart';
import 'package:waylight_mobile/ui/widgets/readlater/article_screen.dart';
import 'package:waylight_mobile/ui/widgets/registry.dart';
import 'package:waylight_mobile/ui/widgets/rss/rss_reader_view_model.dart';
import 'package:waylight_mobile/ui/widgets/rss/rss_screen.dart';
import 'package:waylight_mobile/ui/widgets/services/service_details_screen.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_screen.dart';
import 'package:waylight_mobile/ui/widgets/shopping/shopping_view_model.dart';
import 'package:waylight_mobile/ui/widgets/smarthome/smarthome_screen.dart';
import 'package:waylight_mobile/ui/widgets/timeline/timeline_screen.dart';

/// Creates the router of the app.
///
/// Redirects follow the repositories: without a server every route leads to
/// [Routes.connect], without a session to [Routes.signIn]. Each route hosts
/// its view model in a [ViewModelHost], so the view model lives exactly as
/// long as the screen.
GoRouter createRouter(
  ServerRepository serverRepository,
  SessionRepository sessionRepository, {
  AppLockRepository? lock,
}) => GoRouter(
  initialLocation: Routes.home,
  refreshListenable: Listenable.merge([
    serverRepository,
    sessionRepository,
    ?lock,
  ]),
  redirect: (context, state) => redirectFor(
    uri: state.uri,
    connected: serverRepository.current != null,
    signedIn: sessionRepository.signedIn,
    locked: lock?.locked ?? false,
  ),
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => ViewModelHost(
        create: (context) => DashboardViewModel(
          pushRepository: context.read(),
          themeRepository: context.read(),
          initialTabId: state.uri.queryParameters['tab'] ?? '',
          initialWidgetKind: state.uri.queryParameters['widget'] ?? '',
          serverRepository: context.read(),
          dashboardRepository: context.read(),
          offlineRepository: context.read(),
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
          pushRepository: context.read(),
          lockRepository: context.read(),
        ),
        builder: (context, viewModel) => SettingsScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.pair,
      builder: (context, state) => ViewModelHost(
        create: (context) => PairViewModel(
          server: state.uri.queryParameters['server'] ?? '',
          code: state.uri.queryParameters['code'] ?? '',
          serverRepository: context.read(),
          sessionRepository: context.read(),
        ),
        builder: (context, viewModel) => PairScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.auth,
      builder: (context, state) => ViewModelHost(
        create: (context) => AuthCallbackViewModel(
          query: state.uri.queryParameters,
          sessionRepository: context.read(),
        ),
        builder: (context, viewModel) =>
            AuthCallbackScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.search,
      builder: (context, state) => ViewModelHost(
        create: (context) => SearchViewModel(
          initialQuery: state.uri.queryParameters['q'] ?? '',
          language: context.l10n.localeName,
          serverRepository: context.read(),
          searchRepository: context.read(),
          dashboardRepository: context.read(),
          todosRepository: context.read(),
        ),
        builder: (context, viewModel) => SearchScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.calendar,
      builder: (context, state) => ViewModelHost(
        create: (context) => CalendarViewModel(
          serverRepository: context.read(),
          calendarRepository: context.read(),
        ),
        builder: (context, viewModel) => CalendarScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.shopping,
      builder: (context, state) => ViewModelHost(
        create: (context) => ShoppingViewModel(
          serverRepository: context.read(),
          shoppingRepository: context.read(),
        ),
        builder: (context, viewModel) => ShoppingScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.feeds,
      builder: (context, state) => ViewModelHost(
        create: (context) => RssReaderViewModel(
          serverRepository: context.read(),
          rss: context.read(),
        ),
        builder: (context, viewModel) => RssScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.timeline,
      builder: (context, state) => ViewModelHost(
        create: (context) => RemoteWidgetViewModel(
          server: context.read(),
          data: context.read(),
          query: timelineQuery,
        ),
        builder: (context, viewModel) => TimelineScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.smartHome,
      builder: (context, state) => SmartHomeScreen.route(),
    ),
    GoRoute(
      path: Routes.note,
      builder: (context, state) => ViewModelHost(
        create: (context) => NoteEditorViewModel(
          noteId: state.uri.queryParameters['id'] ?? '',
          serverRepository: context.read(),
          notesRepository: context.read(),
        ),
        builder: (context, viewModel) => NoteEditorScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.article,
      builder: (context, state) => ViewModelHost(
        create: (context) => ArticleViewModel(
          articleId: state.uri.queryParameters['id'] ?? '',
          serverRepository: context.read(),
          readLater: context.read(),
        ),
        builder: (context, viewModel) => ArticleScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.service,
      builder: (context, state) => ServiceDetailsScreen(
        id: state.uri.queryParameters['id'] ?? '',
        name: state.uri.queryParameters['name'] ?? '',
      ),
    ),
    GoRoute(
      path: Routes.security,
      builder: (context, state) => ViewModelHost(
        create: (context) => SecurityViewModel(
          serverRepository: context.read(),
          security: context.read(),
        ),
        builder: (context, viewModel) => SecurityScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.locked,
      builder: (context, state) => ViewModelHost(
        create: (context) => LockViewModel(lock: context.read()),
        builder: (context, viewModel) => LockScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.editTab,
      builder: (context, state) => ViewModelHost(
        create: (context) => EditTabViewModel(
          tabId: state.uri.queryParameters['tab'] ?? '',
          serverRepository: context.read(),
          dashboardRepository: context.read(),
        ),
        builder: (context, viewModel) => EditTabScreen(viewModel: viewModel),
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
  bool locked = false,
}) {
  final link = routeOf(uri);
  if (!Routes.all.contains(link.path)) return Routes.home;
  // The app lock comes first: nothing shows until it is unlocked (#46).
  if (locked) {
    if (link.path == Routes.locked) return link == uri ? null : link.toString();
    final keep = link.path != Routes.home;
    return Uri(
      path: Routes.locked,
      queryParameters: keep ? {'from': link.toString()} : null,
    ).toString();
  }
  if (link.path == Routes.locked) {
    final from = link.queryParameters['from'];
    return _isLocal(from) ? from : Routes.home;
  }
  // Pairing links and the answer of a browser sign-in bring their own
  // server or code, so they open without either; once signed in they lead
  // to the dashboard (#43, #45).
  if (link.path == Routes.pair || link.path == Routes.auth) {
    if (connected && signedIn) return Routes.home;
    return link == uri ? null : link.toString();
  }
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
