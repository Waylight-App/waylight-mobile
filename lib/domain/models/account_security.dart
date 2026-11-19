/// A signed-in session of the account (`GET /api/auth/sessions`).
final class AccountSession {
  /// Creates the session.
  const AccountSession({
    required this.id,
    required this.lastSeenAt,
    this.device = '',
    this.userAgent = '',
    this.clientIp = '',
    this.current = false,
  });

  /// The server's id.
  final String id;

  /// The device name of an app session; empty for browsers.
  final String device;

  /// The browser, for browser sessions.
  final String userAgent;

  /// The last address it was used from.
  final String clientIp;

  /// When it was last used.
  final DateTime lastSeenAt;

  /// Whether it is the app's own session.
  final bool current;
}

/// A started connection of an authenticator app
/// (`POST /api/auth/totp/setup`).
final class TotpSetup {
  /// Creates the setup.
  const TotpSetup({required this.secret, required this.uri});

  /// The secret to type in by hand.
  final String secret;

  /// The `otpauth://` address authenticator apps open.
  final Uri uri;
}
