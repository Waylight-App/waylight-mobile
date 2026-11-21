import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/server/address_selector.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/address_routes.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/platform_api.dart';
import 'package:waylight_mobile/domain/models/address_check.dart';
import 'package:waylight_mobile/domain/models/session.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

/// Home and away addresses (#189). The fake network answers per host:
/// "ok" knows the session, "other" is another Waylight without it, and
/// "down" never answers within the timeout.
void main() {
  final public = testServer();
  final lan = testServer('http://192.168.178.115:8090');
  final vpn = testServer('http://10.8.0.7:8090');

  late Map<String, String> network;
  late List<(Uri, String?)> sent;
  late AddressRoutes routes;
  late ApiCredentials credentials;
  late InMemoryKeyValueStore store;
  late StreamController<void> changes;

  ApiClient client() => ApiClient(
    credentials: credentials,
    routes: routes,
    client: MockClient((request) async {
      sent.add((request.url, request.headers['authorization']));
      final mode = network[request.url.host] ?? 'down';
      if (mode == 'down') {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        throw http.ClientException('unreachable');
      }
      final known =
          request.headers['authorization'] == 'Bearer t' && mode == 'ok';
      return http.Response(
        '{"setupRequired":false,"authenticated":$known'
        '${known ? ',"username":"anna","role":"owner"' : ''}}',
        200,
      );
    }),
  );

  ServerRepositoryRemote repository() {
    final api = PlatformApi(client());
    return ServerRepositoryRemote(
      platformApi: api,
      store: store,
      selector: AddressSelector(
        api: api,
        timeout: const Duration(milliseconds: 50),
      ),
      routes: routes,
      signedIn: (s) => credentials.session?.server == s,
      networkChanges: changes.stream,
    );
  }

  setUp(() {
    network = {'home.example.org': 'ok', '192.168.178.115': 'ok'};
    sent = [];
    routes = AddressRoutes();
    credentials = ApiCredentials()
      ..session = AppSession(server: public, token: 't');
    store = InMemoryKeyValueStore();
    changes = StreamController<void>.broadcast();
  });
  tearDown(() => changes.close());

  test('routes rewrite only requests to their server', () {
    final r = AddressRoutes()..route(public, lan);
    expect(
      r.rewrite(public.resolve('/api/todos')).toString(),
      'http://192.168.178.115:8090/api/todos',
    );
    final other = Uri.parse('https://other.example.org/api/todos');
    expect(r.rewrite(other), other);
    r.route(public, public);
    expect(
      r.rewrite(public.resolve('/api/todos')),
      public.resolve('/api/todos'),
    );
  });

  test(
    'requests go to the address in use with the session of the server',
    () async {
      routes.route(public, lan);
      await client().getJson(public.resolve('/api/todos'));
      expect(sent.single.$1.host, '192.168.178.115');
      expect(sent.single.$2, 'Bearer t');
    },
  );

  test('the first address in order that knows the session wins', () async {
    final repo = repository();
    await repo.connect(public);
    await repo.setAddresses([lan, public]);
    expect(repo.active, lan);
    expect(repo.checks, {lan: AddressCheck.ok, public: AddressCheck.ok});

    // Away from home: the home network address no longer answers.
    network.remove('192.168.178.115');
    changes.add(null);
    await pumpEventQueue();
    await repo.selectAddress();
    expect(repo.active, public);
    expect(repo.checks[lan], AddressCheck.unreachable);
  });

  test('an address that answers without the session is skipped', () async {
    network['192.168.178.115'] = 'other';
    final repo = repository();
    await repo.connect(public);
    await repo.setAddresses([lan, public]);
    expect(repo.active, public);
    expect(repo.checks[lan], AddressCheck.rejected);
  });

  test('nothing answers: no address in use, the route stays', () async {
    final repo = repository();
    await repo.connect(public);
    await repo.setAddresses([lan, public]);
    network.clear();
    await repo.selectAddress();
    expect(repo.active, isNull);
    expect(routes.rewrite(public.resolve('/x')).host, '192.168.178.115');
  });

  test('addresses and the last choice are kept per server', () async {
    final repo = repository();
    await repo.connect(public);
    await repo.setAddresses([public, vpn, lan]);
    expect(repo.active, public);
    await repo.setAddresses([lan, public]);

    routes = AddressRoutes();
    final restored = repository();
    await restored.restore();
    expect(restored.addresses, [lan, public]);
    // Requests go to the last address in use before the first new check.
    expect(routes.rewrite(public.resolve('/x')).host, '192.168.178.115');

    await restored.disconnect();
    expect(
      store.values.keys.where((k) => k.contains('server.addresses')),
      isEmpty,
    );
  });

  test('refuses an empty list, duplicates and more than three', () async {
    final repo = repository();
    await repo.connect(public);
    for (final bad in [
      <Never>[],
      [lan, lan],
      [lan, public, vpn, testServer('https://four.example.org')],
    ]) {
      expect(await repo.setAddresses(bad), isA<Error<void>>(), reason: '$bad');
    }
    expect(repo.addresses, [public]);
    expect(ServerRepository.maxAddresses, 3);
  });

  test('without a session the first address that answers is used', () async {
    credentials.session = null;
    network['192.168.178.115'] = 'other';
    final repo = repository();
    await repo.connect(public);
    await repo.setAddresses([lan, public]);
    expect(repo.active, lan);
    expect(
      await PlatformApi(client()).probeAuthStatus(
        public,
        via: vpn,
        timeout: const Duration(milliseconds: 50),
      ),
      isA<Error<Object?>>(),
    );
  });

  test(
    'a single remaining address is used even if it is not the first one',
    () async {
      final repo = repository();
      await repo.connect(public);
      await repo.setAddresses([lan]);
      expect(repo.active, lan);
      expect(routes.rewrite(public.resolve('/x')).host, '192.168.178.115');
    },
  );
}
