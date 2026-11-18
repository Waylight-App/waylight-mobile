import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

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

    expect(find.text(l10nEn.connectErrorUnreachable), findsOneWidget);
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

  test('errorText has a message for every error', () {
    for (final reason in InvalidServerAddressReason.values) {
      expect(errorText(l10nEn, InvalidServerAddress(reason)), isNotEmpty);
    }
    for (final failure in ApiFailure.values) {
      expect(errorText(l10nEn, ApiException(failure)), isNotEmpty);
    }
    expect(errorText(l10nEn, Exception()), l10nEn.connectErrorUnknown);
  });
}
