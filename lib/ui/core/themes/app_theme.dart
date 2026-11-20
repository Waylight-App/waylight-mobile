import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/appearance.dart';

import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';

/// The Material 3 themes of the app (docs/design/README.md).
///
/// Colours come from Amber, the default theme of the Waylight web interface
/// (`internal/modules/appearance/adapter/gateway/themes/amber.json` of the
/// server).
/// The component themes give every button, field and card its look, so
/// screens use plain Material widgets and stay free of styling.
abstract final class AppTheme {
  /// The Amber accent: the surface of filled buttons, and the seed of the
  /// colour scheme.
  static const Color seed = Color(0xFFF2B441);

  /// Text and icons on the accent (`--color-accent-contrast`).
  static const Color onSeed = Color(0xFF1A1206);

  /// Accent for text, icons and focus on light backgrounds
  /// (`--color-accent-text`). Amber itself is too light for text there.
  static const Color accentTextLight = Color(0xFF9C5D00);

  /// Accent for text, icons and focus on dark backgrounds.
  static const Color accentTextDark = Color(0xFFFFD27A);

  /// The font family of the wordmark, bundled in `assets/fonts` (#10).
  static const String wordmarkFont = 'Fraunces';

  /// The theme in light mode.
  static ThemeData get light => lightFor(null);

  /// The theme in dark mode.
  static ThemeData get dark => darkFor(null);

  /// The light theme in the account's [palette] (#157), or Amber.
  static ThemeData lightFor(ThemePalette? palette) =>
      _theme(Brightness.light, StatusColors.light, palette);

  /// The dark theme in the account's [palette] (#157), or Amber.
  static ThemeData darkFor(ThemePalette? palette) =>
      _theme(Brightness.dark, StatusColors.dark, palette);

  /// A theme in the wallpaper colours (#198): the whole scheme comes from
  /// the system's [seed] (tonalSpot, as Android's own apps), only the status
  /// colours stay the app's, so warnings and successes keep their meaning.
  static ThemeData wallpaper(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return _build(
      scheme,
      brightness == Brightness.light ? StatusColors.light : StatusColors.dark,
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
    );
  }

  static ThemeData _theme(
    Brightness brightness,
    StatusColors status,
    ThemePalette? palette,
  ) {
    final accent = palette == null ? seed : Color(palette.accent);
    final onAccent = palette == null ? onSeed : Color(palette.onAccent);
    // fidelity keeps the chroma of the seed instead of muting it
    // (tonalSpot). primary is used for text and icons, so it takes the
    // readable accent text of the web theme; Amber itself stays the surface
    // of filled buttons, with dark text on it in both modes.
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final light = brightness == Brightness.light;
    final mode = palette == null
        ? null
        : (light ? palette.light : palette.dark);
    var colors = scheme.copyWith(
      primary: light ? accentTextLight : accentTextDark,
      onPrimary: light ? const Color(0xFFFFFFFF) : onSeed,
    );
    if (mode != null) {
      // The web theme's own colours; the seed above fills in the rest.
      colors = colors.copyWith(
        primary: Color(mode.accentText),
        onPrimary: light ? const Color(0xFFFFFFFF) : onAccent,
        surface: Color(mode.background),
        surfaceContainer: Color(mode.surface),
        onSurface: Color(mode.text),
      );
    }
    return _build(colors, status, accent: accent, onAccent: onAccent);
  }

  static ThemeData _build(
    ColorScheme colors,
    StatusColors status, {
    required Color accent,
    required Color onAccent,
  }) {
    const buttonSize = Size(64, Dimens.tapTarget);
    return ThemeData(
      colorScheme: colors,
      extensions: [status],
      appBarTheme: const AppBarTheme(centerTitle: false),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: 0.12)
                : accent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: 0.38)
                : onAccent,
          ),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(buttonSize)),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(buttonSize)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusCard)),
        ),
      ),
    );
  }
}
