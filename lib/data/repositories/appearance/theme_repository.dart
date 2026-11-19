import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The account's theme from the web interface (#157). The last palette is
/// kept on the device, so the app starts in it without the network.
class ThemeRepository extends ChangeNotifier {
  /// Creates the repository.
  ThemeRepository({required this._api, required this._store});

  final ModuleApi _api;
  final KeyValueStore _store;

  static const _key = 'theme.palette';

  ThemePalette? _palette;

  /// The palette, or `null` for the app's own Amber.
  ThemePalette? get palette => _palette;

  /// Reads the palette kept on the device.
  Future<void> restore() async {
    final stored = await _store.read(_key);
    if (stored == null) return;
    _palette = paletteFromCss(stored);
    notifyListeners();
  }

  /// Reads the account's theme from [server]; a failure keeps the current
  /// palette.
  Future<void> refresh(ServerAddress server) async {
    final result = await _api.read(server, '/api/appearance', (json) {
      if (json case {'customCss': final String css}) return css;
      return '';
    });
    if (result case Ok(:final value)) {
      final palette = paletteFromCss(value);
      if (palette == null) {
        await _store.delete(_key);
      } else {
        await _store.write(_key, value);
      }
      _palette = palette;
      notifyListeners();
    }
  }

  /// Forgets the palette, e.g. when signing out.
  Future<void> clear() async {
    _palette = null;
    await _store.delete(_key);
    notifyListeners();
  }
}

/// Reads the palette from a theme's CSS: the variables of the first block
/// are light mode, the block for `data-theme='dark'` overrides them for
/// dark mode. `null` when the CSS sets no accent, i.e. no theme.
ThemePalette? paletteFromCss(String css) {
  final blocks = RegExp(r'([^{}]+)\{([^}]*)\}').allMatches(css);
  final light = <String, int>{};
  final dark = <String, int>{};
  for (final b in blocks) {
    final isDark = b[1]!.contains("'dark'") || b[1]!.contains('"dark"');
    for (final v in RegExp(
      r'--(color-[a-z0-9-]+)\s*:\s*(#[0-9a-fA-F]{3,8})',
    ).allMatches(b[2]!)) {
      final color = _hex(v[2]!);
      if (color != null) (isDark ? dark : light)[v[1]!] = color;
    }
  }
  final accent = light['color-accent'];
  if (accent == null) return null;
  ThemeColors mode(Map<String, int> m, ThemeColors fallback) => ThemeColors(
    accentText: m['color-accent-text'] ?? fallback.accentText,
    background: m['color-bg'] ?? fallback.background,
    surface: m['color-surface'] ?? fallback.surface,
    text: m['color-text'] ?? fallback.text,
  );
  final lightColors = mode(
    light,
    ThemeColors(
      accentText: accent,
      background: 0xFFFFFFFF,
      surface: 0xFFFFFFFF,
      text: 0xFF000000,
    ),
  );
  return ThemePalette(
    accent: accent,
    onAccent: light['color-accent-contrast'] ?? 0xFF000000,
    light: lightColors,
    dark: mode(
      {...light, ...dark},
      ThemeColors(
        accentText: accent,
        background: 0xFF121212,
        surface: 0xFF1E1E1E,
        text: 0xFFFFFFFF,
      ),
    ),
  );
}

int? _hex(String hex) {
  var h = hex.substring(1);
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  if (h.length == 6) h = 'FF$h';
  if (h.length == 8 && hex.length == 9) {
    // CSS writes the alpha last, Flutter first.
    h = '${h.substring(6)}${h.substring(0, 6)}';
  }
  return int.tryParse(h, radix: 16);
}
