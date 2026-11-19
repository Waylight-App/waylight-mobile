import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/shopping.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [ShoppingRepository] in memory; [fail] makes every change fail.
class FakeShoppingRepository implements ShoppingRepository {
  /// The lists; the first one is current.
  List<ShoppingList> lists = const [
    ShoppingList(id: 'l1', name: 'Weekly shop'),
  ];

  /// The items of every list.
  List<ShoppingItem> itemList = [];

  /// The error changes fail with, if any.
  Exception? fail;

  /// The changes asked for, as `done:<id>`, `add:<text>` or `clear`.
  final List<String> calls = [];

  @override
  Future<Result<ShoppingOverview>> overview(ServerAddress server) async =>
      Result.ok(
        ShoppingOverview(
          lists: lists,
          current: lists.isEmpty ? '' : lists.first.id,
        ),
      );

  @override
  Future<Result<List<ShoppingItem>>> items(
    ServerAddress server,
    String listId,
  ) async => Result.ok(itemList);

  @override
  Future<Result<ShoppingItem>> add(
    ServerAddress server,
    String listId,
    String summary,
  ) async {
    calls.add('add:$summary');
    if (fail case final e?) return Result.error(e);
    final item = ShoppingItem(id: 'n${calls.length}', summary: summary);
    itemList = [...itemList, item];
    return Result.ok(item);
  }

  @override
  Future<Result<void>> setDone(
    ServerAddress server,
    String listId,
    String itemId, {
    required bool done,
  }) async {
    calls.add('done:$itemId');
    if (fail case final e?) return Result.error(e);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> clearCompleted(
    ServerAddress server,
    String listId,
  ) async {
    calls.add('clear');
    if (fail case final e?) return Result.error(e);
    return const Result.ok(null);
  }
}
