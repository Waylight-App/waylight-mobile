import 'package:waylight_mobile/data/repositories/search/search_repository.dart';
import 'package:waylight_mobile/data/services/api/search_api.dart';
import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [SearchRepository] that asks the server.
class SearchRepositoryRemote implements SearchRepository {
  /// Creates the repository.
  const SearchRepositoryRemote({required this._api});

  final SearchApi _api;

  @override
  Future<Result<SearchSettings>> settings(ServerAddress server) =>
      _api.settings(server);

  @override
  Future<Result<List<WikiHit>>> wiki(ServerAddress server, String query) =>
      _api.wiki(server, query);

  @override
  Future<Result<List<SearchAnswer>>> answers(
    ServerAddress server,
    String query,
    String language,
  ) => _api.answers(server, query, language);
}
