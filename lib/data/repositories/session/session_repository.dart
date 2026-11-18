import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/utils/result.dart';

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

  /// Ends the session on the server if it can be reached, and always on the
  /// device.
  Future<Result<void>> signOut();
}
