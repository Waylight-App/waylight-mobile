import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// Builds one tile of a [SizedGrid], given its place and its size in
/// logical pixels.
typedef SizedGridTileBuilder = Widget Function(
  BuildContext context,
  GridPlace tile,
  Size size,
);

/// Items of different [WidgetSize]s on a grid of square cells, like the
/// widgets of a phone's home screen (#208).
///
/// The items keep their order and fill gaps ([packGrid]). Used by the
/// dashboard and by its edit mode, so both lay widgets out the same way.
///
/// ```dart
/// SizedGrid(
///   items: [(id: 'clock', size: WidgetSize.small)],
///   columns: 4,
///   tileBuilder: (context, tile, size) => ClockTile(size: size),
/// )
/// ```
class SizedGrid extends StatelessWidget {
  /// Creates the grid, [columns] cells wide.
  const SizedGrid({
    required this.items,
    required this.columns,
    required this.tileBuilder,
    this.animate = false,
    super.key,
  });

  /// The items and their sizes, in display order.
  final List<({String id, WidgetSize size})> items;

  /// The width of the grid in cells: 4 on phones, 8 on tablets.
  final int columns;

  /// Builds the tile of an item.
  final SizedGridTileBuilder tileBuilder;

  /// Whether tiles glide to their new place when the items change, e.g.
  /// while one is dragged in the edit mode.
  final bool animate;

  /// The width of the grid in cells for the screen [context] is shown on.
  static int columnsOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600 ? 4 : 8;

  @override
  Widget build(BuildContext context) {
    final tiles = packGrid(items, columns: columns);
    final rows = tiles.fold(0, (rows, t) => max(rows, t.row + t.rows));
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = Dimens.gapCard;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        double extent(int cells) => cells * cell + (cells - 1) * gap;
        return SizedBox(
          height: rows == 0 ? 0 : extent(rows),
          child: Stack(
            children: [
              for (final tile in tiles)
                AnimatedPositioned(
                  key: ValueKey('grid.${tile.id}'),
                  duration: animate && !MediaQuery.disableAnimationsOf(context)
                      ? const Duration(milliseconds: 200)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  left: tile.column * (cell + gap),
                  top: tile.row * (cell + gap),
                  width: extent(tile.columns),
                  height: extent(tile.rows),
                  child: tileBuilder(
                    context,
                    tile,
                    Size(extent(tile.columns), extent(tile.rows)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
