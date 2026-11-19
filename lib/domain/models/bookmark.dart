/// The bookmarks of the signed-in account (`GET /api/bookmarks`).
final class Bookmarks {
  /// Creates the bookmarks.
  const Bookmarks({required this.folders, required this.bookmarks});

  /// The folders in the order of the web interface.
  final List<BookmarkFolder> folders;

  /// The bookmarks in the order of the web interface.
  final List<Bookmark> bookmarks;
}

/// A folder of bookmarks.
final class BookmarkFolder {
  /// Creates the folder.
  const BookmarkFolder({required this.id, required this.name});

  /// The server's id.
  final String id;

  /// The name of the folder.
  final String name;
}

/// A saved link.
final class Bookmark {
  /// Creates the bookmark.
  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.folderId = '',
    this.createdAt,
  });

  /// The server's id.
  final String id;

  /// The title; the address when empty.
  final String title;

  /// The address the bookmark opens.
  final Uri url;

  /// The folder, or empty for none.
  final String folderId;

  /// When the bookmark was added.
  final DateTime? createdAt;
}

/// How a bookmarks widget orders its links, as in the web interface.
enum BookmarkSort {
  /// The order chosen in the web interface.
  manual,

  /// By title, A–Z.
  az,

  /// Newest first.
  newest;

  /// Orders [list] without changing it.
  List<Bookmark> apply(List<Bookmark> list) => switch (this) {
    manual => [...list],
    az => [...list]..sort(_byTitle),
    newest =>
      [...list]..sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null || bt == null || at == bt) return _byTitle(a, b);
        return bt.compareTo(at);
      }),
  };

  static int _byTitle(Bookmark a, Bookmark b) =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase());
}
