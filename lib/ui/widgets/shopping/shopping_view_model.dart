import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/shopping.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the shopping list widget (#145).
///
/// Changes show at once and are undone when the server refuses them; the
/// failure is kept for a message, see [takeLastError].
class ShoppingViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  ShoppingViewModel({
    required this._serverRepository,
    required this._shoppingRepository,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  final ServerRepository _serverRepository;
  final ShoppingRepository _shoppingRepository;

  ShoppingList? _list;
  List<ShoppingItem> _items = const [];
  Exception? _lastError;

  /// Loads the current list and its items; run again to reload.
  late final Command0<void> load;

  /// The list shown, or `null` when the account has none yet.
  ShoppingList? get list => _list;

  /// Open items first, then the ones in the basket.
  List<ShoppingItem> get items => [
    ..._items.where((i) => !i.done),
    ..._items.where((i) => i.done),
  ];

  /// The last refused change, once; the view shows it as a message.
  Exception? takeLastError() {
    final e = _lastError;
    _lastError = null;
    return e;
  }

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final overview = await _shoppingRepository.overview(server);
    switch (overview) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        final lists = value.lists;
        _list = lists.isEmpty
            ? null
            : lists.firstWhere(
                (l) => l.id == value.current,
                orElse: () => lists.first,
              );
    }
    final list = _list;
    if (list == null) {
      _items = const [];
      notifyListeners();
      return const Result.ok(null);
    }
    final items = await _shoppingRepository.items(server, list.id);
    switch (items) {
      case Ok(:final value):
        _items = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Ticks [item] off or on again.
  Future<void> toggle(ShoppingItem item) async {
    final (server, list) = (_serverRepository.current, _list);
    if (server == null || list == null) return;
    _replace(item.withDone(!item.done));
    final result = await _shoppingRepository.setDone(
      server,
      list.id,
      item.id,
      done: !item.done,
    );
    if (result case Error(:final error)) {
      _replace(item);
      _fail(error);
    }
  }

  /// Adds [summary] to the list; empty text is ignored.
  Future<void> add(String summary) async {
    final text = summary.trim();
    final (server, list) = (_serverRepository.current, _list);
    if (text.isEmpty || server == null || list == null) return;
    switch (await _shoppingRepository.add(server, list.id, text)) {
      case Ok(:final value):
        _items = [..._items, value];
        notifyListeners();
      case Error(:final error):
        _fail(error);
    }
  }

  /// Removes the items in the basket.
  Future<void> clearCompleted() async {
    final (server, list) = (_serverRepository.current, _list);
    if (server == null || list == null) return;
    final before = _items;
    _items = _items.where((i) => !i.done).toList();
    notifyListeners();
    if (await _shoppingRepository.clearCompleted(server, list.id) case Error(
      :final error,
    )) {
      _items = before;
      _fail(error);
    }
  }

  void _replace(ShoppingItem item) {
    _items = [for (final i in _items) i.id == item.id ? item : i];
    notifyListeners();
  }

  void _fail(Exception error) {
    _lastError = error;
    notifyListeners();
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}

/// Whether [error] means the module has no list configured.
bool isNotConfigured(Exception error) =>
    error is ApiException && error.failure == ApiFailure.notFound;
