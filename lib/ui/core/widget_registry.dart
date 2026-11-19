import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';

/// Builds the native view of one widget on a tab.
typedef DashboardWidgetBuilder = Widget Function(
  BuildContext context,
  WidgetPlacement widget,
);

/// Maps widget kinds to their native views (#61).
///
/// The dashboard asks the registry for each widget and falls back to its
/// card for kinds without a native view. The registry is filled in
/// `ui/widgets/registry.dart` and handed to the dashboard by the router, so
/// the dashboard and the widget features never import each other.
final class WidgetRegistry {
  /// Creates a registry with one builder per widget kind.
  const WidgetRegistry(this._builders);

  final Map<String, DashboardWidgetBuilder> _builders;

  /// The builder for [kind], or `null` if the kind has no native view.
  DashboardWidgetBuilder? builderFor(String kind) => _builders[kind];
}
