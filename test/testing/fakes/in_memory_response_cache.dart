import 'package:waylight_mobile/data/services/cache/response_cache.dart';

/// A [ResponseCache] in memory for tests.
class InMemoryResponseCache implements ResponseCache {
  /// The stored answers by address.
  final Map<String, CachedResponse> entries = {};

  @override
  Future<CachedResponse?> read(Uri uri) async => entries[uri.toString()];

  @override
  Future<void> write(Uri uri, String body, DateTime storedAt) async =>
      entries[uri.toString()] = (body: body, storedAt: storedAt);

  @override
  Future<void> clear() async => entries.clear();
}
