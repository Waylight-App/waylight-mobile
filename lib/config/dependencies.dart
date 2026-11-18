import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository_remote.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';

/// The repositories the router needs before the app starts.
typedef Repositories = ({ServerRepository server, SessionRepository session});

/// The services and repositories of the app: the composition root.
///
/// Only this file knows the concrete classes. Everything else depends on
/// the abstract repositories, so tests can provide fakes instead.
List<SingleChildWidget> providers(Repositories repositories) => [
  ChangeNotifierProvider<ServerRepository>.value(value: repositories.server),
  ChangeNotifierProvider<SessionRepository>.value(value: repositories.session),
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
  );
}
