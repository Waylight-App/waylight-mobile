import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/sized_grid.dart';

/// Builds the view of one widget on the dashboard.
typedef PlacementBuilder = Widget Function(
  BuildContext context,
  WidgetPlacement widget,
);

/// Widgets with a size, laid out on a [SizedGrid] like a phone's home
/// screen (#208, docs/design: *Home screen as a grid of sizes*).
///
/// Each tile
/// shows the widget's view in a box of the tile's size; content that does
/// not fit fades out, and tapping the tile calls [onOpen] to show it in
/// full.
class WidgetGrid extends StatelessWidget {
  /// Creates the grid for [items], [columns] cells wide.
  const WidgetGrid({
    required this.items,
    required this.columns,
    required this.builder,
    required this.onOpen,
    this.onArrange,
    super.key,
  });

  /// The widgets and their sizes, in display order.
  final List<({WidgetPlacement widget, WidgetSize size})> items;

  /// The width of the grid in cells: 4 on phones, 8 on tablets.
  final int columns;

  /// Builds the view of a widget.
  final PlacementBuilder builder;

  /// Shows a widget in full.
  final ValueChanged<WidgetPlacement> onOpen;

  /// Opens the edit mode of the tab (#209); `null` where the tab cannot be
  /// changed.
  final VoidCallback? onArrange;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final item in items) item.widget.id: item};
    return SizedGrid(
      items: [for (final item in items) (id: item.widget.id, size: item.size)],
      columns: columns,
      tileBuilder: (context, tile, size) {
        final item = byId[tile.id]!;
        return WidgetTile(
          size: item.size,
          title: item.widget.displayTitle,
          height: size.height,
          onOpen: () => onOpen(item.widget),
          onLongPress: onArrange,
          builder: (context) => builder(context, item.widget),
        );
      },
    );
  }
}

/// One tile of the [WidgetGrid]: the widget's view in a box of [height],
/// faded out at the bottom when it is taller, opened in full on tap.
///
/// The view is built below the [WidgetSizeScope], so [builder] sees the
/// tile's size.
class WidgetTile extends StatefulWidget {
  /// Creates the tile for the view [builder] builds.
  const WidgetTile({
    required this.size,
    required this.title,
    required this.height,
    required this.onOpen,
    required this.builder,
    this.onLongPress,
    super.key,
  });

  /// The size of the tile, passed on in a [WidgetSizeScope].
  final WidgetSize size;

  /// The widget's title, for screen readers.
  final String title;

  /// The height of the tile in logical pixels.
  final double height;

  /// Shows the widget in full.
  final VoidCallback onOpen;

  /// Opens the edit mode, e.g. when the tile is held (#209).
  final VoidCallback? onLongPress;

  /// Builds the widget's view.
  final WidgetBuilder builder;

  @override
  State<WidgetTile> createState() => _WidgetTileState();
}

class _WidgetTileState extends State<WidgetTile> {
  bool _overflows = false;

  // The view is laid out at its natural height in a scroll view that the
  // user cannot scroll; its metrics tell whether it is taller than the tile.
  bool _onMetrics(ScrollMetricsNotification notification) {
    final overflows = notification.metrics.maxScrollExtent > 0.5;
    if (overflows != _overflows) setState(() => _overflows = overflows);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        primary: false,
        child: ConstrainedBox(
          // Cards fill the tile, so short content does not leave a gap.
          constraints: BoxConstraints(minHeight: widget.height),
          child: WidgetSizeScope(
            size: widget.size,
            child: Builder(builder: widget.builder),
          ),
        ),
      ),
    );
    if (_overflows) {
      // Only the alpha of the mask matters (dstIn).
      final opaque = Theme.of(context).colorScheme.onSurface;
      content = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [opaque, opaque, opaque.withValues(alpha: 0)],
          stops: const [0, 0.8, 1],
        ).createShader(bounds),
        child: content,
      );
    }
    return Semantics(
      container: true,
      label: widget.title,
      onTap: widget.onOpen,
      onTapHint: context.l10n.dashboardOpenWidget,
      child: GestureDetector(
        // Buttons inside the widget win their taps; the rest of the tile
        // opens the widget in full.
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTap: widget.onOpen,
        onLongPress: widget.onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          child: content,
        ),
      ),
    );
  }
}
