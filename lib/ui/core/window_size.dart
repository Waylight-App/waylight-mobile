import 'package:material_ui/material_ui.dart';

/// The width classes of Material 3, which decide how many columns a screen
/// uses (#52).
enum WindowSize {
  /// Phones in portrait: under 600 dp.
  compact,

  /// Small tablets and phones in landscape: 600–839 dp.
  medium,

  /// Tablets and larger: 840 dp and more.
  expanded;

  /// The class of [width] in logical pixels.
  static WindowSize ofWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : expanded;

  /// The class of the screen [context] is shown on.
  static WindowSize of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  /// How many columns of cards fit.
  int get columns => switch (this) {
    compact => 1,
    medium => 2,
    expanded => 3,
  };
}
