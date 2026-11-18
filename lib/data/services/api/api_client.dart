import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Sends JSON requests to a Waylight server.
///
/// The client is stateless: every call gets the full [Uri], because the
/// server address belongs to the server repository and can change at run
/// time. Failures are returned as [ApiException]s inside a [Result]; the
/// client never throws for network or HTTP errors.
class ApiClient {
  /// Creates a client that sends requests through the given HTTP client.
  ApiClient({
    required this._client,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final Logger _log = Logger('ApiClient');

  /// How long a request may take before it counts as unreachable.
  final Duration timeout;

  static const Map<String, String> _jsonHeaders = {
    HttpHeaders.acceptHeader: 'application/json',
  };

  /// Sends a GET request and returns the decoded JSON body.
  Future<Result<Object?>> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) => _send(
    () => _client.get(uri, headers: {..._jsonHeaders, ...headers}),
    uri,
  );

  /// Sends a POST request with [body] encoded as JSON.
  Future<Result<Object?>> postJson(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send(
    () => _client.post(
      uri,
      headers: {
        ..._jsonHeaders,
        HttpHeaders.contentTypeHeader: 'application/json',
        ...headers,
      },
      body: jsonEncode(body),
    ),
    uri,
  );

  Future<Result<Object?>> _send(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      _log.info('Timeout: ${uri.path}');
      return const Result.error(ApiException(ApiFailure.unreachable));
    } on http.ClientException catch (e) {
      _log.info('Unreachable: ${uri.path}', e);
      return const Result.error(ApiException(ApiFailure.unreachable));
    } on SocketException catch (e) {
      _log.info('Unreachable: ${uri.path}', e);
      return const Result.error(ApiException(ApiFailure.unreachable));
    }

    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Result.ok(body);
    }
    _log.warning('HTTP ${response.statusCode}: ${uri.path}');
    return Result.error(_toException(response.statusCode, body));
  }

  static Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static ApiException _toException(int status, Object? body) {
    final error = switch (body) {
      {'error': final Map<String, Object?> error} => error,
      _ => const <String, Object?>{},
    };
    return ApiException(
      _failureFor(status),
      statusCode: status,
      code: _string(error['code']),
      message: _string(error['message']),
      field: _string(error['field']),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static ApiFailure _failureFor(int status) => switch (status) {
    401 => ApiFailure.unauthorized,
    403 => ApiFailure.forbidden,
    404 => ApiFailure.notFound,
    422 => ApiFailure.invalid,
    429 => ApiFailure.tooManyRequests,
    _ => ApiFailure.server,
  };
}
