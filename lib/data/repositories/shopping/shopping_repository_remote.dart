import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/shopping.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [ShoppingRepository] on the server's lists API
/// (`/api/shopping/lists/{id}/items`).
class ShoppingRepositoryRemote implements ShoppingRepository {
  /// Creates the repository.
  const ShoppingRepositoryRemote({required this._api});

  final ModuleApi _api;

  static String _list(String id) =>
      '/api/shopping/lists/${Uri.encodeComponent(id)}';

  @override
  Future<Result<ShoppingOverview>> overview(ServerAddress server) =>
      _api.read(server, '/api/shopping/lists', parseShoppingOverview);

  @override
  Future<Result<List<ShoppingItem>>> items(
    ServerAddress server,
    String listId,
  ) => _api.read(server, '${_list(listId)}/items', parseShoppingItems);

  @override
  Future<Result<ShoppingItem>> add(
    ServerAddress server,
    String listId,
    String summary,
  ) async {
    final result = await _api.post(
      server,
      '${_list(listId)}/items',
      body: {'summary': summary},
    );
    return switch (result) {
      Ok(:final value) => switch (_item(value)) {
        final item? => Result.ok(item),
        null => const Result.error(ApiException(ApiFailure.server)),
      },
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> setDone(
    ServerAddress server,
    String listId,
    String itemId, {
    required bool done,
  }) async => switch (await _api.put(
    server,
    '${_list(listId)}/items/${Uri.encodeComponent(itemId)}',
    body: {'done': done},
  )) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<void>> clearCompleted(
    ServerAddress server,
    String listId,
  ) async =>
      switch (await _api.post(server, '${_list(listId)}/clear-completed')) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };
}

ShoppingItem? _item(Object? i) {
  if (i case {'id': final String id, 'summary': final String summary}) {
    return ShoppingItem(id: id, summary: summary, done: i['done'] == true);
  }
  return null;
}

/// Maps `GET /api/shopping/lists`.
ShoppingOverview? parseShoppingOverview(Object? json) {
  if (json case {'lists': final Object? lists}) {
    final parsed = listOf<ShoppingList>(lists, (l) {
      if (l case {'id': final String id, 'name': final String name}) {
        return ShoppingList(
          id: id,
          name: name,
          open: (l['open'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    });
    if (parsed == null) return null;
    return ShoppingOverview(
      lists: parsed,
      current: switch (json['current']) {
        final String c => c,
        _ => '',
      },
    );
  }
  return null;
}

/// Maps the items of a list.
List<ShoppingItem>? parseShoppingItems(Object? json) =>
    listOf<ShoppingItem>(json, _item);
