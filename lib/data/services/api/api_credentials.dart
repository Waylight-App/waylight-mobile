import 'dart:io';

import 'package:waylight_mobile/domain/models/session.dart';

/// The credentials the `ApiClient` adds to requests.
///
/// The session repository decides which session is in use; the client only
/// asks for headers and reports a rejected session. Keeping the two apart
/// means no API service needs to know about sessions.
final class ApiCredentials {
  void Function()? _onRejected;

  /// The session used for the next requests, or `null` when signed out.
  Session? session;

  /// Called when the server rejects the session with HTTP 401.
  set onRejected(void Function()? callback) => _onRejected = callback;

  static const _safeMethods = {'GET', 'HEAD', 'OPTIONS'};

  /// The headers for a [method] request to [uri]; empty if signed out or if
  /// [uri] is not on the session's server.
  Map<String, String> headersFor(String method, Uri uri) {
    final session = this.session;
    if (session == null || !session.covers(uri)) return const {};
    return switch (session) {
      AppSession(:final token) => {
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
      BrowserSession(:final cookie, :final csrfToken) => {
        HttpHeaders.cookieHeader: cookie,
        // The server only checks the CSRF token on state-changing requests.
        if (!_safeMethods.contains(method)) 'X-CSRF-Token': csrfToken,
      },
    };
  }

  /// Reports that a request to [uri] that carried the session got a 401.
  void rejected(Uri uri) {
    final session = this.session;
    if (session == null || !session.covers(uri)) return;
    _onRejected?.call();
  }
}
