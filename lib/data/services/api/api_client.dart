import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A successful answer with its status and headers, for the few calls that
/// need more than the body (e.g. the session cookie of the sign-in).
final class ApiResponse {
  /// Creates the response.
  const ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  /// The HTTP status, 2xx.
  final int statusCode;

  /// The decoded JSON body, or `null` if there is none.
  final Object? body;

  /// The response headers with lower-case names.
  final Map<String, String> headers;
}

/// Sends JSON requests to a Waylight server.
///
/// Every call gets the full [Uri], because the server address belongs to
/// the server repository and can change at run time. The session comes from
/// [ApiCredentials] and is only sent to its own server. Failures are
/// returned as [ApiException]s inside a [Result]; the client never throws
/// for network or HTTP errors.
class ApiClient {
  /// Creates a client that sends requests through the given HTTP client.
  ApiClient({
    required this._client,
    ApiCredentials? credentials,
    this.timeout = const Duration(seconds: 10),
  }) : _credentials = credentials ?? ApiCredentials();

  final http.Client _client;
  final ApiCredentials _credentials;
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
  }) async => _bodyOf(await _send('GET', uri, headers: headers));

  /// Sends a POST request with [body] encoded as JSON.
  Future<Result<Object?>> postJson(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
  }) async =>
      _bodyOf(await postJsonResponse(uri, body: body, headers: headers));

  /// Like [postJson], but returns status and headers as well.
  Future<Result<ApiResponse>> postJsonResponse(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send(
    'POST',
    uri,
    headers: {HttpHeaders.contentTypeHeader: 'application/json', ...headers},
    body: jsonEncode(body),
  );

  static Result<Object?> _bodyOf(Result<ApiResponse> result) =>
      switch (result) {
        Ok(:final value) => Result.ok(value.body),
        Error(:final error) => Result.error(error),
      };

  Future<Result<ApiResponse>> _send(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll({
        ..._jsonHeaders,
        ..._credentials.headersFor(method, uri),
        ...headers,
      });
    if (body != null) request.body = body;

    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
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

    // JSON is always UTF-8 (RFC 8259); Response.body would fall back to
    // Latin-1 when the content type names no charset.
    final decoded = _decode(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Result.ok(
        ApiResponse(
          statusCode: response.statusCode,
          body: decoded,
          headers: response.headers,
        ),
      );
    }
    _log.warning('HTTP ${response.statusCode}: ${uri.path}');
    if (response.statusCode == 401) _credentials.rejected(uri);
    return Result.error(_toException(response.statusCode, decoded));
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
