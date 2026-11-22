import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/first_start/first_start_repository.dart';
import 'package:waylight_mobile/data/repositories/kiosk/kiosk_repository.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/attention/view_models/attention_view_model.dart';
import 'package:waylight_mobile/ui/attention/widgets/attention_screen.dart';
import 'package:waylight_mobile/ui/auth_callback/view_models/auth_callback_view_model.dart';
import 'package:waylight_mobile/ui/auth_callback/widgets/auth_callback_screen.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/reminder_texts.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/kiosk_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/kiosk_screen.dart';
import 'package:waylight_mobile/ui/first_start/view_models/first_start_view_model.dart';
import 'package:waylight_mobile/ui/first_start/widgets/first_start_screen.dart';
import 'package:waylight_mobile/ui/home_widgets/home_widget_texts.dart';
import 'package:waylight_mobile/ui/home_widgets/quick_tile_texts.dart';
import 'package:waylight_mobile/ui/lock/view_models/lock_view_model.dart';
import 'package:waylight_mobile/ui/lock/widgets/lock_screen.dart';
import 'package:waylight_mobile/ui/pair/view_models/pair_view_model.dart';
import 'package:waylight_mobile/ui/pair/widgets/pair_screen.dart';
import 'package:waylight_mobile/ui/pair_watch/view_models/pair_watch_view_model.dart';
import 'package:waylight_mobile/ui/pair_watch/widgets/pair_watch_screen.dart';
import 'package:waylight_mobile/ui/search/view_models/search_view_model.dart';
import 'package:waylight_mobile/ui/search/widgets/search_screen.dart';
import 'package:waylight_mobile/ui/settings/view_models/security_view_model.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_index.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/security_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_area_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_screen.dart';
import 'package:waylight_mobile/ui/share/view_models/share_view_model.dart';
import 'package:waylight_mobile/ui/share/widgets/share_screen.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';
import 'package:waylight_mobile/ui/tag/view_models/tag_action_view_model.dart';
import 'package:waylight_mobile/ui/tag/widgets/tag_action_screen.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_screen.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/tag_writer.dart';
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
/// [Routes.connect], without a session to [Routes.signIn], and the first
/// time on a server to [Routes.welcome]. Each route hosts
/// its view model in a [ViewModelHost], so the view model lives exactly as
/// long as the screen.
GoRouter createRouter(
  ServerRepository serverRepository,
  SessionRepository sessionRepository, {
  AppLockRepository? lock,
  KioskRepository? kiosk,
  FirstStartRepository? firstStart,
}) => GoRouter(
  initialLocation: Routes.home,
  refreshListenable: Listenable.merge([
    serverRepository,
    sessionRepository,
    ?lock,
    ?kiosk,
    ?firstStart,
  ]),
  redirect: (context, state) => redirectFor(
    uri: state.uri,
    connected: serverRepository.current != null,
    signedIn: sessionRepository.signedIn,
    locked: lock?.locked ?? false,
    kiosk: kiosk?.active ?? false,
    firstStart: switch ((firstStart, serverRepository.current)) {
      (final repository?, final server?) => !repository.isDone(server),
      _ => false,
    },
  ),
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => ViewModelHost(
        create: (context) => DashboardViewModel(
          pushRepository: context.read(),
          themeRepository: context.read(),
          homeWidgetsRepository: context.read(),
          homeWidgetFormatter: HomeWidgetTexts(context.l10n),
          reminderRepository: context.read(),
          reminderFormatter: ReminderTexts(context.l10n),
          quickTilesRepository: context.read(),
          quickTileFormatter: QuickTileTexts(context.l10n),
          initialTabId: state.uri.queryParameters['tab'] ?? '',
          initialWidgetKind: state.uri.queryParameters['widget'] ?? '',
          serverRepository: context.read(),
          dashboardRepository: context.read(),
          offlineRepository: context.read(),
          attentionRepository: context.read(),
          compactRepository: context.read(),
          helpRepository: context.read(),
        ),
        builder: (context, viewModel) => DashboardScreen(
          viewModel: viewModel,
          registry: nativeWidgets,
          writeTabTag: defaultTargetPlatform == TargetPlatform.android
              ? writeTabTag
              : null,
        ),
      ),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => _settings(null),
      // Nested, so an area opened from a link goes back to the start page.
      routes: [
        for (final area in SettingsArea.values)
          GoRoute(
            path: area.segment,
            builder: (context, state) => _settings(
              area,
              focus: SettingsItem.values
                  .asNameMap()[state.uri.queryParameters['focus']],
            ),
          ),
        GoRoute(
          path: Routes.security.substring(Routes.settings.length + 1),
          builder: (context, state) => ViewModelHost(
            create: (context) => SecurityViewModel(
              serverRepository: context.read(),
              security: context.read(),
            ),
            builder: (context, viewModel) =>
                SecurityScreen(viewModel: viewModel),
          ),
        ),
        GoRoute(
          path: Routes.pairWatch.substring(Routes.settings.length + 1),
          builder: (context, state) => ViewModelHost(
            create: (context) => PairWatchViewModel(
              serverRepository: context.read(),
              watchRepository: context.read(),
            ),
            builder: (context, viewModel) =>
                PairWatchScreen(viewModel: viewModel),
          ),
        ),
      ],
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
      path: Routes.attention,
      builder: (context, state) => ViewModelHost(
        create: (context) => AttentionViewModel(
          serverRepository: context.read(),
          attentionRepository: context.read(),
        ),
        builder: (context, viewModel) => AttentionScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.tag,
      builder: (context, state) => ViewModelHost(
        create: (context) => TagActionViewModel(
          query: state.uri.queryParameters,
          serverRepository: context.read(),
          habitsRepository: context.read(),
          smartHomeRepository: context.read(),
          shoppingRepository: context.read(),
        ),
        builder: (context, viewModel) => TagActionScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.share,
      builder: (context, state) => ViewModelHost(
        create: (context) => ShareViewModel(
          text: state.uri.queryParameters['text'] ?? '',
          serverRepository: context.read(),
          data: context.read(),
          todos: context.read(),
          notes: context.read(),
          readLater: context.read(),
          bookmarks: context.read(),
          drop: context.read(),
        ),
        builder: (context, viewModel) => ShareScreen(viewModel: viewModel),
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
      path: Routes.connect,
      builder: (context, state) => ViewModelHost(
        create: (context) =>
            ConnectServerViewModel(serverRepository: context.read()),
        builder: (context, viewModel) => ConnectServerScreen(
          viewModel: viewModel,
          onKiosk: kiosk?.enter,
          kioskLink: state.uri.queryParameters['kiosk'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: Routes.kiosk,
      builder: (context, state) => ViewModelHost(
        create: (context) => KioskViewModel(
          servers: context.read(),
          dashboard: context.read(),
          kiosk: context.read(),
          compact: context.read(),
        ),
        builder: (context, viewModel) =>
            KioskScreen(viewModel: viewModel, registry: nativeWidgets),
      ),
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (context, state) => ViewModelHost(
        create: (context) => FirstStartViewModel(
          serverRepository: context.read(),
          firstStartRepository: context.read(),
          preferencesRepository: context.read(),
          pushRepository: context.read(),
          lockRepository: context.read(),
          themeRepository: context.read(),
        ),
        builder: (context, viewModel) => FirstStartScreen(viewModel: viewModel),
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

/// Hosts the settings start page (`null`) or one [area] with its own view
/// model; all settings screens share the view model class (#231). [focus]
/// is the setting a search result pointed to (#232).
ViewModelHost<SettingsViewModel> _settings(
  SettingsArea? area, {
  SettingsItem? focus,
}) => ViewModelHost(
  create: (context) =>
      SettingsViewModel(
          serverRepository: context.read(),
          sessionRepository: context.read(),
          preferencesRepository: context.read(),
          pushRepository: context.read(),
          lockRepository: context.read(),
          diagnosticsRepository: context.read(),
          themeRepository: context.read(),
          reminderRepository: context.read(),
          quickTilesRepository: context.read(),
          attentionRepository: context.read(),
          widgetData: context.read(),
        )
        ..reminderFormatter = ReminderTexts(context.l10n)
        ..quickTileFormatter = QuickTileTexts(context.l10n),
  builder: (context, viewModel) => area == null
      ? SettingsScreen(viewModel: viewModel)
      : SettingsAreaScreen(area: area, viewModel: viewModel, focus: focus),
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
/// after the sign-in. While [firstStart] is due, the dashboard gives way to
/// the first-start questions (#287). Unknown paths open the dashboard.
/// `null` keeps [uri].
@visibleForTesting
String? redirectFor({
  required Uri uri,
  required bool connected,
  required bool signedIn,
  bool locked = false,
  bool kiosk = false,
  bool firstStart = false,
}) {
  var link = routeOf(uri);
  if (!Routes.all.contains(link.path)) return Routes.home;
  // A tag that opens a tab is a link to the dashboard (#260); it passes the
  // app lock and sign-in below like any other link.
  if (link.path == Routes.tag && link.queryParameters['do'] == 'tab') {
    final tab = link.queryParameters['id']?.trim() ?? '';
    link = tab.isEmpty
        ? Uri(path: Routes.home)
        : Uri(path: Routes.home, queryParameters: {'tab': tab});
  }
  // A wall display shows nothing but its tabs (#193).
  if (kiosk && connected && signedIn) {
    return link.path == Routes.kiosk && link == uri ? null : Routes.kiosk;
  }
  if (link.path == Routes.kiosk) {
    // waylight://kiosk?link=… opens the connect screen with the link.
    final kioskLink = link.queryParameters['link'];
    if (kioskLink == null || kioskLink.isEmpty) return Routes.home;
    return Uri(
      path: Routes.connect,
      queryParameters: {'kiosk': kioskLink},
    ).toString();
  }
  // The app lock comes first: nothing shows until it is unlocked (#46).
  if (locked) {
    if (link.path == Routes.locked) return link == uri ? null : link.toString();
    // The dashboard with a tab (#260) is worth returning to as well.
    final keep = link.toString() != Routes.home;
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
  if (onEntry) {
    final target = _isLocal(from) ? from! : Routes.home;
    return firstStart && target == Routes.home ? Routes.welcome : target;
  }
  if (link.path == Routes.welcome && !firstStart) return Routes.home;
  // Only the plain dashboard: a link to a tab or a screen opens as asked,
  // and the questions follow on the next way home.
  if (firstStart && link.toString() == Routes.home) return Routes.welcome;
  return link == uri ? null : link.toString();
}

// Only paths inside the app may come from `?from=`.
bool _isLocal(String? from) =>
    from != null && from.startsWith('/') && !from.startsWith('//');
