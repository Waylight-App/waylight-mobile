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
}
