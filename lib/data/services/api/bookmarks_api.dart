import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The bookmarks endpoint of the server (`api/modules/bookmarks.yaml`).
class BookmarksApi {
  /// Creates the service on top of an [ApiClient].
  const BookmarksApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/bookmarks`, optionally of one [folder] or [tag].
  Future<Result<Bookmarks>> bookmarks(
    ServerAddress server, {
    String folder = '',
    String tag = '',
  }) async {
    final uri = server
        .resolve('/api/bookmarks')
        .replace(
          queryParameters: {
            if (folder.isNotEmpty) 'folder': folder,
            if (tag.isNotEmpty) 'tag': tag,
          },
        );
    final result = await _client.getJson(uri);
    switch (result) {
      case Ok(:final value):
        final bookmarks = parseBookmarks(value);
        return bookmarks == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(bookmarks);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// Maps the JSON of `GET /api/bookmarks`; `null` if it does not match.
/// Bookmarks with an address that is not http(s) are left out, so the app
/// never opens other schemes.
Bookmarks? parseBookmarks(Object? json) {
  if (json case {
    'bookmarks': final List<Object?> items,
    'folders': final List<Object?> folders,
  }) {
    return Bookmarks(
      folders: [
        for (final f in folders)
          if (f case {'id': final String id, 'name': final String name})
            BookmarkFolder(id: id, name: name),
      ],
      bookmarks: [
        for (final b in items)
          if (b case {
            'id': final String id,
            'title': final String title,
            'url': final String url,
          })
            if (Uri.tryParse(url) case final uri?
                when uri.isScheme('http') || uri.isScheme('https'))
              Bookmark(
                id: id,
                title: title.trim().isEmpty ? url : title,
                url: uri,
                folderId: switch (b['folderId']) {
                  final String f => f,
                  _ => '',
                },
                createdAt: switch (b['createdAt']) {
                  final String c => DateTime.tryParse(c),
                  _ => null,
                },
              ),
      ],
    );
  }
  return null;
}
