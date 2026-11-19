import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of a widget that shows a list and changes it on the server.
///
/// Changes show at once ([change], [remove], [add]) and are undone when the
/// server refuses them; the failure is kept for a message, see
/// [takeLastError] and `ErrorSnackListener`.
class ItemsViewModel<T> extends ChangeNotifier {
  /// Creates the view model and starts loading with the fetch function.
  ItemsViewModel({
    required this._serverRepository,
    required this._fetch,
    required this._id,
  }) {
    load = Command0(_load)..execute().ignore();
    _loadRole().ignore();
  }

  final ServerRepository _serverRepository;
  final Future<Result<List<T>>> Function(ServerAddress server) _fetch;
  final String Function(T item) _id;

  List<T> _items = const [];
  Exception? _lastError;
  bool _canEdit = false;

  /// Whether the account may change things; guests and kiosk displays only
  /// look, like in the web interface.
  bool get canEdit => _canEdit;

  Future<void> _loadRole() async {
    if (await _serverRepository.status() case Ok(:final value)) {
      _canEdit = value.role != 'guest' && value.role != 'kiosk';
      notifyListeners();
    }
  }

  /// Loads the list; run again to reload.
  late final Command0<void> load;

  /// The items.
  List<T> get items => _items;

  /// The last refused change, once.
  Exception? takeLastError() {
    final e = _lastError;
    _lastError = null;
    return e;
  }

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    switch (await _fetch(server)) {
      case Ok(:final value):
        _items = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Shows [after] in place of [before] and sends [send]; undone on failure.
  Future<void> change(
    T before,
    T after,
    Future<Result<void>> Function(ServerAddress server) send,
  ) async {
    final server = _serverRepository.current;
    if (server == null) return;
    _replace(_id(before), after);
    if (await send(server) case Error(:final error)) {
      _replace(_id(before), before);
      _fail(error);
    }
  }

  /// Hides [item] and sends [send]; it comes back on failure.
  Future<void> remove(
    T item,
    Future<Result<void>> Function(ServerAddress server) send,
  ) async {
    final server = _serverRepository.current;
    if (server == null) return;
    final before = _items;
    _items = [
      for (final i in _items)
        if (_id(i) != _id(item)) i,
    ];
    notifyListeners();
    if (await send(server) case Error(:final error)) {
      _items = before;
      _fail(error);
    }
  }

  /// Sends [send] and puts the created item first.
  Future<bool> add(
    Future<Result<T>> Function(ServerAddress server) send,
  ) async {
    final server = _serverRepository.current;
    if (server == null) return false;
    switch (await send(server)) {
      case Ok(:final value):
        _items = [value, ..._items];
        notifyListeners();
        return true;
      case Error(:final error):
        _fail(error);
        return false;
    }
  }

  void _replace(String id, T item) {
    _items = [for (final i in _items) _id(i) == id ? item : i];
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
