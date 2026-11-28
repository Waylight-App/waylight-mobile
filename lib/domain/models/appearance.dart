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

/// How much larger the account wants the text, on top of the system's
/// text size (`textSize` of `GET /api/appearance`, #291).
enum TextSize {
  /// The system's size.
  normal(1),

  /// A step larger.
  large(1.15),

  /// Two steps larger.
  larger(1.3);

  const TextSize(this.factor);

  /// What the text is multiplied by.
  final double factor;

  /// Reads the server's value; anything unknown counts as [normal].
  static TextSize parse(Object? value) =>
      values.where((s) => s.name == value).firstOrNull ?? normal;
}

/// The accessibility options of the account, the same as in the web
/// interface (#291).
final class Accessibility {
  /// Creates the options.
  const Accessibility({
    this.textSize = TextSize.normal,
    this.highContrast = false,
    this.simpleView = false,
  });

  /// Reads the options of `GET /api/appearance`; a server without them
  /// leaves everything off.
  factory Accessibility.fromJson(Map<String, Object?> json) => Accessibility(
    textSize: TextSize.parse(json['textSize']),
    highContrast: json['highContrast'] == true,
    simpleView: json['simpleView'] == true,
  );

  /// Text size on top of the system's.
  final TextSize textSize;

  /// Black on white or white on black, with strong outlines.
  final bool highContrast;

  /// One column of compact views, without edit controls.
  final bool simpleView;

  /// A copy with the given values replaced.
  Accessibility copyWith({
    TextSize? textSize,
    bool? highContrast,
    bool? simpleView,
  }) => Accessibility(
    textSize: textSize ?? this.textSize,
    highContrast: highContrast ?? this.highContrast,
    simpleView: simpleView ?? this.simpleView,
  );

  /// The options as the server sends them.
  Map<String, Object?> toJson() => {
    'textSize': textSize.name,
    'highContrast': highContrast,
    'simpleView': simpleView,
  };

  @override
  bool operator ==(Object other) =>
      other is Accessibility &&
      other.textSize == textSize &&
      other.highContrast == highContrast &&
      other.simpleView == simpleView;

  @override
  int get hashCode => Object.hash(textSize, highContrast, simpleView);
}
