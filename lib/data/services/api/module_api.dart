import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Reads the JSON of a module endpoint and maps it with a parser.
///
/// Most widgets only read one or two endpoints; this saves an API class per
/// module. Endpoints that change data keep their own API class.
class ModuleApi {
  /// Creates the service on top of an [ApiClient].
  const ModuleApi(this._client);

  final ApiClient _client;

  /// Reads `GET path` with [query] and maps the answer with [parse]; an
  /// answer [parse] does not understand fails with `ApiFailure.server`.
  Future<Result<T>> read<T>(
    ServerAddress server,
    String path,
    T? Function(Object? json) parse, {
    Map<String, String> query = const {},
  }) async {
    final uri = server
        .resolve(path)
        .replace(queryParameters: query.isEmpty ? null : query);
    final result = await _client.getJson(uri);
    switch (result) {
      case Ok(:final value):
        final parsed = parse(value);
        return parsed == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(parsed);
      case Error(:final error):
        return Result.error(error);
    }
  }
}
