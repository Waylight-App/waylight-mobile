import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The tab could not be found, or it is a team tab the account may not
/// change.
final class TabNotEditable implements Exception {
  /// Creates the exception.
  const TabNotEditable();
}

/// The edit mode of a tab (#209): order, hidden widgets and sizes (#208)
/// of its phone layout, saved together; or a reset to the desktop grid.
class EditTabViewModel extends ChangeNotifier {
  /// Creates the view model for [tabId] and loads the tab.
  EditTabViewModel({
    required this.tabId,
    required this._serverRepository,
    required this._dashboardRepository,
  }) {
    load = Command0(_load)..execute().ignore();
    save = Command0(_save);
    reset = Command0(_reset);
  }

  /// The tab being edited.
  final String tabId;
  final ServerRepository _serverRepository;
  final DashboardRepository _dashboardRepository;

  List<PhoneLayoutItem> _items = const [];
  String _name = '';

  /// Loads the tab.
  late final Command0<void> load;

  /// Stores the layout.
  late final Command0<void> save;

  /// Lets the layout follow the desktop grid again.
  late final Command0<void> reset;

  /// The widgets in their phone order, hidden ones included.
  List<PhoneLayoutItem> get items => _items;

  /// The name of the tab.
  String get name => _name;

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _dashboardRepository.dashboard(server);
    switch (result) {
      case Ok(:final value):
        final tab = value.tabs
            .where((t) => t.id == tabId && t.mine)
            .firstOrNull;
        if (tab == null) return const Result.error(TabNotEditable());
        _items = List.unmodifiable(tab.layout);
        _name = tab.name;
        _changed = false;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Whether the layout differs from the one on the server.
  bool get changed => _changed;
  bool _changed = false;

  /// The widgets shown on phones, in their order.
  List<PhoneLayoutItem> get visible => [
    for (final item in _items)
      if (!item.hidden) item,
  ];

  /// The widgets hidden on phones.
  List<PhoneLayoutItem> get hidden => [
    for (final item in _items)
      if (item.hidden) item,
  ];

  int _indexOf(String id) => _items.indexWhere((i) => i.widget.id == id);

  void _update(List<PhoneLayoutItem> items) {
    _items = List.unmodifiable(items);
    _changed = true;
    notifyListeners();
  }

  /// Moves widget [id] to the place of widget [targetId], as when it is
  /// dragged onto it: before it when moving up, after it when moving down.
  void moveOnto(String id, String targetId) {
    final from = _indexOf(id);
    final to = _indexOf(targetId);
    if (from < 0 || to < 0 || from == to) return;
    final list = [..._items];
    final item = list.removeAt(from);
    list.insert(to, item);
    _update(list);
  }

  /// Moves widget [id] one place earlier (`-1`) or later (`1`) among the
  /// visible widgets, for screen readers and keyboards.
  void moveBy(String id, int delta) {
    final shown = visible;
    final index = shown.indexWhere((i) => i.widget.id == id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= shown.length) return;
    moveOnto(id, shown[target].widget.id);
  }

  /// Hides widget [id] on phones; it stays on the desktop.
  void hide(String id) => _setHidden(id, hidden: true);

  /// Shows widget [id] on phones again.
  void showAgain(String id) => _setHidden(id, hidden: false);

  void _setHidden(String id, {required bool hidden}) {
    final index = _indexOf(id);
    if (index < 0 || _items[index].hidden == hidden) return;
    final list = [..._items];
    list[index] = list[index].copyWith(hidden: hidden);
    _update(list);
  }

  /// Sets the grid size of widget [id]; `null` shows it at the full width
  /// and its natural height (#208).
  void setSize(String id, WidgetSize? size) {
    final index = _indexOf(id);
    if (index < 0 || _items[index].size == size) return;
    final list = [..._items];
    list[index] = list[index].withSize(size);
    _update(list);
  }

  Future<Result<void>> _save() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _dashboardRepository.saveLayout(server, tabId, _items);
    if (result is Ok<void>) _changed = false;
    return result;
  }

  Future<Result<void>> _reset() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _dashboardRepository.resetLayout(server, tabId);
  }

  @override
  void dispose() {
    load.dispose();
    save.dispose();
    reset.dispose();
    super.dispose();
  }
}
