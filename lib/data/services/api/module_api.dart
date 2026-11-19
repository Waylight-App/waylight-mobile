import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Talks to the endpoints of a module: reads JSON and maps it with a
/// parser, or sends a change.
///
/// Most widgets need only a few calls; this saves an API class per module.
/// The repositories of the modules give the calls their names and types.
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

  /// Sends `POST path` with a JSON [body].
  Future<Result<Object?>> post(
    ServerAddress server,
    String path, {
    Object? body,
  }) => _client.postJson(server.resolve(path), body: body);

  /// Sends `PUT path` with a JSON [body].
  Future<Result<Object?>> put(
    ServerAddress server,
    String path, {
    Object? body,
  }) => _client.putJson(server.resolve(path), body: body);

  /// Sends `DELETE path`.
  Future<Result<void>> delete(ServerAddress server, String path) =>
      _client.delete(server.resolve(path));
}
