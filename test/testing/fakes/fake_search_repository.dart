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
}
