import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/repositories/first_start/first_start_repository.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/first_start/view_models/first_start_view_model.dart';
import 'package:waylight_mobile/ui/first_start/widgets/first_start_screen.dart';

import '../../testing/fakes/fake_action_repositories.dart';
import '../../testing/fakes/fake_device_auth.dart';
import '../../testing/fakes/fake_preferences_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_system_colors.dart';
import '../../testing/fakes/in_memory_key_value_store.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeServerRepository servers;
  late FirstStartRepository firstStart;
  late FakePreferencesRepository preferences;
  late FakePushRepository push;
  late FakeDeviceAuth auth;
  late AppLockRepository lock;
  late ThemeRepository theme;

  setUp(() async {
    servers = FakeServerRepository(current: testServer());
    firstStart = FirstStartRepository(store: InMemoryKeyValueStore());
    preferences = FakePreferencesRepository();
    push = FakePushRepository();
    auth = FakeDeviceAuth();
    lock = AppLockRepository(auth: auth, store: InMemoryKeyValueStore());
    theme = ThemeRepository(
      api: ModuleApi(
        ApiClient(client: MockClient((_) async => http.Response('', 503))),
      ),
      store: InMemoryKeyValueStore(),
      systemColors: FakeSystemColors(0xFF336699),
    );
    await theme.restore(server: testServer());
  });

  FirstStartViewModel create() => FirstStartViewModel(
    serverRepository: servers,
    firstStartRepository: firstStart,
    preferencesRepository: preferences,
    pushRepository: push,
    lockRepository: lock,
    themeRepository: theme,
  );

  Future<FirstStartViewModel> pump(WidgetTester tester) async {
    // Tall enough that every question fits without scrolling.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final viewModel = create();
    await tester.pumpScreen(FirstStartScreen(viewModel: viewModel));
    await tester.pumpAndSettle();
    return viewModel;
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('firstStart.next')));
    await tester.pumpAndSettle();
  }

  test('asks only what this phone has', () async {
    push.isAvailable = false;
    auth.isAvailable = false;
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.steps, [FirstStartStep.addresses, FirstStartStep.look]);
  });

  testWidgets('walks through every question and ends on Done', (tester) async {
    final viewModel = await pump(tester);
    expect(viewModel.steps, FirstStartStep.values);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text(l10nEn.firstStartLater), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('firstStart.push')));
    await tester.pumpAndSettle();
    expect(viewModel.pushOn, isTrue);

    await next(tester);
    expect(find.text('Step 2 of 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('firstStart.lock')));
    await tester.pumpAndSettle();
    expect(lock.enabled, isTrue);

    await tester.tap(find.byKey(const ValueKey('firstStart.back')));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 4'), findsOneWidget);
    await next(tester);
    await next(tester);
    expect(find.text(l10nEn.firstStartAddressesTitle), findsOneWidget);

    await next(tester);
    await tester.tap(find.text(l10nEn.settingsDark));
    await tester.pumpAndSettle();
    expect(preferences.appearance.theme, ThemeChoice.dark);
    await tester.tap(find.text(l10nEn.settingsColoursWallpaper));
    await tester.pumpAndSettle();
    expect(theme.useWallpaper, isTrue);
    expect(firstStart.isDone(testServer()), isFalse);

    expect(find.text(l10nEn.firstStartDone), findsOneWidget);
    await next(tester);
    expect(firstStart.isDone(testServer()), isTrue);
  });

  testWidgets('shows the battery hint while push is restricted', (
    tester,
  ) async {
    push.unrestricted = false;
    await pump(tester);
    expect(find.byKey(const ValueKey('firstStart.battery')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('firstStart.push')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.settingsPushBatteryAction));
    await tester.pumpAndSettle();
    expect(push.unrestricted, isTrue);
    expect(find.byKey(const ValueKey('firstStart.battery')), findsNothing);
  });

  testWidgets('adds a second address and explains a wrong one', (tester) async {
    push.isAvailable = false;
    auth.isAvailable = false;
    await pump(tester);

    final field = find.byKey(const ValueKey('firstStart.addressField'));
    await tester.enterText(field, 'ftp://x');
    await tester.tap(find.byKey(const ValueKey('firstStart.addAddress')));
    await tester.pumpAndSettle();
    expect(servers.addresses, [testServer()]);
    expect(find.text('ftp://x'), findsOneWidget);
    expect(tester.widget<TextField>(field).decoration?.errorText, isNotNull);

    await tester.enterText(field, 'http://192.168.1.10:8090');
    await tester.tap(find.byKey(const ValueKey('firstStart.addAddress')));
    await tester.pumpAndSettle();
    expect(servers.addresses, [
      testServer(),
      testServer('http://192.168.1.10:8090'),
    ]);

    await tester.tap(find.byTooltip(l10nEn.addressRemove).last);
    await tester.pumpAndSettle();
    expect(servers.addresses, [testServer()]);
  });

  testWidgets('skips everything at once', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('firstStart.skipAll')));
    await tester.pumpAndSettle();
    expect(firstStart.isDone(testServer()), isTrue);
  });

  testWidgets('reads in German', (tester) async {
    await tester.pumpScreen(
      FirstStartScreen(viewModel: create()),
      locale: const Locale('de'),
    );
    await tester.pumpAndSettle();
    expect(find.text('App einrichten'), findsOneWidget);
    expect(find.text('Schritt 1 von 4'), findsOneWidget);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  test('a wrong address keeps the list', () async {
    final viewModel = create();
    expect(
      await viewModel.addAddress('ftp://x'),
      isA<InvalidServerAddressReason>(),
    );
    expect(servers.addresses, [testServer()]);
  });
}
