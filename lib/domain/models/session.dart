import 'package:waylight_mobile/domain/models/server_address.dart';

/// A signed-in session on a Waylight server (ADR 0004, phase 1).
///
/// The server identifies it by a cookie; state-changing requests also carry
/// its CSRF token. Both are secrets and only ever kept in the secure
/// storage.
final class Session {
  /// Creates a session on [server].
  const Session({
    required this.server,
    required this.cookie,
    required this.csrfToken,
  });

  /// The server the session belongs to; it is never sent anywhere else.
  final ServerAddress server;

  /// The session cookie as `name=value`, ready for the `Cookie` header.
  final String cookie;

  /// The token for `X-CSRF-Token` on POST, PUT, PATCH and DELETE.
  final String csrfToken;

  /// Whether [uri] is a request to [server], under its path.
  bool covers(Uri uri) =>
      uri.origin == server.uri.origin && uri.path.startsWith(server.uri.path);

  @override
  bool operator ==(Object other) =>
      other is Session &&
      other.server == server &&
      other.cookie == cookie &&
      other.csrfToken == csrfToken;

  @override
  int get hashCode => Object.hash(server, cookie, csrfToken);

  // Never print the secrets, e.g. in logs or test failures.
  @override
  String toString() => 'Session($server)';
}
