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
