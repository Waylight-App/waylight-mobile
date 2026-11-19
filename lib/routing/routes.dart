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

  /// The search (#22).
  static const search = '/search';

  /// Waits for biometrics or the device PIN (#46).
  static const locked = '/locked';

  /// Edits the phone layout of a tab: `/edit-tab?tab=<id>` (#53).
  static const editTab = '/edit-tab';

  /// The agenda of the next weeks and new events (#100).
  static const calendar = '/calendar';

  /// The shopping list in full (#103).
  static const shopping = '/shopping';

  /// The feed reader (#106).
  static const feeds = '/feeds';

  /// The timeline of the instance (#109).
  static const timeline = '/timeline';

  /// Every chosen smart home entity (#107).
  static const smartHome = '/smart-home';

  /// Every path the router knows; links to others open the dashboard.
  static const all = {
    home,
    connect,
    signIn,
    settings,
    pair,
    auth,
    search,
    locked,
    editTab,
    calendar,
    shopping,
    feeds,
    timeline,
    smartHome,
  };
}
