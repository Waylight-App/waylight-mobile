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

/// Edits the phone layout of one tab (#53): order, hidden widgets, sizes
/// (#208), reset.
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
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Moves the widget at [from] to [to] (in the list after removing it).
  void move(int from, int to) {
    if (from == to || from < 0 || from >= _items.length) return;
    final list = [..._items];
    final item = list.removeAt(from);
    list.insert(to.clamp(0, list.length), item);
    _items = List.unmodifiable(list);
    notifyListeners();
  }

  /// Shows or hides the widget at [index] on phones.
  void toggleHidden(int index) {
    final list = [..._items];
    list[index] = list[index].copyWith(hidden: !list[index].hidden);
    _items = List.unmodifiable(list);
    notifyListeners();
  }

  /// Sets the grid size of the widget at [index]; `null` shows it at the
  /// full width and its natural height (#208).
  void setSize(int index, WidgetSize? size) {
    if (_items[index].size == size) return;
    final list = [..._items];
    list[index] = list[index].withSize(size);
    _items = List.unmodifiable(list);
    notifyListeners();
  }

  Future<Result<void>> _save() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _dashboardRepository.saveLayout(server, tabId, _items);
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
