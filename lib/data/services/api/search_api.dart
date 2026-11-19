import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/search.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The search settings of the server (`api/modules/search.yaml`).
class SearchApi {
  /// Creates the service on top of an [ApiClient].
  const SearchApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/search/settings`.
  Future<Result<SearchSettings>> settings(ServerAddress server) async {
    final result = await _client.getJson(
      server.resolve('/api/search/settings'),
    );
    return switch (result) {
      Ok(:final value) => switch (parseSearchSettings(value)) {
        final settings? => Result.ok(settings),
        null => const Result.error(ApiException(ApiFailure.server)),
      },
      Error(:final error) => Result.error(error),
    };
  }
}

/// Maps the JSON of `GET /api/search/settings`; `null` if it does not
/// match.
SearchSettings? parseSearchSettings(Object? json) {
  if (json is! Map<String, Object?>) return null;
  String str(Object? v) => v is String ? v : '';
  return SearchSettings(
    defaultProvider: str(json['defaultProvider']),
    shortcuts: [
      if (json['shortcuts'] case final List<Object?> list)
        for (final s in list)
          if (s case {'keyword': final String k, 'urlTemplate': final String u})
            SearchShortcut(keyword: k, name: str(s['name']), urlTemplate: u),
    ],
    keywords: [
      if (json['keywords'] case final List<Object?> list)
        for (final k in list)
          if (k case {
            'keyword': final String word,
            'kind': final String kind,
            'target': final String target,
          })
            SearchKeyword(
              keyword: word,
              kind: kind,
              target: target,
              label: str(k['label']),
            ),
    ],
    todoPrefix: switch (json['bar']) {
      {'capturePrefixes': {'todo': final String t}} => t,
      _ => '',
    },
  );
}
