import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The search settings of the account (#22).
abstract interface class SearchRepository {
  /// The keywords, shortcuts and web search of [server].
  Future<Result<SearchSettings>> settings(ServerAddress server);

  /// Pages of the connected wikis that match [query] (#156).
  Future<Result<List<WikiHit>>> wiki(ServerAddress server, String query);
}
