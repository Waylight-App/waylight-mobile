import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/config/dependencies.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';

import '../testing/fakes/fake_dashboard_repository.dart';
import '../testing/fakes/fake_server_repository.dart';
import '../testing/fakes/fake_session_repository.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeServerRepository servers,
    FakeSessionRepository sessions,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: providers((
          server: servers,
          session: sessions,
          dashboard: FakeDashboardRepository(),
        )),
        child: WaylightApp(router: createRouter(servers, sessions)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the connect screen without a server', (tester) async {
    await pumpApp(tester, FakeServerRepository(), FakeSessionRepository());

    expect(find.byType(ConnectServerScreen), findsOneWidget);
  });

  testWidgets('asks to sign in on a connected server', (tester) async {
    await pumpApp(
      tester,
      FakeServerRepository(current: testServer()),
      FakeSessionRepository(),
    );

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('follows connecting, signing in and out', (tester) async {
    final servers = FakeServerRepository();
    final sessions = FakeSessionRepository();
    await pumpApp(tester, servers, sessions);

    await servers.connect(testServer());
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    await sessions.signIn(testServer(), password: 'pw');
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    await sessions.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    await servers.disconnect();
    await tester.pumpAndSettle();
    expect(find.byType(ConnectServerScreen), findsOneWidget);
  });

  test('redirects by server and session', () {
    String? at(
      String location, {
      bool connected = true,
      bool signedIn = true,
    }) => redirectFor(
      location: location,
      connected: connected,
      signedIn: signedIn,
    );

    expect(at(Routes.home, connected: false, signedIn: false), Routes.connect);
    expect(at(Routes.connect, connected: false, signedIn: false), isNull);
    expect(at(Routes.home, signedIn: false), Routes.signIn);
    expect(at(Routes.connect, signedIn: false), Routes.signIn);
    expect(at(Routes.signIn, signedIn: false), isNull);
    expect(at(Routes.signIn), Routes.home);
    expect(at(Routes.connect), Routes.home);
    expect(at(Routes.home), isNull);
  });
}
