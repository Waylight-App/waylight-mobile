import 'dart:typed_data';

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
    // Widget data is kept for offline use like the dashboard (ADR 0007).
    final result = await _client.getJson(uri, keepOffline: true);
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

  /// Sends `POST path` with [query] and a JSON [body].
  Future<Result<Object?>> post(
    ServerAddress server,
    String path, {
    Object? body,
    Map<String, String> query = const {},
  }) => _client.postJson(
    server.resolve(path).replace(queryParameters: query.isEmpty ? null : query),
    body: body,
  );

  /// Sends `POST path` with a JSON [body] and reads a plain-text answer.
  Future<Result<String>> postText(
    ServerAddress server,
    String path, {
    Object? body,
  }) => _client.postText(server.resolve(path), body: body);

  /// Sends `PUT path` with a JSON [body].
  Future<Result<Object?>> put(
    ServerAddress server,
    String path, {
    Object? body,
  }) => _client.putJson(server.resolve(path), body: body);

  /// Reads `GET path` as raw bytes, such as an image.
  Future<Result<Uint8List>> bytes(
    ServerAddress server,
    String path, {
    Map<String, String> query = const {},
  }) => _client.getBytes(
    server.resolve(path).replace(queryParameters: query.isEmpty ? null : query),
  );

  /// Sends `DELETE path`.
  Future<Result<void>> delete(ServerAddress server, String path) =>
      _client.delete(server.resolve(path));
}
