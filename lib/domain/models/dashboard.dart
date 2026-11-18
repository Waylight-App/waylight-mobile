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
  });

  /// The server's id of the tab.
  final String id;

  /// The name the user gave the tab.
  final String name;

  /// The visible widgets, top to bottom.
  final List<WidgetPlacement> widgets;
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
