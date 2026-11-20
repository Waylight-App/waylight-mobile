import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_action_repositories.dart';
import '../../testing/fakes/fake_link_opener.dart';
import '../../testing/fakes/fake_preferences_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/fakes/fake_system_colors.dart';
import '../../testing/fakes/in_memory_key_value_store.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeServerRepository servers;
  late FakeSessionRepository sessions;
  late FakePreferencesRepository preferences;
  late FakeLinkOpener opener;

  SettingsViewModel create() => SettingsViewModel(
    serverRepository: servers,
    sessionRepository: sessions,
    preferencesRepository: preferences,
    appVersion: () async => '0.3.0 (7)',
  );

  setUp(() {
    servers = FakeServerRepository(current: testServer())
      ..statusResult = const Result.ok(
        ServerStatus(setupRequired: false, username: 'anna', role: 'member'),
      );
    sessions = FakeSessionRepository(signedIn: true);
    preferences = FakePreferencesRepository();
    opener = FakeLinkOpener();
  });

  Future<void> pump(WidgetTester tester) async {
    // Tall enough for all sections, so the lazy list builds every one.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: opener,
        child: SettingsScreen(viewModel: create()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows server, account and versions', (tester) async {
    await pump(tester);

    expect(find.text('https://home.example.org'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('anna'), findsOneWidget);
    expect(find.text(l10nEn.settingsRoleMember), findsOneWidget);
    expect(find.text('0.3.0 (7)'), findsOneWidget);
  });

  testWidgets('hides the server version when the account may not see it', (
    tester,
  ) async {
    servers.versionResult = const Result.error(FormatException('forbidden'));
    await pump(tester);

    expect(find.text(l10nEn.settingsVersion), findsNothing);
  });

  testWidgets('changes theme and language at once', (tester) async {
    await pump(tester);

    await tester.tap(find.text(l10nEn.settingsDark));
    await tester.pump();
    expect(preferences.appearance.theme, ThemeChoice.dark);

    await tester.tap(find.text('Deutsch'));
    await tester.pump();
    expect(preferences.appearance.language, AppLanguage.de);
  });

  testWidgets('signs out, and signs out before forgetting the server', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('settings.signOut')));
    await tester.pump();
    expect(sessions.signOutCalls, 1);

    await tester.tap(find.byKey(const ValueKey('settings.disconnect')));
    await tester.pump();
    expect(sessions.signOutCalls, 2);
    expect(servers.current, isNull);
  });

  testWidgets('opens the source code', (tester) async {
    await pump(tester);

    await tester.tap(find.text(l10nEn.settingsSource));
    await tester.pump();

    expect(opener.opened.single, sourceUrl);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  test('names the roles', () {
    expect(roleLabel(l10nEn, 'owner'), l10nEn.settingsRoleOwner);
    expect(roleLabel(l10nEn, 'unknown'), l10nEn.settingsAccount);
  });

  testWidgets('switches to and removes other servers', (tester) async {
    final other = testServer('https://other.example.org');
    servers.known = [testServer(), other];
    await pump(tester);

    expect(find.text('https://other.example.org'), findsOneWidget);
    await tester.tap(find.text('https://other.example.org'));
    await tester.pumpAndSettle();
    expect(servers.current, other);

    await tester.tap(find.byTooltip(l10nEn.settingsRemoveServer));
    await tester.pumpAndSettle();
    expect(servers.known, [other]);
    expect(sessions.discarded, [testServer()]);
  });

  testWidgets('adds a server without signing out', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('settings.addServer')));
    await tester.pumpAndSettle();

    expect(servers.current, isNull);
    expect(sessions.signOutCalls, 0);
  });

  testWidgets('turns notifications on and off', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final push = FakePushRepository();
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: opener,
        child: SettingsScreen(
          viewModel: SettingsViewModel(
            serverRepository: servers,
            sessionRepository: sessions,
            preferencesRepository: preferences,
            pushRepository: push,
            appVersion: () async => '0.3.0 (7)',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings.push')));
    await tester.pumpAndSettle();
    expect(push.calls, ['enable']);
    expect(await push.isOn(), isTrue);

    await tester.tap(find.byKey(const ValueKey('settings.push')));
    await tester.pumpAndSettle();
    expect(push.calls.last, 'disable');
  });

  testWidgets('builds without push show no notification switch', (
    tester,
  ) async {
    await tester.pumpScreen(
      SettingsScreen(
        viewModel: SettingsViewModel(
          serverRepository: servers,
          sessionRepository: sessions,
          preferencesRepository: preferences,
          pushRepository: FakePushRepository()..isAvailable = false,
          appVersion: () async => '0.3.0 (7)',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings.push')), findsNothing);
  });

  testWidgets(
    'offers wallpaper colours only where the system has them (#198)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<ThemeRepository> theme(int? color) async {
        final repo = ThemeRepository(
          api: ModuleApi(
            ApiClient(client: MockClient((_) async => http.Response('', 503))),
          ),
          store: InMemoryKeyValueStore(),
          systemColors: FakeSystemColors(color),
        );
        await repo.restore(server: testServer());
        return repo;
      }

      SettingsScreen screen(ThemeRepository repo) => SettingsScreen(
        viewModel: SettingsViewModel(
          serverRepository: servers,
          sessionRepository: sessions,
          preferencesRepository: preferences,
          themeRepository: repo,
          appVersion: () async => '0.3.0 (7)',
        ),
      );

      await tester.pumpScreen(screen(await theme(null)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings.colours')), findsNothing);

      final repo = await theme(0xFF3366CC);
      await tester.pumpScreen(screen(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallpaper'));
      await tester.pumpAndSettle();
      expect(repo.useWallpaper, isTrue);
    },
  );
}
