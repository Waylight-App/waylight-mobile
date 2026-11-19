import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The settings of a bookmarks widget, as the web interface stores them.
final class BookmarksConfig {
  /// Creates the settings.
  const BookmarksConfig({
    this.folderId = '',
    this.tag = '',
    this.sort = BookmarkSort.manual,
  });

  /// Reads the widget configuration; unknown values fall back to defaults.
  factory BookmarksConfig.fromJson(Map<String, Object?> json) =>
      BookmarksConfig(
        folderId: switch (json['folderId']) {
          final String f => f,
          _ => '',
        },
        tag: switch (json['tag']) {
          final String t => t,
          _ => '',
        },
        sort: BookmarkSort.values.firstWhere(
          (s) => s.name == json['sort'],
          orElse: () => BookmarkSort.manual,
        ),
      );

  /// The folder to show; empty for all.
  final String folderId;

  /// The tag to show; empty for all.
  final String tag;

  /// The order of the links.
  final BookmarkSort sort;
}

/// A group of links under a folder name (empty for links without folder).
typedef BookmarkGroup = ({String name, List<Bookmark> links});

/// The state of a bookmarks widget (#66).
class BookmarksViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  BookmarksViewModel({
    required this.config,
    required this._serverRepository,
    required this._bookmarksRepository,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  /// The settings of the widget.
  final BookmarksConfig config;
  final ServerRepository _serverRepository;
  final BookmarksRepository _bookmarksRepository;

  /// Loads the links, grouped by folder in the folders' order.
  late final Command0<List<BookmarkGroup>> load;

  List<BookmarkFolder> _folders = const [];

  /// The folders a bookmark can go to.
  List<BookmarkFolder> get folders => _folders;

  /// Creates a bookmark, or saves it over [id], and reloads.
  Future<Result<void>> save(BookmarkDraft draft, {String id = ''}) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = id.isEmpty
        ? await _bookmarksRepository.create(server, draft)
        : await _bookmarksRepository.update(server, id, draft);
    if (result is Ok<void>) await load.execute();
    return result;
  }

  /// Deletes a bookmark and reloads.
  Future<Result<void>> delete(Bookmark bookmark) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _bookmarksRepository.delete(server, bookmark.id);
    if (result is Ok<void>) await load.execute();
    return result;
  }

  Future<Result<List<BookmarkGroup>>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _bookmarksRepository.bookmarks(
      server,
      folder: config.folderId,
      tag: config.tag,
    );
    switch (result) {
      case Ok(:final value):
        _folders = value.folders;
        return Result.ok(group(value, config.sort));
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Groups [bookmarks] by folder in the folders' order; links without a
  /// folder come last. Empty folders are left out.
  @visibleForTesting
  static List<BookmarkGroup> group(Bookmarks bookmarks, BookmarkSort sort) {
    final sorted = sort.apply(bookmarks.bookmarks);
    final known = {for (final f in bookmarks.folders) f.id};
    return [
      for (final folder in bookmarks.folders)
        if (sorted.where((b) => b.folderId == folder.id).toList()
            case final links when links.isNotEmpty)
          (name: folder.name, links: links),
      if (sorted.where((b) => !known.contains(b.folderId)).toList()
          case final links when links.isNotEmpty)
        (name: '', links: links),
    ];
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
