import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';

/// The rows of a list in the normal view, cut to what fits the tile (#211).
///
/// A tile shows as many whole rows as its height allows, so a large tile
/// shows more than a medium one; when rows are left out the last line says
/// how many. Larger text sizes show fewer rows, never cut-off ones.
/// Outside the grid — in the full view, in a sheet — every row is shown.
///
/// ```dart
/// TileRows(
///   items: todos,
///   rowHeight: Dimens.tapTarget,
///   rowBuilder: (context, todo) => InfoRow(title: todo.title),
/// )
/// ```
class TileRows<T> extends StatelessWidget {
  /// Creates the rows of [items], each built by [rowBuilder] and about
  /// [rowHeight] high at normal text size.
  const TileRows({
    required this.items,
    required this.rowHeight,
    required this.rowBuilder,
    this.reserved = 0,
    this.minRows = 1,
    super.key,
  });

  /// All rows in order.
  final List<T> items;

  /// The height of one row at normal text size.
  final double rowHeight;

  /// Builds the row of one item.
  final Widget Function(BuildContext context, T item) rowBuilder;

  /// The height, at normal text size, of what the widget shows above or
  /// below the rows.
  final double reserved;

  /// The fewest rows shown; 0 where the rows are extra and may give way
  /// completely.
  final int minRows;

  /// The height of a row with one line of text.
  static const lineRowHeight = 32.0;

  /// The height of a row with a second, smaller line.
  static const twoLineRowHeight = 56.0;

  /// The height of the card around the content at normal text size: its
  /// padding and the gap below the title, and the title, which grows with
  /// the text.
  static const _padding = 40.0;
  static const _title = 28.0;

  /// The height of the line that counts the hidden rows.
  static const _moreHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    final tile = WidgetSizeScope.maybeHeightOf(context);
    if (tile == null) return _column(context, items, hidden: 0);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final factor = scale < 1 ? 1.0 : scale;
    final room = tile - _padding - (_title + reserved) * factor;
    final perRow = rowHeight * factor;
    if (items.length <= (room / perRow).floor()) {
      return _column(context, items, hidden: 0);
    }
    final withCount = ((room - _moreHeight * factor) / perRow).floor();
    if (withCount >= minRows) {
      return _column(
        context,
        items.take(withCount).toList(),
        hidden: items.length - withCount,
      );
    }
    // No room for the count: only the rows that fit, without it.
    final plain = (room / perRow).floor().clamp(minRows, items.length);
    return _column(context, items.take(plain).toList(), hidden: 0);
  }

  Widget _column(BuildContext context, List<T> rows, {required int hidden}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in rows) rowBuilder(context, item),
        if (hidden > 0)
          Text(
            context.l10n.tileMoreRows(hidden),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
