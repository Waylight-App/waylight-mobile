import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:waylight_mobile/data/repositories/watch/watch_pairing_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/watch/watch_handover.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/watch_link.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_barcode_scanner.dart';
import '../../../testing/fakes/fake_handover_sealer.dart';
import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  const key = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8';
  final link = WatchLink.parse(
    'waylight://watch?addr=192.168.1.23:41234&key=$key',
  )!;

  late FakeBarcodeScanner scanner;
  late FakeHandoverSealer sealer;
  late List<http.Request> serverRequests;
  late List<http.Request> watchRequests;
  late int serverStatus;
  late int watchStatus;

  setUp(() {
    scanner = FakeBarcodeScanner();
    sealer = FakeHandoverSealer();
    serverRequests = [];
    watchRequests = [];
    serverStatus = 201;
    watchStatus = 204;
  });

  WatchPairingRepository repository() => WatchPairingRepository(
    api: ModuleApi(
      ApiClient(
        client: MockClient((request) async {
          serverRequests.add(request);
          return http.Response(
            serverStatus == 201
                ? '{"code":"c0de","expiresAt":"2026-11-21T12:05:00Z"}'
                : '{"error":{"code":"forbidden"}}',
            serverStatus,
          );
        }),
      ),
    ),
    scanner: scanner,
    sealer: sealer,
    watch: WatchClient(
      MockClient((request) async {
        watchRequests.add(request);
        return http.Response('', watchStatus);
      }),
    ),
  );

  test('the message matches the plaintext of the watch test vector', () {
    final message = WatchPairingRepository.handoverMessage(
      testServer('http://192.168.178.115:8090'),
      'test-code',
    );
    expect(
      utf8.decode(message),
      '{"server":"http://192.168.178.115:8090","code":"test-code"}',
    );
  });

  test('creates a code and sends it sealed to the watch', () async {
    final result = await repository().pair(link, testServer());

    expect(result, isA<Ok<void>>());
    expect(serverRequests.single.method, 'POST');
    expect(
      serverRequests.single.url.path,
      '/api/auth/app-sessions/pairing-code',
    );
    expect(sealer.sealed, [
      '{"server":"https://home.example.org","code":"c0de"}',
    ]);
    final sent = watchRequests.single;
    expect(sent.url.toString(), 'http://192.168.1.23:41234/pair');
    expect(sent.body, isNot(contains('=')));
    expect(sent.body, isNot(contains('c0de')));
    final decoded = base64Url.decode(base64Url.normalize(sent.body));
    expect(utf8.decode(decoded.sublist(2)), sealer.sealed.single);
  });

  test("maps the watch's answers", () async {
    final cases = {
      401: WatchPairingFailure.rejected,
      422: WatchPairingFailure.invalidServer,
      502: WatchPairingFailure.serverUnreachable,
      400: WatchPairingFailure.notDecryptable,
      404: WatchPairingFailure.watchUnreachable,
    };
    for (final MapEntry(key: status, value: failure) in cases.entries) {
      watchStatus = status;
      final result = await repository().pair(link, testServer());
      expect(
        (result as Error<void>).error,
        isA<WatchPairingException>().having(
          (e) => e.failure,
          'failure',
          failure,
        ),
        reason: '$status',
      );
    }
  });

  test('a watch that does not answer is unreachable', () async {
    final repo = WatchPairingRepository(
      api: ModuleApi(
        ApiClient(
          client: MockClient(
            (_) async => http.Response('{"code":"c0de"}', 201),
          ),
        ),
      ),
      scanner: scanner,
      sealer: sealer,
      watch: WatchClient(
        MockClient((_) async => throw http.ClientException('refused')),
      ),
    );
    final result = await repo.pair(link, testServer());
    expect(
      (result as Error<void>).error,
      isA<WatchPairingException>().having(
        (e) => e.failure,
        'failure',
        WatchPairingFailure.watchUnreachable,
      ),
    );
  });

  test('sends nothing when the server refuses a code', () async {
    serverStatus = 403;
    final result = await repository().pair(link, testServer());

    expect((result as Error<void>).error, isA<ApiException>());
    expect(watchRequests, isEmpty);
  });

  test('sends nothing when the phone cannot seal', () async {
    sealer.supported = false;
    final result = await repository().pair(link, testServer());

    expect(
      (result as Error<void>).error,
      isA<WatchPairingException>().having(
        (e) => e.failure,
        'failure',
        WatchPairingFailure.unsupported,
      ),
    );
    expect(watchRequests, isEmpty);
  });

  test('scans a watch code, a cancel and a foreign code', () async {
    final repo = repository();
    scanner.next = 'waylight://watch?addr=192.168.1.23:41234&key=$key';
    expect(
      (await repo.scan() as Ok<WatchLink?>).value?.address,
      '192.168.1.23:41234',
    );
    scanner.next = null;
    expect((await repo.scan() as Ok<WatchLink?>).value, isNull);
    scanner.next = 'https://example.org';
    expect(await repo.scan(), isA<Error<WatchLink?>>());
  });
}
