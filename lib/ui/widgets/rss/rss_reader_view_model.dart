import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the feed reader (#106): the feeds, the chosen one and its
/// items, unread only or all.
class RssReaderViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  RssReaderViewModel({required this._serverRepository, required this._rss}) {
    load = Command0(_load)..execute().ignore();
  }

  /// How many items are loaded.
  static const limit = 100;

  final ServerRepository _serverRepository;
  final RssRepository _rss;

  List<RssFeed> _feeds = const [];
  List<FeedArticle> _items = const [];
  String _feedId = '';
  bool _unreadOnly = true;
  Exception? _lastError;

  /// Loads feeds and items; run again to reload.
  late final Command0<void> load;

  /// The feeds.
  List<RssFeed> get feeds => _feeds;

  /// The items of the chosen feed.
  List<FeedArticle> get items => _items;

  /// The chosen feed; empty for all.
  String get feedId => _feedId;

  /// Whether only unread items are shown.
  bool get unreadOnly => _unreadOnly;

  /// Unread items over all feeds.
  int get unread => _feeds.fold(0, (sum, f) => sum + f.unread);

  /// The last refused change, once.
  Exception? takeLastError() {
    final e = _lastError;
    _lastError = null;
    return e;
  }

  /// Shows one feed, or all with an empty id.
  Future<void> chooseFeed(String id) async {
    _feedId = id;
    notifyListeners();
    await load.execute();
  }

  /// Shows only unread items, or all.
  Future<void> setUnreadOnly(bool value) async {
    _unreadOnly = value;
    notifyListeners();
    await load.execute();
  }

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final feeds = await _rss.feeds(server);
    if (feeds case Ok(:final value)) _feeds = value;
    switch (await _rss.items(
      server,
      feedId: _feedId,
      unreadOnly: _unreadOnly,
      limit: limit,
    )) {
      case Ok(:final value):
        _items = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Marks [item] read or unread; undone when the server refuses.
  Future<void> setRead(FeedArticle item, {required bool read}) async {
    final server = _serverRepository.current;
    if (server == null || item.read == read) return;
    _replace(item.withRead(read));
    _count(item, read ? -1 : 1);
    if (await _rss.setRead(server, item.id, read: read) case Error(
      :final error,
    )) {
      _replace(item);
      _count(item, read ? 1 : -1);
      _fail(error);
    }
  }

  /// Marks everything of the chosen feed read.
  Future<void> markAllRead() async {
    final server = _serverRepository.current;
    if (server == null) return;
    if (await _rss.markAllRead(server, feedId: _feedId) case Error(
      :final error,
    )) {
      _fail(error);
      return;
    }
    await load.execute();
  }

  /// Fetches the feeds on the server, then reloads.
  Future<void> refresh() async {
    final server = _serverRepository.current;
    if (server != null) await _rss.refresh(server);
    await load.execute();
  }

  void _replace(FeedArticle item) {
    _items = [for (final i in _items) i.id == item.id ? item : i];
    notifyListeners();
  }

  void _count(FeedArticle item, int delta) {
    _feeds = [
      for (final f in _feeds)
        f.title == item.feed
            ? RssFeed(
                id: f.id,
                title: f.title,
                unread: (f.unread + delta).clamp(0, 1 << 30),
              )
            : f,
    ];
    notifyListeners();
  }

  void _fail(Exception error) {
    _lastError = error;
    notifyListeners();
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
