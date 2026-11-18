/// What happened after the password was checked.
sealed class SignInResult {
  const SignInResult();
}

/// The account is signed in.
final class SignedIn extends SignInResult {
  /// Creates the result.
  const SignedIn();
}

/// The account has a second factor; the sign-in has to be repeated with a
/// code.
final class CodeRequired extends SignInResult {
  /// Creates the result.
  const CodeRequired({required this.authenticatorApp});

  /// Whether the account has an authenticator app. Without one (passkeys
  /// only) the app can only accept a recovery code.
  final bool authenticatorApp;
}
