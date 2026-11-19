import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/repositories/notes/notes_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository.dart';
import 'package:waylight_mobile/data/repositories/weather/weather_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/data/services/api/dashboard_api.dart';
import 'package:waylight_mobile/data/services/api/notes_api.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/data/services/api/todos_api.dart';
import 'package:waylight_mobile/data/services/api/weather_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';

/// The repositories of the app. Server and session are needed by the
/// router before the app starts.
typedef Repositories = ({
  ServerRepository server,
  SessionRepository session,
  DashboardRepository dashboard,
  WeatherRepository weather,
  TodosRepository todos,
  NotesRepository notes,
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
  Provider<NotesRepository>.value(value: repositories.notes),
];

/// Creates the repositories with their real services. They share one API
/// client, so every request carries the current session.
Repositories createRepositories() {
  final credentials = ApiCredentials();
  final client = ApiClient(client: http.Client(), credentials: credentials);
  const store = SecureKeyValueStore();
  return (
    server: ServerRepositoryRemote(
      platformApi: PlatformApi(client),
      store: store,
    ),
    session: SessionRepositoryRemote(
      authApi: AuthApi(client),
      credentials: credentials,
      store: store,
    ),
    dashboard: DashboardRepositoryRemote(api: DashboardApi(client)),
    weather: WeatherRepositoryRemote(api: WeatherApi(client)),
    todos: TodosRepositoryRemote(api: TodosApi(client)),
    notes: NotesRepositoryRemote(api: NotesApi(client)),
  );
}
