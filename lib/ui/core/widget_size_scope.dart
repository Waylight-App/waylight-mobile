import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';

/// Tells a widget's view the size of the tile it is shown in (#208).
///
/// The dashboard grid puts every sized widget into a scope. Views that
/// have a compact form read it with [WidgetSizeScope.maybeOf] and show
/// what fits (#211); everything else stays one tap away in the full view.
/// Outside the grid — in a list, in the full view — there is no scope.
class WidgetSizeScope extends InheritedWidget {
  /// Puts [child] into a tile of [size].
  const WidgetSizeScope({
    required this.size,
    required super.child,
    this.height,
    super.key,
  });

  /// The size of the tile.
  final WidgetSize size;

  /// The height of the tile in logical pixels, where the grid knows it.
  final double? height;

  /// The size of the tile around [context], or `null` outside the grid.
  static WidgetSize? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WidgetSizeScope>()?.size;

  /// Whether [context] is in a tile of the dashboard grid.
  static bool inGrid(BuildContext context) => maybeOf(context) != null;

  /// The height of the tile around [context], or `null` outside the grid.
  static double? maybeHeightOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WidgetSizeScope>()?.height;

  @override
  bool updateShouldNotify(WidgetSizeScope oldWidget) =>
      size != oldWidget.size || height != oldWidget.height;
}
