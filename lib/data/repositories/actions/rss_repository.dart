import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The feed items of the server (#142).
abstract interface class RssRepository {
  /// The newest [limit] items, of one feed when [feedId] is set.
  Future<Result<List<FeedArticle>>> items(
    ServerAddress server, {
    String feedId = '',
    bool unreadOnly = true,
    int limit = 20,
  });

  /// Marks an item read or unread.
  Future<Result<void>> setRead(
    ServerAddress server,
    String id, {
    required bool read,
  });

  /// The subscribed feeds with their unread counts.
  Future<Result<List<RssFeed>>> feeds(ServerAddress server);

  /// Marks every item read, of one feed when [feedId] is set.
  Future<Result<void>> markAllRead(ServerAddress server, {String feedId = ''});

  /// Asks the server to fetch the feeds now.
  Future<Result<void>> refresh(ServerAddress server);
}

/// An [RssRepository] on `/api/rss`.
class RssRepositoryRemote implements RssRepository {
  /// Creates the repository.
  const RssRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<FeedArticle>>> items(
    ServerAddress server, {
    String feedId = '',
    bool unreadOnly = true,
    int limit = 20,
  }) => _api.read(
    server,
    '/api/rss/items',
    parseFeedArticles,
    query: {
      'limit': '$limit',
      if (feedId.isNotEmpty) 'feed': feedId,
      if (unreadOnly) 'unread': 'true',
    },
  );

  @override
  Future<Result<void>> setRead(
    ServerAddress server,
    String id, {
    required bool read,
  }) async => switch (await _api.put(
    server,
    '/api/rss/items/${Uri.encodeComponent(id)}/read',
    body: {'read': read},
  )) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<List<RssFeed>>> feeds(ServerAddress server) =>
      _api.read(server, '/api/rss/feeds', parseFeeds);

  @override
  Future<Result<void>> markAllRead(
    ServerAddress server, {
    String feedId = '',
  }) async => switch (await _api.post(
    server,
    '/api/rss/read-all',
    body: {'feedId': feedId},
  )) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<Result<void>> refresh(ServerAddress server) async =>
      switch (await _api.post(server, '/api/rss/refresh')) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };
}

/// Maps `GET /api/rss/feeds`.
List<RssFeed>? parseFeeds(Object? json) => listOf<RssFeed>(json, (f) {
  if (f case {'id': final String id, 'title': final String title}) {
    return RssFeed(
      id: id,
      title: title,
      unread: (f['unread'] as num?)?.toInt() ?? 0,
    );
  }
  return null;
});

/// Maps `GET /api/rss/items`.
List<FeedArticle>? parseFeedArticles(Object? json) =>
    listOf<FeedArticle>(json, (i) {
      if (i case {'id': final String id, 'title': final String title}) {
        return FeedArticle(
          id: id,
          title: title,
          feed: switch (i['feedTitle']) {
            final String f => f,
            _ => '',
          },
          link: switch (i['link']) {
            final String l when l.isNotEmpty => Uri.tryParse(l),
            _ => null,
          },
          publishedAt: asDateTime(i['publishedAt'])?.toLocal(),
          read: i['read'] == true,
        );
      }
      return null;
    });
