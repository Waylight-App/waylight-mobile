import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';

/// The services and repositories of the app: the composition root.
///
/// Only this file knows the concrete classes. Everything else depends on
/// the abstract repositories, so tests can provide fakes instead. The
/// [serverRepository] is created before the app starts, because the router
/// needs it.
List<SingleChildWidget> providers({
  required ServerRepository serverRepository,
}) => [ChangeNotifierProvider<ServerRepository>.value(value: serverRepository)];

/// Creates the server repository with its real services.
ServerRepository createServerRepository() => ServerRepositoryRemote(
  platformApi: PlatformApi(ApiClient(client: http.Client())),
  store: const SecureKeyValueStore(),
);
