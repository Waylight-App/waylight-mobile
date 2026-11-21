import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/kiosk/kiosk_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/kiosk.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_device_auth.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_session_repository.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

/// The wall display (#193).
void main() {
  group('kiosk link', () {
    test('reads server and token from the link the server shows', () {
      final link = parseKioskLink('https://home.example.org/kiosk#abc%2Bdef');
      expect(link, isA<Ok<KioskLink>>());
      final value = (link as Ok<KioskLink>).value;
      expect(value.server.toString(), 'https://home.example.org');
      expect(value.token, 'abc+def');
      expect(
        (parseKioskLink(
          'https://nas.example.org/waylight/kiosk#t',
        ) as Ok<KioskLink>).value.server.toString(),
        'https://nas.example.org/waylight',
      );
    });

    test('refuses other links', () {
      for (final bad in [
        'https://home.example.org/kiosk',
        'https://home.example.org/#t',
        'nonsense',
      ]) {
        expect(parseKioskLink(bad), isA<Error<KioskLink>>(), reason: bad);
      }
    });
  });

  test('night dimming, also over midnight', () {
    const night = KioskOptions(nightFrom: '22:00', nightTo: '06:30');
    expect(night.nightAt(DateTime(2026, 11, 21, 23)), isTrue);
    expect(night.nightAt(DateTime(2026, 11, 21, 6, 29)), isTrue);
    expect(night.nightAt(DateTime(2026, 11, 21, 6, 30)), isFalse);
    expect(night.nightAt(DateTime(2026, 11, 21, 12)), isFalse);
    const day = KioskOptions(nightFrom: '12:00', nightTo: '13:00');
    expect(day.nightAt(DateTime(2026, 11, 21, 12, 30)), isTrue);
    expect(const KioskOptions().nightAt(DateTime(2026, 11, 21, 23)), isFalse);
  });

  group('KioskRepository', () {
    late FakeServerRepository servers;
    late FakeSessionRepository sessions;
    late FakeDeviceAuth auth;
    late InMemoryKeyValueStore store;

    KioskRepository repository() => KioskRepository(
      servers: servers,
      sessions: sessions,
      api: ModuleApi(
        ApiClient(
          client: MockClient(
            (_) async => http.Response(
              '{"rotateSeconds":30,"nightFrom":"22:00","nightTo":"06:00"}',
              200,
            ),
          ),
        ),
      ),
      store: store,
      auth: auth,
    );

    setUp(() {
      servers = FakeServerRepository();
      sessions = FakeSessionRepository();
      auth = FakeDeviceAuth();
      store = InMemoryKeyValueStore();
    });

    test('a kiosk link connects, signs in and reads the options', () async {
      final repo = repository();
      expect(
        await repo.enter('https://home.example.org/kiosk#tok'),
        isA<Ok<void>>(),
      );
      expect(servers.current.toString(), 'https://home.example.org');
      expect(sessions.kioskCalls, ['tok']);
      expect(repo.active, isTrue);
      expect(repo.options.rotateSeconds, 30);

      final restored = repository();
      await restored.restore();
      expect(restored.active, isTrue, reason: 'survives a restart');
    });

    test('a broken link changes nothing', () async {
      final repo = repository();
      expect(await repo.enter('https://home.example.org/'), isA<Error<void>>());
      expect(servers.current, isNull);
      expect(repo.active, isFalse);
    });

    test('a disabled link on the server leads to the connect screen', () async {
      final repo = repository();
      await repo.enter('https://home.example.org/kiosk#tok');
      sessions
        ..signedIn = false
        ..notifyListeners();
      await pumpEventQueue();
      expect(repo.active, isFalse);
      expect(servers.current, isNull);
    });

    test('leaving needs the device credential', () async {
      final repo = repository();
      await repo.enter('https://home.example.org/kiosk#tok');
      auth.succeeds = false;
      expect(await repo.leave('why'), isFalse);
      expect(repo.active, isTrue);
      auth.succeeds = true;
      expect(await repo.leave('why'), isTrue);
      expect(repo.active, isFalse);
      expect(sessions.signOutCalls, 1);
      expect(servers.current, isNull);
    });
  });

  group('redirect', () {
    test('a wall display shows only its screen', () {
      String? go(String path, {bool kiosk = true}) => redirectFor(
        uri: Uri.parse(path),
        connected: true,
        signedIn: true,
        kiosk: kiosk,
      );
      expect(go(Routes.home), Routes.kiosk);
      expect(go(Routes.settings), Routes.kiosk);
      expect(go(Routes.kiosk), isNull);
      expect(go(Routes.kiosk, kiosk: false), Routes.home);
    });

    test('a kiosk deep link opens the connect screen with the link', () {
      final to = redirectFor(
        uri: Uri.parse(
          '/kiosk?link=https%3A%2F%2Fhome.example.org%2Fkiosk%23t',
        ),
        connected: false,
        signedIn: false,
      );
      expect(Uri.parse(to!).path, Routes.connect);
      expect(
        Uri.parse(to).queryParameters['kiosk'],
        'https://home.example.org/kiosk#t',
      );
    });
  });
}
