import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/account/account_security_repository.dart';
import 'package:waylight_mobile/domain/models/account_security.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/settings/view_models/security_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/security_screen.dart';

import '../../testing/fakes/fake_action_repositories.dart';
import '../../testing/fakes/fake_link_opener.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);

  late FakeAccountSecurity security;
  late FakeLinkOpener links;

  setUp(() {
    security = FakeAccountSecurity()
      ..list = [
        AccountSession(
          id: 'a',
          device: 'Pixel',
          lastSeenAt: DateTime(2026, 11, 19),
          current: true,
        ),
        AccountSession(
          id: 'b',
          userAgent: 'Firefox on Linux',
          clientIp: '192.168.1.20',
          lastSeenAt: DateTime(2026, 11, 18),
        ),
      ];
    links = FakeLinkOpener();
  });

  Future<void> pump(WidgetTester tester) async {
    final vm = SecurityViewModel(
      serverRepository: FakeServerRepository(current: testServer()),
      security: security,
    );
    addTearDown(vm.dispose);
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: links,
        child: SecurityScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('parses the sessions of the server', () {
    final list = parseSessions([
      {
        'id': 'x',
        'device': 'Pixel',
        'userAgent': '',
        'clientIp': '10.0.0.2',
        'lastSeenAt': '2026-11-19T08:00:00Z',
        'current': true,
      },
    ])!;
    expect(list.single.current, isTrue);
    expect(list.single.device, 'Pixel');
  });

  testWidgets('lists sessions and signs out another device', (tester) async {
    await pump(tester);
    expect(find.text(l10nEn.securityThisDevice), findsOneWidget);
    await tester.tap(find.byTooltip(l10nEn.securitySignOutSession));
    await tester.pumpAndSettle();
    expect(security.calls, ['revoke:b']);
  });

  testWidgets('changes the password', (tester) async {
    await pump(tester);
    await tester.tap(
      find.widgetWithText(OutlinedButton, l10nEn.securityChangePassword),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'old-secret');
    await tester.enterText(find.byType(TextField).at(1), 'new-secret-123');
    await tester.tap(
      find.widgetWithText(FilledButton, l10nEn.securityChangePassword),
    );
    await tester.pumpAndSettle();
    expect(security.calls, ['password:new-secret-123']);
    expect(find.text(l10nEn.securityPasswordChanged), findsOneWidget);
  });

  testWidgets('sets up two-factor sign-in and shows the recovery codes', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(l10nEn.securityTotpSetUp));
    await tester.pumpAndSettle();
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    await tester.tap(find.text(l10nEn.securityOpenAuthenticator));
    expect(links.opened.single.scheme, 'otpauth');

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text(l10nEn.securityConfirm));
    await tester.pumpAndSettle();
    expect(find.textContaining('aaaa-bbbb'), findsOneWidget);
    await tester.tap(find.text(l10nEn.securityCodesSaved));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.securityTotpOff), findsOneWidget);
  });
}
