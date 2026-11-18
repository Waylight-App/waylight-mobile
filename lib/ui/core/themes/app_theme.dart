import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';

/// The Material 3 themes of the app (docs/design/README.md).
///
/// Colours come from the accent of the Waylight web interface
/// (`--color-accent` in `web/src/shared/theme/tokens.css` of the server).
/// The component themes give every button, field and card its look, so
/// screens use plain Material widgets and stay free of styling.
abstract final class AppTheme {
  /// The Waylight accent colour.
  static const Color seed = Color(0xFF3365E8);

  /// The font family of the wordmark (bundled with #10; until then the
  /// platform's serif font is used).
  static const String wordmarkFont = 'Fraunces';

  /// The theme in light mode.
  static ThemeData get light => _theme(Brightness.light, StatusColors.light);

  /// The theme in dark mode.
  static ThemeData get dark => _theme(Brightness.dark, StatusColors.dark);

  static ThemeData _theme(Brightness brightness, StatusColors status) {
    // fidelity keeps the chroma of the seed instead of muting it
    // (tonalSpot). In light mode the seed itself is the primary colour, as
    // on the web: white text on it has a contrast of 5.0:1.
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final colors = brightness == Brightness.light
        ? scheme.copyWith(primary: seed, onPrimary: const Color(0xFFFFFFFF))
        : scheme;
    const buttonSize = Size(64, Dimens.tapTarget);
    return ThemeData(
      colorScheme: colors,
      extensions: [status],
      appBarTheme: const AppBarTheme(centerTitle: false),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(buttonSize)),
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
