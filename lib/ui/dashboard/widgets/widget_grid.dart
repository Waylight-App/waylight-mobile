import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_card.dart';
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
    this.onHold,
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

  /// Called when a tile is held: opens the edit mode of the tab (#209) or
  /// the menu of the widget (#289); `null` where there is nothing to do.
  final ValueChanged<WidgetPlacement>? onHold;

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
          onLongPress: onHold == null ? null : () => onHold!(item.widget),
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

  /// Runs when the tile is held, e.g. to open the edit mode (#209).
  final VoidCallback? onLongPress;

  /// Builds the widget's view.
  final WidgetBuilder builder;

  @override
  State<WidgetTile> createState() => WidgetTileState();
}

/// The state of a [WidgetTile]: whether its view is taller than the tile.
class WidgetTileState extends State<WidgetTile> {
  bool _overflows = false;

  /// Whether the view is taller than the tile and fades out at the bottom.
  @visibleForTesting
  bool get fades => _overflows;

  // The view is laid out at its natural height in a scroll view that the
  // user cannot scroll; its metrics tell whether it is taller than the tile.
  bool _onMetrics(ScrollMetricsNotification notification) {
    final overflows = notification.metrics.maxScrollExtent > 0.5;
    if (overflows != _overflows) setState(() => _overflows = overflows);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Only the alpha of the mask matters (dstIn).
    final opaque = Theme.of(context).colorScheme.onSurface;
    // The mask is always part of the tree and only its gradient changes:
    // wrapping the view only while it overflows would rebuild the view,
    // which then reloads, gets shorter, unwraps and flickers in a loop.
    final content = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          opaque,
          opaque,
          if (_overflows) opaque.withValues(alpha: 0) else opaque,
        ],
        stops: const [0, 0.8, 1],
      ).createShader(bounds),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          primary: false,
          child: ConstrainedBox(
            // Cards fill the tile, so short content does not leave a gap.
            constraints: BoxConstraints(minHeight: widget.height),
            child: WidgetSizeScope(
              size: widget.size,
              height: widget.height,
              child: Builder(builder: widget.builder),
            ),
          ),
        ),
      ),
    );
    final l10n = context.l10n;
    return Semantics(
      container: true,
      button: true,
      label: widget.title,
      onTap: widget.onOpen,
      // Small tiles open a detail sheet (#226), larger ones the full view.
      onTapHint: isCompact(widget.size)
          ? l10n.dashboardOpenDetails
          : l10n.dashboardOpenWidget,
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
