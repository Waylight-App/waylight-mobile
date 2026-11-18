import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/config/dependencies.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/home/widgets/home_screen.dart';

import '../testing/fakes/fake_server_repository.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeServerRepository repo) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: providers(serverRepository: repo),
        child: WaylightApp(router: createRouter(repo)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the connect screen without a server', (tester) async {
    await pumpApp(tester, FakeServerRepository());

    expect(find.byType(ConnectServerScreen), findsOneWidget);
  });

  testWidgets('starts on the home screen with a server', (tester) async {
    await pumpApp(tester, FakeServerRepository(current: testServer()));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('follows the repository when it connects', (tester) async {
    final repository = FakeServerRepository();
    await pumpApp(tester, repository);

    await repository.connect(testServer());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);

    await repository.disconnect();
    await tester.pumpAndSettle();

    expect(find.byType(ConnectServerScreen), findsOneWidget);
  });
}
