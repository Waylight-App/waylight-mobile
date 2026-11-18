import 'package:material_ui/material_ui.dart';

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

  /// The font family of the wordmark (bundled with #10; until then the
  /// platform's serif font is used).
  static const String wordmarkFont = 'Fraunces';

  /// The theme in light mode.
  static ThemeData get light => _theme(Brightness.light, StatusColors.light);

  /// The theme in dark mode.
  static ThemeData get dark => _theme(Brightness.dark, StatusColors.dark);

  static ThemeData _theme(Brightness brightness, StatusColors status) {
    // fidelity keeps the chroma of the seed instead of muting it
    // (tonalSpot). primary is used for text and icons, so it takes the
    // readable accent text of the web theme; Amber itself stays the surface
    // of filled buttons, with dark text on it in both modes.
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final light = brightness == Brightness.light;
    final colors = scheme.copyWith(
      primary: light ? accentTextLight : accentTextDark,
      onPrimary: light ? const Color(0xFFFFFFFF) : onSeed,
    );
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
                : seed,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: 0.38)
                : onSeed,
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
