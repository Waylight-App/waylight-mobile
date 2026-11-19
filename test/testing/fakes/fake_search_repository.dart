import 'package:waylight_mobile/data/repositories/search/search_repository.dart';
import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [SearchRepository] without network for tests.
class FakeSearchRepository implements SearchRepository {
  /// What [settings] returns.
  Result<SearchSettings> result = const Result.ok(SearchSettings());

  @override
  Future<Result<SearchSettings>> settings(ServerAddress server) async => result;

  /// The wiki pages every query finds.
  List<WikiHit> wikiHits = const [];

  /// The wiki queries asked.
  final List<String> wikiQueries = [];

  @override
  Future<Result<List<WikiHit>>> wiki(ServerAddress server, String query) async {
    wikiQueries.add(query);
    return Result.ok(wikiHits);
  }

  /// The answers every query gets.
  List<SearchAnswer> answerList = const [];

  /// The answer queries asked, as `query/language`.
  final List<String> answerQueries = [];

  @override
  Future<Result<List<SearchAnswer>>> answers(
    ServerAddress server,
    String query,
    String language,
  ) async {
    answerQueries.add('$query/$language');
    return Result.ok(answerList);
  }
}
