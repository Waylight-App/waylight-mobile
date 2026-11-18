import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/home/view_models/home_view_model.dart';
import 'package:waylight_mobile/ui/home/widgets/home_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeServerRepository repository;

  setUp(() => repository = FakeServerRepository(current: testServer()));

  testWidgets('shows the connected server', (tester) async {
    final viewModel = HomeViewModel(serverRepository: repository);
    await tester.pumpScreen(HomeScreen(viewModel: viewModel));

    expect(
      find.text(l10nEn.homeConnectedTo('https://home.example.org')),
      findsOneWidget,
    );
    expect(find.text(l10nEn.homeComingSoon), findsOneWidget);
  });

  testWidgets('asks to finish the setup in the browser', (tester) async {
    repository.statusResult = const Result.ok(
      ServerStatus(setupRequired: true),
    );
    final viewModel = HomeViewModel(serverRepository: repository);
    await tester.pumpScreen(HomeScreen(viewModel: viewModel));

    expect(find.text(l10nEn.homeSetupRequired), findsOneWidget);
  });

  testWidgets('disconnects from the server', (tester) async {
    final viewModel = HomeViewModel(serverRepository: repository);
    await tester.pumpScreen(HomeScreen(viewModel: viewModel));

    await tester.tap(find.byKey(const ValueKey('home.disconnect')));
    await tester.pump();

    expect(repository.current, isNull);
  });
}
