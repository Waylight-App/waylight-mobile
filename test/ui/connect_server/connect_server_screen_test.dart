import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_action_repositories.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeServerRepository repository;
  late ConnectServerViewModel viewModel;

  setUp(() {
    repository = FakeServerRepository();
    viewModel = ConnectServerViewModel(serverRepository: repository);
  });

  Future<void> enter(WidgetTester tester, String address) async {
    await tester.enterText(
      find.byKey(const ValueKey('connect.address')),
      address,
    );
    await tester.tap(find.byKey(const ValueKey('connect.submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('connects to the entered server', (tester) async {
    await tester.pumpScreen(ConnectServerScreen(viewModel: viewModel));

    await enter(tester, 'home.example.org');

    expect(repository.connectCalls, [testServer()]);
  });

  testWidgets('shows why an address is invalid', (tester) async {
    await tester.pumpScreen(ConnectServerScreen(viewModel: viewModel));

    await enter(tester, 'ftp://example.org');

    expect(find.text(l10nEn.connectErrorScheme), findsOneWidget);
  });

  testWidgets('shows that the server is unreachable', (tester) async {
    repository.statusResult = const Result.error(
      ApiException(ApiFailure.unreachable),
    );
    await tester.pumpScreen(ConnectServerScreen(viewModel: viewModel));

    await enter(tester, 'home.example.org');

    expect(find.text(l10nEn.errorUnreachable), findsOneWidget);
  });

  testWidgets('warns about plain HTTP', (tester) async {
    await tester.pumpScreen(ConnectServerScreen(viewModel: viewModel));

    await tester.enterText(
      find.byKey(const ValueKey('connect.address')),
      'http://192.168.1.2:8090',
    );
    await tester.pump();

    expect(find.text(l10nEn.connectInsecureWarning), findsOneWidget);
  });

  testWidgets('is translated into German', (tester) async {
    await tester.pumpScreen(
      ConnectServerScreen(viewModel: viewModel),
      locale: const Locale('de'),
    );

    expect(find.text('Verbinde dein Waylight'), findsOneWidget);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpScreen(ConnectServerScreen(viewModel: viewModel));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('says when the address is not a Waylight server', (tester) async {
    repository.statusResult = const Result.error(
      ApiException(ApiFailure.server),
    );
    await tester.pumpScreen(ConnectServerScreen(viewModel: viewModel));

    await enter(tester, 'router.example.org');

    expect(find.text(l10nEn.connectErrorNotWaylight), findsOneWidget);
  });

  group('an error is shown either at the field or in the banner', () {
    test('invalid addresses at the field', () {
      for (final reason in InvalidServerAddressReason.values) {
        final error = InvalidServerAddress(reason);
        expect(fieldError(l10nEn, error), isNotEmpty, reason: reason.name);
        expect(bannerError(l10nEn, error), isNull, reason: reason.name);
      }
    });

    test('everything else in the banner', () {
      for (final failure in ApiFailure.values) {
        final error = ApiException(failure);
        expect(fieldError(l10nEn, error), isNull, reason: failure.name);
        expect(bannerError(l10nEn, error), isNotEmpty, reason: failure.name);
      }
      expect(bannerError(l10nEn, Exception()), l10nEn.errorUnknown);
    });
  });

  testWidgets('the privacy note names Google only when push is possible', (
    tester,
  ) async {
    await tester.pumpScreen(ConnectServerScreen(viewModel: viewModel));
    expect(find.text(l10nEn.connectPrivacy), findsOneWidget);

    final withPush = ConnectServerViewModel(
      serverRepository: repository,
      pushRepository: FakePushRepository(),
    );
    addTearDown(withPush.dispose);
    await tester.pumpScreen(ConnectServerScreen(viewModel: withPush));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.connectPrivacyPush), findsOneWidget);
    expect(find.bySemanticsLabel('Waylight'), findsWidgets);
  });
}
