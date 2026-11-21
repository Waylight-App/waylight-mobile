import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_index.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_view_model.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_area_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_screen.dart';
import 'package:waylight_mobile/ui/settings/widgets/settings_texts.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_action_repositories.dart';
import '../../testing/fakes/fake_attention_repository.dart';
import '../../testing/fakes/fake_preferences_repository.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  List<SettingsHit> search(
    String query, {
    bool Function(SettingsItem)? available,
    String Function(SettingsItem)? title,
  }) => searchSettings(
    query,
    available: available ?? (_) => true,
    title: title ?? (item) => itemTitle(l10nEn, item),
    areaTitle: (area) => areaTitle(l10nEn, area),
  );

  Iterable<SettingsItem?> items(List<SettingsHit> hits) =>
      hits.map((h) => h.item);

  group('searchSettings', () {
    test('finds settings by German and English synonyms', () {
      expect(items(search('akku')), contains(SettingsItem.battery));
      expect(items(search('Battery')), contains(SettingsItem.battery));
      expect(items(search('pin')), contains(SettingsItem.lock));
      expect(items(search('adresse')), contains(SettingsItem.addresses));
      expect(items(search('prüfen')), contains(SettingsItem.checkAddresses));
      expect(items(search('Geburtstag')), contains(SettingsItem.reminders));
    });

    test('finds settings by their title in the app language', () {
      final de = lookupAppLocalizations(const Locale('de'));
      final hits = search('schnelleinst', title: (item) => itemTitle(de, item));
      expect(items(hits), contains(SettingsItem.quickTiles));
    });

    test('finds areas by their title', () {
      final hits = search('this phone');
      expect(hits.where((h) => h.item == null).map((h) => h.area), [
        SettingsArea.phone,
      ]);
    });

    test('needs every word and finds nothing for blank queries', () {
      expect(items(search('dark theme')), [SettingsItem.theme]);
      expect(search('   '), isEmpty);
      expect(search('zebra'), isEmpty);
    });

    test('leaves out what the phone or account does not have', () {
      final hits = search(
        'akku',
        available: (item) => item != SettingsItem.battery,
      );
      expect(items(hits), isNot(contains(SettingsItem.battery)));
    });
  });

  group('screens', () {
    late FakeServerRepository servers;

    SettingsViewModel create({bool push = false}) => SettingsViewModel(
      serverRepository: servers,
      sessionRepository: FakeSessionRepository(signedIn: true),
      preferencesRepository: FakePreferencesRepository(),
      pushRepository: FakePushRepository()..isAvailable = push,
      appVersion: () async => '0.3.0 (7)',
    );

    setUp(() {
      servers = FakeServerRepository(current: testServer())
        ..statusResult = const Result.ok(
          ServerStatus(setupRequired: false, username: 'anna', role: 'member'),
        );
    });

    testWidgets('filters the start page live and clears again', (tester) async {
      await tester.pumpScreen(SettingsScreen(viewModel: create(push: true)));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('settings.search')),
        'akku',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings.hit.notifications.battery')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('settings.area.server')), findsNothing);

      await tester.tap(find.byTooltip(l10nEn.settingsSearchClear));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings.area.server')),
        findsOneWidget,
      );
    });

    testWidgets('shows the attention hint while something needs help', (
      tester,
    ) async {
      final attention = FakeAttentionRepository(
        items: const [
          AttentionItem(
            id: 'module:immich',
            kind: AttentionKind.connection,
            integration: 'immich',
            title: 'immich',
            message: 'The server rejected the login.',
            action: AttentionAction.fix,
          ),
        ],
      );
      final viewModel = SettingsViewModel(
        serverRepository: servers,
        sessionRepository: FakeSessionRepository(signedIn: true),
        preferencesRepository: FakePreferencesRepository(),
        attentionRepository: attention,
        appVersion: () async => '0.3.0 (7)',
      );
      await tester.pumpScreen(SettingsScreen(viewModel: viewModel));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.attentionBadge(1)), findsOneWidget);

      await attention.clear();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings.attention')), findsNothing);
    });

    testWidgets('does not find push where the phone has none', (tester) async {
      await tester.pumpScreen(SettingsScreen(viewModel: create()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('settings.search')),
        'akku',
      );
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.settingsSearchEmpty('akku')), findsOneWidget);
    });

    testWidgets('opens an area scrolled to the setting, highlighted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpScreen(
        SettingsAreaScreen(
          area: SettingsArea.about,
          viewModel: create(),
          focus: SettingsItem.licences,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final licences = find.text(l10nEn.settingsLicences);
      expect(tester.getBottomLeft(licences).dy, lessThan(500));
      final target = tester.widget<AnimatedContainer>(
        find
            .ancestor(of: licences, matching: find.byType(AnimatedContainer))
            .first,
      );
      expect(
        (target.decoration! as BoxDecoration).color,
        isNot(Colors.transparent),
      );

      await tester.pump(SettingsTarget.highlight);
      await tester.pumpAndSettle();
      final faded = tester.widget<AnimatedContainer>(
        find
            .ancestor(of: licences, matching: find.byType(AnimatedContainer))
            .first,
      );
      expect((faded.decoration! as BoxDecoration).color, Colors.transparent);
    });
  });
}
