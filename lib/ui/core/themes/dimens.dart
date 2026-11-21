/// Spacing, sizes and corner radii: the layout tokens of the design system
/// (docs/ui-components.md#tokens).
///
/// Widgets use these names instead of numbers, so every screen keeps the
/// same rhythm and a change happens in one place.
abstract final class Dimens {
  /// Small gap, e.g. between a heading and its text.
  static const double gapSmall = 8;

  /// Gap between cards in a list or grid.
  static const double gapCard = 12;

  /// Default gap between elements, and the padding of a page.
  static const double gap = 16;

  /// Large gap, e.g. between the sections of a form.
  static const double gapLarge = 32;

  /// Minimum size of anything the user can tap (Material and WCAG).
  static const double tapTarget = 48;

  /// Size of a progress indicator inside a button.
  static const double inlineProgress = 20;

  /// Size of an icon next to text, e.g. in a banner.
  static const double iconSmall = 20;

  /// Size of the main icon of a widget, e.g. the weather now.
  static const double iconLarge = 40;

  /// Gap between the rows of a compact list, e.g. forecast days.
  static const double gapTiny = 4;

  /// Width of a short label column, e.g. the weekday of a forecast.
  static const double labelColumn = 48;

  /// Corner radius of cards.
  static const double radiusCard = 16;

  /// Corner radius of banners and small containers.
  static const double radiusBanner = 12;

  /// Corner radius of small framed content such as the radar picture.
  static const double radiusSmall = 8;

  /// Maximum width of forms on tablets and in landscape.
  static const double maxFormWidth = 480;

  /// Maximum width of list pages such as the settings on tablets and in
  /// landscape (#52).
  static const double maxPageWidth = 640;
}
