import 'package:waylight_mobile/routing/routes.dart';

/// The areas of the settings, in the order of the start page (#231).
///
/// Each area is a screen of its own at [path], also reachable as
/// `waylight://settings/<segment>`. docs/development.md#settings-areas lists
/// what each holds.
enum SettingsArea {
  /// Who is signed in, password and sign-in methods, sign out.
  account(Routes.settingsAccount),

  /// The addresses of the server, other servers, disconnecting.
  server(Routes.settingsServer),

  /// Theme, wallpaper colours, language and the accessibility options.
  appearance(Routes.settingsAppearance),

  /// Push notifications with the battery hint, reminders on the device.
  notifications(Routes.settingsNotifications),

  /// App lock, home screen widgets, Quick Settings tiles, wall display.
  phone(Routes.settingsPhone),

  /// Versions, licences, source, privacy and the diagnostic report.
  about(Routes.settingsAbout);

  const SettingsArea(this.path);

  /// The route of the area's screen.
  final String path;

  /// The path below [Routes.settings], e.g. `server`.
  String get segment => path.substring(Routes.settings.length + 1);
}
