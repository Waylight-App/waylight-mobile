import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';

/// Builds the native view of one widget on a tab.
typedef DashboardWidgetBuilder = Widget Function(
  BuildContext context,
  WidgetPlacement widget,
);

/// Builds the preview of a widget titled `title` in a tile of `size` from
/// example data (#251).
typedef WidgetPreviewBuilder = Widget Function(
  BuildContext context,
  String title,
  WidgetSize size,
);

/// Maps widget kinds to their native views (#61).
///
/// The dashboard asks the registry for each widget and falls back to its
/// card for kinds without a native view. The registry is filled in
/// `ui/widgets/registry.dart` and handed to the dashboard by the router, so
/// the dashboard and the widget features never import each other.
final class WidgetRegistry {
  /// Creates a registry with one builder per widget kind, and previews
  /// from example data for the kinds in `previews`.
  const WidgetRegistry(this._builders, {this._previews = const {}});

  final Map<String, DashboardWidgetBuilder> _builders;
  final Map<String, WidgetPreviewBuilder> _previews;

  /// The builder for [kind], or `null` if the kind has no native view.
  DashboardWidgetBuilder? builderFor(String kind) => _builders[kind];

  /// The preview of [kind] from example data, or `null` if it has none;
  /// the gallery then draws a schematic tile.
  WidgetPreviewBuilder? previewFor(String kind) => _previews[kind];
}
