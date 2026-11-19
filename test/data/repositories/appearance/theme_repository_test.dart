import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';

import '../../../testing/fakes/fake_server_repository.dart';
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
}
