import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository.dart';
import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/repositories/notes/notes_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository_local.dart';
import 'package:waylight_mobile/data/repositories/search/search_repository.dart';
import 'package:waylight_mobile/data/repositories/search/search_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_outbox.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/data/services/api/bookmarks_api.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/api/notes_api.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/data/services/api/search_api.dart';
import 'package:waylight_mobile/data/services/api/todos_api.dart';
import 'package:waylight_mobile/data/services/api/transit_api.dart';
import 'package:waylight_mobile/data/services/api/waste_api.dart';
import 'package:waylight_mobile/data/services/api/weather_api.dart';
import 'package:waylight_mobile/data/services/cache/response_cache.dart';
import 'package:waylight_mobile/data/services/platform/device_auth.dart';
import 'package:waylight_mobile/data/services/platform/device_name.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';

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
  PreferencesRepository preferences,
  OfflineRepository offline,
  SearchRepository search,
  AppLockRepository lock,
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
  Provider<SearchRepository>.value(value: repositories.search),
  ChangeNotifierProvider<AppLockRepository>.value(value: repositories.lock),
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
  final client = ApiClient(
    client: http.Client(),
    credentials: credentials,
    cache: cache,
    offline: offline,
  );
  const store = SecureKeyValueStore();
  final server = ServerRepositoryRemote(
    platformApi: PlatformApi(client),
    store: store,
  );
  final todos = TodosRepositoryOutbox(
    remote: TodosRepositoryRemote(api: TodosApi(client)),
    store: store,
    offline: offline,
    server: () => server.current,
  );
  return (
    server: server,
    session: SessionRepositoryRemote(
      authApi: AuthApi(client),
      credentials: credentials,
      store: store,
      deviceName: deviceName(),
      cache: cache,
      onForget: [todos.clear],
    ),
    dashboard: DashboardRepositoryRemote(api: DashboardApi(client)),
    weather: WeatherRepositoryRemote(api: WeatherApi(client)),
    todos: todos,
    notes: NotesRepositoryRemote(api: NotesApi(client)),
    bookmarks: BookmarksRepositoryRemote(api: BookmarksApi(client)),
    transit: TransitRepositoryRemote(api: TransitApi(client)),
    waste: WasteRepositoryRemote(api: WasteApi(client)),
    widgetData: WidgetDataRepositoryRemote(api: ModuleApi(client)),
    preferences: PreferencesRepositoryLocal(store: store),
    offline: OfflineRepository(offline),
    search: SearchRepositoryRemote(api: SearchApi(client)),
    lock: AppLockRepository(auth: LocalDeviceAuth(), store: store),
  );
}
