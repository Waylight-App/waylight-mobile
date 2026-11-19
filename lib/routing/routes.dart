/// The paths of all screens. Use these constants, never string literals.
abstract final class Routes {
  /// The dashboard, the start screen once signed in.
  static const home = '/';

  /// The screen that asks for the server address.
  static const connect = '/connect';

  /// The screen that asks for account name and password.
  static const signIn = '/sign-in';

  /// Server, account, appearance and about.
  static const settings = '/settings';

  /// Pairs the app from a QR code: `waylight://pair?server=…&code=…` (#43).
  static const pair = '/pair';

  /// The answer of a sign-in in the browser: `waylight://auth?code=…` (#45).
  static const auth = '/auth';

  /// Every path the router knows; links to others open the dashboard.
  static const all = {home, connect, signIn, settings, pair, auth};
}
