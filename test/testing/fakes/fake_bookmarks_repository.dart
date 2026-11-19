import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository.dart';
import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [BookmarksRepository] without network for tests.
class FakeBookmarksRepository implements BookmarksRepository {
  /// What [bookmarks] returns; none by default.
  Result<Bookmarks> result = const Result.ok(
    Bookmarks(folders: [], bookmarks: []),
  );

  /// The folder and tag of every call.
  final List<(String, String)> calls = [];

  @override
  Future<Result<Bookmarks>> bookmarks(
    ServerAddress server, {
    String folder = '',
    String tag = '',
  }) async {
    calls.add((folder, tag));
    return result;
  }

  /// The changes asked for, as `create:<title>`, `update:<id>` or `delete:<id>`.
  final List<String> changes = [];

  @override
  Future<Result<void>> create(ServerAddress server, BookmarkDraft draft) async {
    changes.add('create:${draft.title}');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    BookmarkDraft draft,
  ) async {
    changes.add('update:$id');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> delete(ServerAddress server, String id) async {
    changes.add('delete:$id');
    return const Result.ok(null);
  }
}
