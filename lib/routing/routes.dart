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

  /// Writes a note: `/note?id=<id>`, without an id a new one (#101).
  static const note = '/note';

  /// Reads a saved article: `/article?id=<id>` (#104).
  static const article = '/article';

  /// Uptime and outages of a service: `/service?id=<id>&name=<name>` (#108).
  static const service = '/service';

  /// Broken connections and widgets that are not set up yet (#229).
  static const attention = '/attention';

  /// Password, two-factor sign-in and sessions (#110).
  static const security = '/settings/security';

  /// Saves content shared from another app: `/share?text=…` (#21).
  static const share = '/share';

  /// The wall display (#193); also opened by `waylight://kiosk?link=…`.
  static const kiosk = '/kiosk';

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
    calendar,
    shopping,
    feeds,
    timeline,
    smartHome,
    note,
    article,
    service,
    attention,
    security,
    share,
    kiosk,
  };
}
