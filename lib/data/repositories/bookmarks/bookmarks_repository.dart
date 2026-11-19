import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The bookmarks module of the server (#66).
abstract interface class BookmarksRepository {
  /// The bookmarks on [server], optionally of one [folder] or [tag].
  Future<Result<Bookmarks>> bookmarks(
    ServerAddress server, {
    String folder = '',
    String tag = '',
  });
}
