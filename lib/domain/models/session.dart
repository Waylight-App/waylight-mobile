import 'package:waylight_mobile/domain/models/server_address.dart';

/// A signed-in session on a Waylight server (ADR 0004).
///
/// Its secrets are only ever kept in the secure storage and only sent to
/// [server].
sealed class Session {
  const Session({required this.server});

  /// The server the session belongs to; it is never sent anywhere else.
  final ServerAddress server;

  /// Whether [uri] is a request to [server], under its path.
  bool covers(Uri uri) =>
      uri.origin == server.uri.origin && uri.path.startsWith(server.uri.path);

  // Never print the secrets, e.g. in logs or test failures.
  @override
  String toString() => '$runtimeType($server)';
}

/// The session of a browser (phase 1): a cookie, and a CSRF token for
/// state-changing requests. Used with servers without app sessions.
final class BrowserSession extends Session {
  /// Creates the session.
  const BrowserSession({
    required super.server,
    required this.cookie,
    required this.csrfToken,
  });

  /// The session cookie as `name=value`, ready for the `Cookie` header.
  final String cookie;

  /// The token for `X-CSRF-Token` on POST, PUT, PATCH and DELETE.
  final String csrfToken;

  @override
  bool operator ==(Object other) =>
      other is BrowserSession &&
      other.server == server &&
      other.cookie == cookie &&
      other.csrfToken == csrfToken;

  @override
  int get hashCode => Object.hash(server, cookie, csrfToken);
}

/// An app session (phase 2, server ADR 0024): a bearer token of this
/// device, listed with the device name in the web interface and revoked
/// there. It needs no CSRF token.
final class AppSession extends Session {
  /// Creates the session.
  const AppSession({required super.server, required this.token});

  /// The bearer token (`wa_…`).
  final String token;

  @override
  bool operator ==(Object other) =>
      other is AppSession && other.server == server && other.token == token;

  @override
  int get hashCode => Object.hash(server, token);
}
