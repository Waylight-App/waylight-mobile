/// The look of the app, chosen on the device (#14).
final class Appearance {
  /// Creates the appearance.
  const Appearance({
    this.theme = ThemeChoice.system,
    this.language = AppLanguage.system,
  });

  /// Light, dark or as the system.
  final ThemeChoice theme;

  /// The language of the texts.
  final AppLanguage language;

  /// A copy with the given values replaced.
  Appearance copyWith({ThemeChoice? theme, AppLanguage? language}) =>
      Appearance(
        theme: theme ?? this.theme,
        language: language ?? this.language,
      );

  @override
  bool operator ==(Object other) =>
      other is Appearance && other.theme == theme && other.language == language;

  @override
  int get hashCode => Object.hash(theme, language);
}

/// Light or dark.
enum ThemeChoice {
  /// As the system.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// The language of the app.
enum AppLanguage {
  /// As the system.
  system,

  /// English.
  en,

  /// German.
  de,
}

/// The colours of the account's theme in the web interface (#157), read
/// from its CSS variables.
final class ThemePalette {
  /// Creates the palette.
  const ThemePalette({
    required this.accent,
    required this.onAccent,
    required this.light,
    required this.dark,
  });

  /// The accent (`--color-accent`), the surface of filled buttons.
  final int accent;

  /// Text on the accent (`--color-accent-contrast`).
  final int onAccent;

  /// The colours in light mode.
  final ThemeColors light;

  /// The colours in dark mode.
  final ThemeColors dark;
}

/// The colours of one mode of a [ThemePalette], as ARGB integers.
final class ThemeColors {
  /// Creates the colours.
  const ThemeColors({
    required this.accentText,
    required this.background,
    required this.surface,
    required this.text,
  });

  /// Accent for text and icons (`--color-accent-text`).
  final int accentText;

  /// The page (`--color-bg`).
  final int background;

  /// Cards (`--color-surface`).
  final int surface;

  /// Text (`--color-text`).
  final int text;
}
