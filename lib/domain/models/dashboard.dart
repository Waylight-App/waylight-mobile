/// The tabs of the signed-in account, as the server gives them: guests and
/// members only get the tabs they may see.
final class Dashboard {
  /// Creates the dashboard.
  const Dashboard({required this.tabs, this.defaultTabId = ''});

  /// The tabs in the order of the web interface.
  final List<DashboardTab> tabs;

  /// The tab to open first; empty for the first tab.
  final String defaultTabId;

  /// The index of the tab to open first.
  int get initialIndex {
    final index = tabs.indexWhere((t) => t.id == defaultTabId);
    return index < 0 ? 0 : index;
  }
}

/// One tab of the dashboard with its widgets in phone order.
final class DashboardTab {
  /// Creates the tab.
  const DashboardTab({
    required this.id,
    required this.name,
    required this.widgets,
    this.layout = const [],
    this.mine = true,
    this.sizes = const {},
    this.sizesOnServer = false,
  });

  /// The server's id of the tab.
  final String id;

  /// The name the user gave the tab.
  final String name;

  /// The visible widgets, top to bottom.
  final List<WidgetPlacement> widgets;

  /// The phone layout with hidden widgets too, in display order (#53).
  final List<PhoneLayoutItem> layout;

  /// Whether the tab belongs to the account; team tabs shared with it are
  /// read-only.
  final bool mine;

  /// The size of each widget in the grid by widget id (#208); widgets
  /// without one take the full width at their natural height.
  final Map<String, WidgetSize> sizes;

  /// Whether the server stores sizes in its phone layout
  /// (Waylight-App/waylight#585); otherwise the app keeps them on the
  /// device.
  final bool sizesOnServer;

  /// A copy of the tab with [sizes] for its widgets, in [layout] too.
  DashboardTab withSizes(Map<String, WidgetSize> sizes) => DashboardTab(
    id: id,
    name: name,
    widgets: widgets,
    layout: [for (final item in layout) item.withSize(sizes[item.widget.id])],
    mine: mine,
    sizes: Map.unmodifiable(sizes),
    sizesOnServer: sizesOnServer,
  );
}

/// The size of a widget in the dashboard grid (#208), in cells of a grid
/// that is four cells wide on phones: like the widgets of a phone's home
/// screen.
enum WidgetSize {
  /// Half the width of a phone, square: 2 × 2 cells.
  small(2, 2),

  /// The full width of a phone, half as high: 4 × 2 cells.
  medium(4, 2),

  /// The full width of a phone, square: 4 × 4 cells.
  large(4, 4),

  /// The full width of a phone, one cell high: 4 × 1 cells.
  strip(4, 1);

  const WidgetSize(this.columns, this.rows);

  /// The width in cells.
  final int columns;

  /// The height in cells.
  final int rows;

  /// The size named [name] (`small` …), or `null` for anything else, such
  /// as the empty string for "no size".
  static WidgetSize? parse(Object? name) =>
      values.where((size) => size.name == name).firstOrNull;
}

/// A widget's place in the grid: its top left cell and its span (#208).
typedef GridPlace = ({String id, int column, int row, int columns, int rows});

/// Places widgets of the given sizes on a grid [columns] cells wide.
///
/// The widgets keep their order, row by row from the top left; each takes
/// the first place where it fits, so a later small widget fills a gap left
/// by a wider one (dense packing, as on a phone's home screen). Widgets
/// wider than the grid are narrowed to its width.
List<GridPlace> packGrid(
  List<({String id, WidgetSize size})> items, {
  required int columns,
}) {
  assert(columns > 0, 'A grid needs at least one column.');
  final taken = <List<bool>>[];
  bool isFree(int row, int column, int width, int height) {
    for (var r = row; r < row + height; r++) {
      if (r >= taken.length) return true;
      for (var c = column; c < column + width; c++) {
        if (taken[r][c]) return false;
      }
    }
    return true;
  }

  final tiles = <GridPlace>[];
  for (final item in items) {
    final width = item.size.columns.clamp(1, columns);
    final height = item.size.rows;
    for (var row = 0; ; row++) {
      final column = [for (var c = 0; c + width <= columns; c++) c]
          .where((c) => isFree(row, c, width, height))
          .firstOrNull;
      if (column == null) continue;
      while (taken.length < row + height) {
        taken.add(List.filled(columns, false));
      }
      for (var r = row; r < row + height; r++) {
        for (var c = column; c < column + width; c++) {
          taken[r][c] = true;
        }
      }
      tiles.add((
        id: item.id,
        column: column,
        row: row,
        columns: width,
        rows: height,
      ));
      break;
    }
  }
  return tiles;
}

/// A widget's place in the phone layout of a tab (#53).
final class PhoneLayoutItem {
  /// Creates the item.
  const PhoneLayoutItem({
    required this.widget,
    this.hidden = false,
    this.rows = 1,
    this.size,
  });

  /// The widget.
  final WidgetPlacement widget;

  /// Whether it is hidden on phones.
  final bool hidden;

  /// The minimum height in grid rows, kept as the web interface set it.
  final int rows;

  /// The size in the dashboard grid, or `null` for the full width at the
  /// widget's natural height (#208).
  final WidgetSize? size;

  /// A copy with [hidden] changed.
  PhoneLayoutItem copyWith({bool? hidden}) => PhoneLayoutItem(
    widget: widget,
    hidden: hidden ?? this.hidden,
    rows: rows,
    size: size,
  );

  /// A copy with [size] instead of the current size; `null` removes it.
  PhoneLayoutItem withSize(WidgetSize? size) =>
      PhoneLayoutItem(widget: widget, hidden: hidden, rows: rows, size: size);
}

/// A widget on a tab: what it is and how it is configured.
final class WidgetPlacement {
  /// Creates the placement.
  const WidgetPlacement({
    required this.id,
    required this.kind,
    this.title = '',
    this.config = const {},
  });

  /// The server's id of the widget.
  final String id;

  /// The widget kind, such as `clock` or `transit`; picks the renderer.
  final String kind;

  /// The title the user gave the widget, or empty.
  final String title;

  /// The widget's configuration as the server stores it.
  final Map<String, Object?> config;

  /// The title to show: the user's, else the kind in words, e.g.
  /// `status-overview` → "Status overview".
  String get displayTitle {
    if (title.isNotEmpty) return title;
    final words = kind.replaceAll(RegExp('[-_]+'), ' ').trim();
    if (words.isEmpty) return kind;
    return words[0].toUpperCase() + words.substring(1);
  }
}

/// A widget's place in the desktop grid, for [phoneOrder].
typedef GridPosition = ({String id, int x, int y});

/// A widget's entry in the phone layout of the server.
typedef PhoneItem = ({String id, bool hidden});

/// The ids of a tab's widgets in the order a phone shows them.
///
/// The server sends the phone layout in display order, also while it still
/// follows the desktop grid; hidden widgets are left out. Without a phone
/// layout (older servers) the grid is read row by row, left to right.
List<String> phoneOrder(List<GridPosition> grid, List<PhoneItem> phone) {
  final known = {for (final g in grid) g.id};
  if (phone.isNotEmpty) {
    return [
      for (final item in phone)
        if (!item.hidden && known.contains(item.id)) item.id,
    ];
  }
  final sorted = [...grid]
    ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
  return [for (final g in sorted) g.id];
}
