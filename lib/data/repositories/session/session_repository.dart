import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/utils/result.dart';

/// An answer of the browser that does not belong to a sign-in started in
/// this app, or came back without a code (#45).
final class UnexpectedSignIn implements Exception {
  /// Creates the exception.
  const UnexpectedSignIn();
}

/// The signed-in session on the connected server (ADR 0004).
///
/// The single source of truth for whether the app is signed in. It notifies
/// its listeners on every change, so the router can show the sign-in
/// screen. It does not know the server repository: callers pass the server,
/// which keeps the repositories independent of each other.
abstract class SessionRepository extends ChangeNotifier {
  /// Whether a session is in use.
  bool get signedIn;

  /// Whether the server ended the last session (HTTP 401), as opposed to
  /// signing out in the app; the sign-in screen explains it then.
  bool get expired;

  /// Loads the stored session; one for another server than [server] is
  /// dropped. Call once at start.
  Future<Result<void>> restore(ServerAddress? server);

  /// Signs in on [server]. [username] is empty for the owner; [code] is the
  /// TOTP or recovery code when [SignInResult] asked for one.
  Future<Result<SignInResult>> signIn(
    ServerAddress server, {
    String username = '',
    required String password,
    String code = '',
  });

  /// Whether [server] can hand a sign-in in the browser over to the app
  /// (passkeys, Microsoft, single sign-on; #45).
  Future<bool> supportsBrowserSignIn(ServerAddress server);

  /// Prepares a sign-in in the browser and returns the page to open there.
  Future<Result<Uri>> startBrowserSignIn(ServerAddress server);

  /// Finishes a sign-in in the browser with the [code] and [state] the
  /// server sent back to the app.
  Future<Result<void>> finishBrowserSignIn({
    required String code,
    required String state,
  });

  /// Signs in on [server] with the pairing [code] of a QR code (#43).
  Future<Result<void>> pair(ServerAddress server, String code);

  /// Ends the session on the server if it can be reached, and always on the
  /// device.
  Future<Result<void>> signOut();
}
