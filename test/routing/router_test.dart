import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/config/dependencies.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/offline/offline_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository_outbox.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';

import '../testing/fakes/fake_action_repositories.dart';
import '../testing/fakes/fake_bookmarks_repository.dart';
import '../testing/fakes/fake_dashboard_repository.dart';
import '../testing/fakes/fake_device_auth.dart';
import '../testing/fakes/fake_habits_repository.dart';
import '../testing/fakes/fake_notes_repository.dart';
import '../testing/fakes/fake_preferences_repository.dart';
import '../testing/fakes/fake_search_repository.dart';
import '../testing/fakes/fake_server_repository.dart';
import '../testing/fakes/fake_session_repository.dart';
import '../testing/fakes/fake_shopping_repository.dart';
import '../testing/fakes/fake_todos_repository.dart';
import '../testing/fakes/fake_transit_repository.dart';
import '../testing/fakes/fake_waste_repository.dart';
import '../testing/fakes/fake_weather_repository.dart';
import '../testing/fakes/fake_widget_data_repository.dart';
import '../testing/fakes/in_memory_key_value_store.dart';

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
          weather: FakeWeatherRepository(),
          todos: TodosRepositoryOutbox(
            remote: FakeTodosRepository(),
            store: InMemoryKeyValueStore(),
            offline: OfflineStatus(),
            server: () => null,
          ),
          notes: FakeNotesRepository(),
          bookmarks: FakeBookmarksRepository(),
          transit: FakeTransitRepository(),
          waste: FakeWasteRepository(),
          widgetData: FakeWidgetDataRepository(),
          shopping: FakeShoppingRepository(),
          habits: FakeHabitsRepository(),
          rss: FakeRssRepository(),
          parcels: FakeParcelsRepository(),
          smartHome: FakeSmartHomeRepository(),
          focus: FakeFocusRepository(),
          preferences: FakePreferencesRepository(),
          offline: OfflineRepository(OfflineStatus()),
          search: FakeSearchRepository(),
          lock: AppLockRepository(
            auth: FakeDeviceAuth(),
            store: InMemoryKeyValueStore(),
          ),
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

  String? at(String location, {bool connected = true, bool signedIn = true}) =>
      redirectFor(
        uri: Uri.parse(location),
        connected: connected,
        signedIn: signedIn,
      );

  test('redirects by server and session', () {
    expect(at(Routes.home, connected: false, signedIn: false), Routes.connect);
    expect(at(Routes.connect, connected: false, signedIn: false), isNull);
    expect(at(Routes.home, signedIn: false), Routes.signIn);
    expect(at(Routes.connect, signedIn: false), Routes.signIn);
    expect(at(Routes.signIn, signedIn: false), isNull);
    expect(at(Routes.signIn), Routes.home);
    expect(at(Routes.connect), Routes.home);
    expect(at(Routes.home), isNull);
  });

  test('opens links from outside', () {
    expect(at('waylight://settings'), Routes.settings);
    expect(at('waylight://settings?tab=1'), '/settings?tab=1');
    expect(at('waylight://nowhere'), Routes.home);
    expect(
      at('waylight://auth?code=c&state=s', signedIn: false),
      '/auth?code=c&state=s',
    );
    expect(at('/nowhere'), Routes.home);
  });

  test('continues to the link after the sign-in', () {
    final gate = at('waylight://settings', signedIn: false)!;
    expect(gate, '/sign-in?from=%2Fsettings');

    expect(at(gate), Routes.settings);
    expect(at('/sign-in?from=%2F%2Fevil.example.org'), Routes.home);
    expect(
      at('waylight://settings', connected: false, signedIn: false),
      '/connect?from=%2Fsettings',
    );
  });
}
