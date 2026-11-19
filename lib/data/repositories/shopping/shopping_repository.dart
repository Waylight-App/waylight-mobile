import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/shopping.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The shopping lists of the server (#145).
abstract interface class ShoppingRepository {
  /// The lists and the current one.
  Future<Result<ShoppingOverview>> overview(ServerAddress server);

  /// The items of [listId].
  Future<Result<List<ShoppingItem>>> items(ServerAddress server, String listId);

  /// Adds [summary] to [listId] and returns the new item.
  Future<Result<ShoppingItem>> add(
    ServerAddress server,
    String listId,
    String summary,
  );

  /// Ticks [itemId] off or on again.
  Future<Result<void>> setDone(
    ServerAddress server,
    String listId,
    String itemId, {
    required bool done,
  });

  /// Removes the ticked-off items of [listId].
  Future<Result<void>> clearCompleted(ServerAddress server, String listId);
}
