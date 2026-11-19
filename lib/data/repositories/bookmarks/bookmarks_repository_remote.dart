import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository.dart';
import 'package:waylight_mobile/data/services/api/bookmarks_api.dart';
import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [BookmarksRepository] that asks the server every time.
class BookmarksRepositoryRemote implements BookmarksRepository {
  /// Creates the repository.
  const BookmarksRepositoryRemote({required this._api});

  final BookmarksApi _api;

  @override
  Future<Result<Bookmarks>> bookmarks(
    ServerAddress server, {
    String folder = '',
    String tag = '',
  }) => _api.bookmarks(server, folder: folder, tag: tag);

  @override
  Future<Result<void>> create(ServerAddress server, BookmarkDraft draft) =>
      _api.create(server, draft);

  @override
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    BookmarkDraft draft,
  ) => _api.update(server, id, draft);

  @override
  Future<Result<void>> delete(ServerAddress server, String id) =>
      _api.delete(server, id);
}
