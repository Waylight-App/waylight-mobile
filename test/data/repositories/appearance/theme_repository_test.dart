import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/fakes/fake_system_colors.dart';
import '../../../testing/fakes/in_memory_key_value_store.dart';

void main() {
  // Recorded from https://demo.getwaylight.app (the Amber theme).
  final appearance = File('test/fixtures/appearance_demo.json')
      .readAsStringSync();
  final css =
      (jsonDecode(appearance) as Map<String, Object?>)['customCss']! as String;

  test('reads light and dark colours from the theme CSS', () {
    final p = paletteFromCss(css)!;
    expect(p.accent, 0xFFF2B441);
    expect(p.onAccent, 0xFF1A1206);
    expect(p.light.background, 0xFFFFF3D6);
    expect(p.dark.background, 0xFF131829);
    expect(p.dark.accentText, 0xFFF2B441);
    expect(p.dark.surface, 0xFF1B2238);
  });

  test('CSS without an accent is no theme; short and alpha colours work', () {
    expect(paletteFromCss(''), isNull);
    expect(paletteFromCss(':root { --color-bg: #fff; }'), isNull);
    final p = paletteFromCss(
      ':root { --color-accent: #0a8; --color-bg: #11223380; }',
    )!;
    expect(p.accent, 0xFF00AA88);
    expect(p.light.background, 0x80112233);
  });

  test('refreshes, keeps the palette on the device and clears it', () async {
    final store = InMemoryKeyValueStore();
    final repo = ThemeRepository(
      api: ModuleApi(
        ApiClient(
          client: MockClient((_) async => http.Response(appearance, 200)),
        ),
      ),
      store: store,
    );
    await repo.refresh(testServer());
    expect(repo.palette?.accent, 0xFFF2B441);

    final restored = ThemeRepository(
      api: ModuleApi(
        ApiClient(client: MockClient((_) async => http.Response('', 503))),
      ),
      store: store,
    );
    await restored.restore();
    expect(restored.palette?.light.background, 0xFFFFF3D6);

    await repo.clear();
    expect(repo.palette, isNull);
    expect(store.values, isEmpty);
  });

  test('the app theme follows the palette', () {
    final p = paletteFromCss(css)!;
    final light = AppTheme.lightFor(p);
    expect(light.colorScheme.surface, const Color(0xFFFFF3D6));
    expect(light.colorScheme.primary, const Color(0xFF9C5D00));
    expect(AppTheme.darkFor(p).colorScheme.surface, const Color(0xFF131829));
    expect(AppTheme.light.colorScheme.primary, AppTheme.accentTextLight);
  });

  group('accessibility options (#291)', () {
    ThemeRepository create(String body, InMemoryKeyValueStore store) =>
        ThemeRepository(
          api: ModuleApi(
            ApiClient(
              client: MockClient((_) async => http.Response(body, 200)),
            ),
          ),
          store: store,
        );

    test('are read from the account and kept on the device', () async {
      final store = InMemoryKeyValueStore();
      final repo = create(
        '{"customCss":"","textSize":"larger","highContrast":true,'
        '"simpleView":true}',
        store,
      );
      expect(repo.accessibility, const Accessibility());
      await repo.refresh(testServer());
      expect(repo.accessibility.textSize, TextSize.larger);
      expect(repo.accessibility.highContrast, isTrue);
      expect(repo.accessibility.simpleView, isTrue);

      final restored = create('', store);
      await restored.restore();
      expect(restored.accessibility, repo.accessibility);

      await repo.clear();
      expect(repo.accessibility, const Accessibility());
      expect(store.values, isEmpty);
    });

    test('stay off on a server that does not know them', () async {
      final repo = create(
        '{"customCss":"","textSize":"huge"}',
        InMemoryKeyValueStore(),
      );
      await repo.refresh(testServer());
      expect(repo.accessibility, const Accessibility());
    });

    test('scale the text by the step', () {
      expect(TextSize.normal.factor, 1);
      expect(TextSize.large.factor, lessThan(TextSize.larger.factor));
    });
  });

  group('wallpaper colours (#198)', () {
    final offline = ModuleApi(
      ApiClient(client: MockClient((_) async => http.Response('', 503))),
    );
    final other = switch (ServerAddress.parse('https://other.example.org')) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };

    test('are offered only where the system has them', () async {
      final repo = ThemeRepository(
        api: offline,
        store: InMemoryKeyValueStore(),
        systemColors: FakeSystemColors(),
      );
      await repo.restore(server: testServer());
      expect(repo.wallpaperAvailable, isFalse);
      await repo.setWallpaper(testServer(), enabled: true);
      expect(repo.useWallpaper, isFalse);
      expect(repo.wallpaperSeed, isNull);
    });

    test('are stored per server and forgotten on sign-out', () async {
      final store = InMemoryKeyValueStore();
      ThemeRepository create() => ThemeRepository(
        api: offline,
        store: store,
        systemColors: FakeSystemColors(0xFF3366CC),
      );
      final repo = create();
      await repo.restore(server: testServer());
      expect(repo.useWallpaper, isFalse);
      await repo.setWallpaper(testServer(), enabled: true);
      expect(repo.wallpaperSeed, 0xFF3366CC);

      final restored = create();
      await restored.restore(server: testServer());
      expect(restored.useWallpaper, isTrue);
      await restored.refresh(other);
      expect(restored.useWallpaper, isFalse, reason: 'another server');

      await repo.clear();
      final afterSignOut = create();
      await afterSignOut.restore(server: testServer());
      expect(afterSignOut.useWallpaper, isFalse);
    });

    test('the wallpaper theme keeps the status colours', () {
      final light = AppTheme.wallpaper(
        const Color(0xFF3366CC),
        Brightness.light,
      );
      final dark = AppTheme.wallpaper(const Color(0xFF3366CC), Brightness.dark);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.colorScheme.primary, isNot(AppTheme.accentTextLight));
      expect(
        light.extension<StatusColors>(),
        AppTheme.light.extension<StatusColors>(),
      );
      expect(
        dark.extension<StatusColors>(),
        AppTheme.dark.extension<StatusColors>(),
      );
    });
  });
}
