import 'package:material_ui/material_ui.dart';

/// The Material 3 themes of the app.
///
/// Derived from the accent colour of the Waylight web interface
/// (`--color-accent` in `web/src/shared/theme/tokens.css` of the server), so
/// app and web look like one product.
abstract final class AppTheme {
  /// The Waylight accent colour.
  static const Color seed = Color(0xFF3365E8);

  /// The theme in light mode.
  static ThemeData get light => _theme(Brightness.light);

  /// The theme in dark mode.
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colors,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
