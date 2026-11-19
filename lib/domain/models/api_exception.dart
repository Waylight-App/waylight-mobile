/// Why a request to the Waylight server failed.
enum ApiFailure {
  /// The server could not be reached: no network, wrong address, timeout.
  unreachable,

  /// The session is missing or expired (HTTP 401).
  unauthorized,

  /// The account may not do this (HTTP 403).
  forbidden,

  /// The resource does not exist or its module is disabled (HTTP 404).
  notFound,

  /// Someone else changed the resource in the meantime (HTTP 409).
  conflict,

  /// The server rejected the input (HTTP 422); see [ApiException.field].
  invalid,

  /// Too many failed attempts; the client is locked out for a while (429).
  tooManyRequests,

  /// The server answered with an error, or it is not a Waylight server.
  server,
}

/// A failed request to the Waylight API.
///
/// Mirrors the error envelope of the server, `{"error": {"code", "message",
/// "field"}}` (`api/openapi.base.yaml` in the server repository).
final class ApiException implements Exception {
  /// Creates an exception for [failure].
  const ApiException(
    this.failure, {
    this.statusCode,
    this.code,
    this.message,
    this.field,
  });

  /// The kind of failure, from which the UI picks a message.
  final ApiFailure failure;

  /// The HTTP status code, if the server answered.
  final int? statusCode;

  /// The machine-readable error code of the server, such as `invalid`.
  final String? code;

  /// The English message of the server.
  final String? message;

  /// The request field a validation error refers to.
  final String? field;

  @override
  String toString() =>
      'ApiException(${failure.name}, status: $statusCode, code: $code)';
}
