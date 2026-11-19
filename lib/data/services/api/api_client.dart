import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/services/api/api_credentials.dart';
import 'package:waylight_mobile/data/services/api/offline_status.dart';
import 'package:waylight_mobile/data/services/cache/response_cache.dart';
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
    this._cache,
    OfflineStatus? offline,
    this._now = DateTime.now,
    this.timeout = const Duration(seconds: 10),
  }) : _credentials = credentials ?? ApiCredentials(),
       _offline = offline ?? OfflineStatus();

  /// The read endpoints whose last answer is kept for offline use (#23,
  /// ADR 0007). Sign-in, settings, exports and logs are never kept.
  static const cachedPaths = {
    '/api/dashboard',
    '/api/weather',
    '/api/todos',
    '/api/notes',
    '/api/bookmarks',
    '/api/transit/departures',
    '/api/waste/upcoming',
  };

  /// How old a stored answer may be to be shown.
  static const maxCacheAge = Duration(days: 7);

  final ResponseCache? _cache;
  final OfflineStatus _offline;
  final DateTime Function() _now;

  final http.Client _client;
  final ApiCredentials _credentials;
  final Logger _log = Logger('ApiClient');

  /// How long a request may take before it counts as unreachable.
  final Duration timeout;

  static const Map<String, String> _jsonHeaders = {
    HttpHeaders.acceptHeader: 'application/json',
  };

  /// Sends a GET request and returns the decoded JSON body. For the
  /// [cachedPaths], or with [keepOffline], the answer is kept and served
  /// when the server cannot be reached (ADR 0007).
  Future<Result<Object?>> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
    bool keepOffline = false,
  }) async {
    final result = await _send('GET', uri, headers: headers);
    final cache = _cache;
    if (cache == null || !(keepOffline || _cachable(uri))) {
      return _bodyOf(result);
    }
    switch (result) {
      case Ok(:final value):
        await cache.write(uri, jsonEncode(value.body), _now());
      case Error(error: ApiException(failure: ApiFailure.unreachable)):
        final stored = await cache.read(uri);
        if (stored != null &&
            _now().difference(stored.storedAt) < maxCacheAge) {
          _offline.servedStored(stored.storedAt);
          return Result.ok(_decode(stored.body));
        }
      case Error():
        break;
    }
    return _bodyOf(result);
  }

  bool _cachable(Uri uri) =>
      cachedPaths.any((p) => uri.path == p || uri.path.endsWith(p));

  /// Sends a POST request with [body] encoded as JSON.
  Future<Result<Object?>> postJson(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
  }) async =>
      _bodyOf(await postJsonResponse(uri, body: body, headers: headers));

  /// Sends a PUT request with [body] encoded as JSON.
  Future<Result<Object?>> putJson(Uri uri, {Object? body}) async => _bodyOf(
    await _send(
      'PUT',
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    ),
  );

  /// Sends a DELETE request.
  Future<Result<void>> delete(Uri uri) async =>
      switch (await _send('DELETE', uri, headers: const {})) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };

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
    final result = await _transport(method, uri, headers: headers, body: body);
    switch (result) {
      case Error(:final error):
        return Result.error(error);
      case Ok(value: final response):
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
  }

  /// Sends a GET request and returns the raw body, such as an image.
  Future<Result<Uint8List>> getBytes(Uri uri) async {
    final result = await _transport(
      'GET',
      uri,
      headers: const {HttpHeaders.acceptHeader: '*/*'},
    );
    switch (result) {
      case Error(:final error):
        return Result.error(error);
      case Ok(value: final response):
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return Result.ok(response.bodyBytes);
        }
        if (response.statusCode == 401) _credentials.rejected(uri);
        return Result.error(_toException(response.statusCode, null));
    }
  }

  /// Sends the request with the credentials; transport failures and
  /// timeouts become `ApiFailure.unreachable`.
  Future<Result<http.Response>> _transport(
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
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      _offline.reachedServer();
      return Result.ok(response);
    } on TimeoutException {
      _log.info('Timeout: ${uri.path}');
    } on http.ClientException catch (e) {
      _log.info('Unreachable: ${uri.path}', e);
    } on SocketException catch (e) {
      _log.info('Unreachable: ${uri.path}', e);
    }
    return const Result.error(ApiException(ApiFailure.unreachable));
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
    409 => ApiFailure.conflict,
    422 => ApiFailure.invalid,
    429 => ApiFailure.tooManyRequests,
    _ => ApiFailure.server,
  };
}
