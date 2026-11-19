import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/media.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Saved articles of the server (#104).
abstract interface class ReadLaterRepository {
  /// The saved articles, newest first.
  Future<Result<List<Article>>> articles(ServerAddress server);

  /// One article with its reader copy.
  Future<Result<Article>> article(ServerAddress server, String id);

  /// Marks an article read, unread or archived.
  Future<Result<void>> setStatus(
    ServerAddress server,
    String id,
    ArticleStatus status,
  );

  /// Saves [url]; the server fetches the reader copy.
  Future<Result<Article>> save(ServerAddress server, Uri url);

  /// Deletes an article.
  Future<Result<void>> remove(ServerAddress server, String id);
}

/// A [ReadLaterRepository] on `/api/readlater`.
class ReadLaterRepositoryRemote implements ReadLaterRepository {
  /// Creates the repository.
  const ReadLaterRepositoryRemote({required this._api});

  final ModuleApi _api;

  static String _path(String id) => '/api/readlater/${Uri.encodeComponent(id)}';

  @override
  Future<Result<List<Article>>> articles(ServerAddress server) =>
      _api.read(server, '/api/readlater', (json) => listOf(json, parseArticle));

  @override
  Future<Result<Article>> article(ServerAddress server, String id) =>
      _api.read(server, _path(id), parseArticle);

  @override
  Future<Result<void>> setStatus(
    ServerAddress server,
    String id,
    ArticleStatus status,
  ) async => switch (await _api.put(
    server,
    '${_path(id)}/status',
    body: {'status': status.name},
  )) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<Article>> save(ServerAddress server, Uri url) async =>
      switch (await _api.post(
        server,
        '/api/readlater',
        body: {'url': '$url'},
      )) {
        Ok(:final value) => switch (parseArticle(value)) {
          final a? => Result.ok(a),
          null => const Result.error(ApiException(ApiFailure.server)),
        },
        Error(:final error) => Result.error(error),
      };

  @override
  Future<Result<void>> remove(ServerAddress server, String id) =>
      _api.delete(server, _path(id));
}

/// Maps an article of `/api/readlater`.
Article? parseArticle(Object? a) {
  if (a case {
    'id': final String id,
    'url': final String url,
    'title': final String title,
  }) {
    final address = Uri.tryParse(url);
    if (address == null) return null;
    String text(Object? v) => v is String ? v : '';
    return Article(
      id: id,
      url: address,
      title: title.isEmpty ? url : title,
      site: text(a['site']),
      excerpt: text(a['excerpt']),
      readingMinutes: (a['readingMinutes'] as num?)?.toInt() ?? 0,
      status: switch (a['status']) {
        'read' => ArticleStatus.read,
        'archived' => ArticleStatus.archived,
        _ => ArticleStatus.unread,
      },
      content: text(a['content']),
    );
  }
  return null;
}
