import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository_remote.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/auth_api.dart';
import 'package:waylight_mobile/data/services/auth/pkce.dart';
import 'package:waylight_mobile/domain/models/session.dart';
import 'package:waylight_mobile/ui/auth_callback/view_models/auth_callback_view_model.dart';
import 'package:waylight_mobile/ui/auth_callback/widgets/auth_callback_screen.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/fakes/in_memory_key_value_store.dart';
import '../../testing/pump_app.dart';

void main() {
  group('repository', () {
    late InMemoryKeyValueStore store;
    late ApiCredentials credentials;
    late List<http.Request> requests;
    late http.Response Function(http.Request) answer;

    SessionRepositoryRemote create() => SessionRepositoryRemote(
      authApi: AuthApi(
        ApiClient(
          credentials: credentials,
          client: MockClient((r) async {
            requests.add(r);
            return answer(r);
          }),
        ),
      ),
      credentials: credentials,
      store: store,
      deviceName: 'Pixel',
    );

    setUp(() {
      store = InMemoryKeyValueStore();
      credentials = ApiCredentials();
      requests = [];
      answer = (_) => http.Response('{"token":"wa_b"}', 201);
    });

    test('detects servers that offer app sessions', () async {
      answer = (_) =>
          http.Response('{"error":{"code":"invalid","field":"device"}}', 422);
      expect(await create().supportsBrowserSignIn(testServer()), isTrue);
      answer = (_) => http.Response('', 404);
      expect(await create().supportsBrowserSignIn(testServer()), isFalse);
    });

    test('starts with a challenge and finishes with the verifier', () async {
      final repository = create();
      final url =
          (await repository.startBrowserSignIn(testServer()) as Ok<Uri>).value;

      expect(url.path, '/app-sign-in');
      final pending =
          jsonDecode(store.values[SessionRepositoryRemote.pendingKey]!) as Map;
      expect(
        url.queryParameters['challenge'],
        Pkce.challengeOf(pending['verifier'] as String),
      );

      final result = await repository.finishBrowserSignIn(
        code: 'c',
        state: url.queryParameters['state']!,
      );

      expect(result, isA<Ok<void>>());
      expect(jsonDecode(requests.single.body), {
        'device': 'Pixel',
        'pairingCode': 'c',
        'verifier': pending['verifier'],
      });
      expect(
        credentials.session,
        AppSession(server: testServer(), token: 'wa_b'),
      );
      expect(
        store.values.containsKey(SessionRepositoryRemote.pendingKey),
        isFalse,
      );
    });

    test('refuses answers to sign-ins it did not start', () async {
      final repository = create();
      await repository.startBrowserSignIn(testServer());

      final wrongState = await repository.finishBrowserSignIn(
        code: 'c',
        state: 'other',
      );
      final noPending = await repository.finishBrowserSignIn(
        code: 'c',
        state: 'x',
      );

      expect((wrongState as Error<void>).error, isA<UnexpectedSignIn>());
      expect((noPending as Error<void>).error, isA<UnexpectedSignIn>());
      expect(requests, isEmpty);
    });
  });

  group('screens', () {
    testWidgets('offers the browser sign-in where the server supports it', (
      tester,
    ) async {
      Future<void> pump(bool supported) async {
        final sessions = FakeSessionRepository()..browserSupported = supported;
        await tester.pumpScreen(
          SignInScreen(
            viewModel: SignInViewModel(
              serverRepository: FakeServerRepository(current: testServer()),
              sessionRepository: sessions,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(false);
      expect(find.byKey(const ValueKey('signIn.browser')), findsNothing);
      await pump(true);
      expect(find.byKey(const ValueKey('signIn.browser')), findsOneWidget);
    });

    Future<void> callback(
      WidgetTester tester,
      Map<String, String> query,
      FakeSessionRepository sessions,
    ) async {
      await tester.pumpScreen(
        AuthCallbackScreen(
          viewModel: AuthCallbackViewModel(
            query: query,
            sessionRepository: sessions,
          ),
        ),
      );
      // The spinner keeps turning until the router leaves the screen.
      await tester.pump();
      await tester.pump();
    }

    testWidgets('finishes the sign-in', (tester) async {
      final sessions = FakeSessionRepository();
      await callback(tester, {'code': 'c', 'state': 's'}, sessions);

      expect(sessions.signedIn, isTrue);
    });

    testWidgets('explains a cancelled or foreign sign-in', (tester) async {
      await callback(tester, {
        'error': 'access_denied',
        'state': 's',
      }, FakeSessionRepository());
      expect(find.text(l10nEn.authCallbackCancelled), findsOneWidget);

      final foreign = FakeSessionRepository()
        ..finishResult = const Result.error(UnexpectedSignIn());
      await callback(tester, {'code': 'c', 'state': 'x'}, foreign);
      expect(find.text(l10nEn.authCallbackUnexpected), findsOneWidget);
      expect(find.text(l10nEn.authCallbackBack), findsOneWidget);
    });
  });
}
