import 'package:material_ui/material_ui.dart';

/// Colours of the rain radar (#176). The DWD radar is drawn for a dark map,
/// so the widget keeps the dark background of the web widget in both modes.
abstract final class RadarColors {
  /// Behind the radar picture.
  static const background = Color(0xFF1F2937);

  /// The credit below the picture.
  static const caption = Color(0xFFE5E7EB);

  /// The dot that marks the widget's place.
  static const marker = Color(0xFFEF4444);

  /// The ring around the dot.
  static const markerRing = Color(0xFFFFFFFF);
}
