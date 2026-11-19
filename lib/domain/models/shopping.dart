/// A shopping list (`GET /api/shopping/lists`).
final class ShoppingList {
  /// Creates the list.
  const ShoppingList({required this.id, required this.name, this.open = 0});

  /// The server's id.
  final String id;

  /// The list's name.
  final String name;

  /// How many items are still open.
  final int open;
}

/// The lists and the one the account looks at.
final class ShoppingOverview {
  /// Creates the overview.
  const ShoppingOverview({required this.lists, this.current = ''});

  /// The lists the account can see.
  final List<ShoppingList> lists;

  /// The id of the current list; empty when there is none.
  final String current;
}

/// An item of a shopping list.
final class ShoppingItem {
  /// Creates the item.
  const ShoppingItem({
    required this.id,
    required this.summary,
    this.done = false,
  });

  /// The server's id.
  final String id;

  /// What to buy.
  final String summary;

  /// Whether it is in the basket.
  final bool done;

  /// The same item, ticked off or not.
  ShoppingItem withDone(bool value) =>
      ShoppingItem(id: id, summary: summary, done: value);
}
