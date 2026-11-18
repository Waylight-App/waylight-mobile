import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeSessionRepository sessions;

  Future<void> pump(WidgetTester tester, {Locale? locale}) => tester.pumpScreen(
    SignInScreen(
      viewModel: SignInViewModel(
        serverRepository: FakeServerRepository(current: testServer()),
        sessionRepository: sessions,
      ),
    ),
    locale: locale ?? const Locale('en'),
  );

  Future<void> submit(WidgetTester tester, String password) async {
    await tester.enterText(
      find.byKey(const ValueKey('signIn.password')),
      password,
    );
    await tester.tap(find.byKey(const ValueKey('signIn.submit')));
    await tester.pumpAndSettle();
  }

  setUp(() => sessions = FakeSessionRepository());

  testWidgets('signs in with account name and password', (tester) async {
    await pump(tester);

    await tester.enterText(
      find.byKey(const ValueKey('signIn.username')),
      'anna',
    );
    await submit(tester, 'pw');

    expect(sessions.signInCalls.single, (
      username: 'anna',
      password: 'pw',
      code: '',
    ));
  });

  testWidgets('asks for the code in a second step', (tester) async {
    sessions.signInResult = const Result.ok(
      CodeRequired(authenticatorApp: false),
    );
    await pump(tester);

    await submit(tester, 'pw');

    expect(find.byKey(const ValueKey('signIn.code')), findsOneWidget);
    expect(find.text(l10nEn.signInCodeHintRecovery), findsOneWidget);
  });

  testWidgets('clears the password after a failed attempt', (tester) async {
    sessions.signInResult = const Result.error(
      ApiException(ApiFailure.unauthorized),
    );
    await pump(tester);

    await submit(tester, 'wrong');

    expect(find.text(l10nEn.signInErrorCredentials), findsOneWidget);
    expect(find.text('wrong'), findsNothing);
  });

  testWidgets('explains an ended session', (tester) async {
    sessions.expired = true;
    await pump(tester);

    expect(find.text(l10nEn.signInExpired), findsOneWidget);
  });

  testWidgets('works in German', (tester) async {
    await pump(tester, locale: const Locale('de'));

    expect(find.text('Anmelden'), findsWidgets);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  test('maps errors to messages', () {
    const unauthorized = ApiException(ApiFailure.unauthorized);
    expect(
      signInError(l10nEn, unauthorized, false),
      l10nEn.signInErrorCredentials,
    );
    expect(signInError(l10nEn, unauthorized, true), l10nEn.signInErrorCode);
    expect(
      signInError(l10nEn, const ApiException(ApiFailure.forbidden), false),
      l10nEn.homeSetupRequired,
    );
    expect(
      signInError(
        l10nEn,
        const ApiException(ApiFailure.tooManyRequests),
        false,
      ),
      l10nEn.errorTooManyRequests,
    );
  });
}
