// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Waylight';

  @override
  String get connectTitle => 'Connect your Waylight';

  @override
  String get connectIntro =>
      'Enter the address you open Waylight with in your browser.';

  @override
  String get connectAddressLabel => 'Server address';

  @override
  String get connectAddressHint => 'https://home.example.org';

  @override
  String get connectButton => 'Connect';

  @override
  String get connectErrorEmpty => 'Enter the address of your server.';

  @override
  String get connectErrorInvalid =>
      'This is not a valid address. Example: https://home.example.org';

  @override
  String get connectErrorScheme =>
      'The address must start with http:// or https://.';

  @override
  String get connectErrorParts =>
      'Leave out user name, password and anything after ? or #.';

  @override
  String get connectErrorNotWaylight =>
      'This address does not answer like a Waylight server.';

  @override
  String get connectInsecureWarning =>
      'Without https:// your password travels unencrypted. Use this only in your own network.';

  @override
  String get homeSetupRequired =>
      'This server has no account yet. Finish the setup in your browser first.';

  @override
  String get homeDisconnect => 'Use another server';

  @override
  String get connectPrivacy => 'The app talks to your server and nobody else.';

  @override
  String get errorUnreachable =>
      'The server cannot be reached. Is your phone in the same network or VPN?';

  @override
  String get errorUnauthorized =>
      'Your session has ended. Please sign in again.';

  @override
  String get errorForbidden => 'Your account may not do this.';

  @override
  String get errorNotFound =>
      'This is not available on your server. The module may be switched off.';

  @override
  String get errorInvalid => 'Please check your input.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get errorServer =>
      'The server answered with an error. Please try again later.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String signInServer(String server) {
    return 'on $server';
  }

  @override
  String get signInExpired => 'Your session has ended. Please sign in again.';

  @override
  String get signInUsernameLabel => 'Account name';

  @override
  String get signInUsernameHelper => 'Leave empty for the owner account.';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInCodeLabel => 'Code';

  @override
  String get signInCodeHint =>
      'The code from your authenticator app, or a recovery code.';

  @override
  String get signInCodeHintRecovery =>
      'This account uses a passkey. Enter one of your recovery codes.';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInErrorCredentials =>
      'The account name or the password is wrong.';

  @override
  String get signInErrorCode => 'The password or the code is wrong.';

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get dashboardWidgetNotYet => 'Not available in the app yet.';

  @override
  String get dashboardRetry => 'Try again';

  @override
  String get dashboardNoTabs =>
      'There are no tabs for your account yet. Add one in the web interface.';

  @override
  String get dashboardEmptyTab => 'This tab has no widgets yet.';

  @override
  String get connectErrorInsecure =>
      'Plain http:// only works for addresses in your home network. Use https:// for this server.';

  @override
  String get weatherClearSky => 'Clear sky';

  @override
  String get weatherMainlyClear => 'Mainly clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherOvercast => 'Overcast';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherRimeFog => 'Rime fog';

  @override
  String get weatherLightDrizzle => 'Light drizzle';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherDenseDrizzle => 'Dense drizzle';

  @override
  String get weatherFreezingDrizzle => 'Freezing drizzle';

  @override
  String get weatherLightRain => 'Light rain';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherHeavyRain => 'Heavy rain';

  @override
  String get weatherFreezingRain => 'Freezing rain';

  @override
  String get weatherLightSnow => 'Light snow';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherHeavySnow => 'Heavy snow';

  @override
  String get weatherSnowGrains => 'Snow grains';

  @override
  String get weatherRainShowers => 'Rain showers';

  @override
  String get weatherViolentShowers => 'Violent showers';

  @override
  String get weatherSnowShowers => 'Snow showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherThunderstormWithHail => 'Thunderstorm with hail';

  @override
  String get weatherUnknown => 'Unknown';

  @override
  String weatherDegrees(int value) {
    return '$value °C';
  }

  @override
  String weatherFeelsLike(int value) {
    return 'Feels like $value °C';
  }

  @override
  String weatherRange(int min, int max) {
    return '$min° / $max°';
  }

  @override
  String weatherPrecipitation(int value) {
    return '$value % rain';
  }

  @override
  String get weatherNoPlace =>
      'Choose a place for this widget in the web interface.';

  @override
  String get todosTitle => 'To-dos';

  @override
  String get todosEmpty => 'Nothing to do.';

  @override
  String get todosDone => 'Done';

  @override
  String get todosOverdue => 'Overdue';

  @override
  String get todosToday => 'Today';

  @override
  String get todosTomorrow => 'Tomorrow';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesNone => 'No notes yet.';

  @override
  String get notesNonePinned => 'No pinned notes.';

  @override
  String get notesPinned => 'Pinned';

  @override
  String get bookmarksTitle => 'Bookmarks';

  @override
  String get bookmarksEmpty => 'No bookmarks yet.';

  @override
  String get linkOpenFailed => 'The link could not be opened.';

  @override
  String get dashboardOpenInWaylight => 'Open in Waylight';

  @override
  String get transitTitle => 'Departures';

  @override
  String get transitNoStop =>
      'Choose a stop for this widget in the web interface.';

  @override
  String get transitEmpty => 'No departures in the next hours.';

  @override
  String get transitNow => 'now';

  @override
  String transitInMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String transitDelay(int minutes) {
    return '+$minutes';
  }

  @override
  String get transitCancelled => 'cancelled';

  @override
  String transitTimeTrack(String time, String track) {
    return '$time · platform $track';
  }

  @override
  String get wasteTitle => 'Waste collection';

  @override
  String get wasteNotConfigured =>
      'Set up the waste calendar in the web interface.';

  @override
  String get wasteEmpty => 'No collections ahead.';

  @override
  String wasteInDays(int days) {
    return 'in $days days';
  }

  @override
  String get freshnessJustNow => 'updated just now';

  @override
  String freshnessMinutesAgo(int minutes) {
    return 'updated $minutes min ago';
  }

  @override
  String freshnessStale(String age) {
    return 'outdated – $age';
  }

  @override
  String freshnessFailed(String age) {
    return 'refresh failed – $age';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAddress => 'Address';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsOwnerAccount => 'Owner account';

  @override
  String get settingsRoleOwner => 'Owner';

  @override
  String get settingsRoleAdmin => 'Admin';

  @override
  String get settingsRoleMember => 'Member';

  @override
  String get settingsRoleGuest => 'Guest';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsLicence => 'Licence';

  @override
  String get settingsSource => 'Source code';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLicences => 'Open-source licences';

  @override
  String get pairTitle => 'Connecting the app';

  @override
  String get pairInvalidLink =>
      'This link is not a complete pairing code. Show a new QR code in Waylight under Settings → Mobile app.';

  @override
  String get pairCodeInvalid =>
      'This pairing code is not valid any more. Show a new QR code in Waylight under Settings → Mobile app.';

  @override
  String get pairEnterManually => 'Enter the address instead';

  @override
  String get connectQrHint =>
      'Or scan the QR code under Settings → Mobile app in Waylight with your phone\'s camera.';

  @override
  String get connectTryDemo => 'Try the public demo';

  @override
  String get dashboardDemo =>
      'This is the public demo. Its data is reset every hour.';

  @override
  String get errorConflict =>
      'Someone else changed this in the meantime. It was loaded again.';

  @override
  String get todosAddLabel => 'New to-do';

  @override
  String get todosAdd => 'Add';

  @override
  String get todosClearCompleted => 'Clear completed';

  @override
  String get todosTitleLabel => 'Title';

  @override
  String get todosTitleRequired => 'Enter a title.';

  @override
  String get todosNoDueDate => 'No due date';

  @override
  String get todosRemoveDueDate => 'Remove due date';

  @override
  String get todosDelete => 'Delete';

  @override
  String get todosSave => 'Save';

  @override
  String dashboardOffline(String time) {
    return 'Offline · showing the data from $time';
  }

  @override
  String get signInBrowser =>
      'Sign in in the browser (passkey, Microsoft, SSO)';

  @override
  String get authCallbackTitle => 'Finishing the sign-in';

  @override
  String get authCallbackCancelled =>
      'The sign-in in the browser was cancelled.';

  @override
  String get authCallbackUnexpected =>
      'This sign-in was not started in this app, or it took too long. Please start it again.';

  @override
  String get authCallbackBack => 'Back to the sign-in';

  @override
  String get searchHint => 'Search';

  @override
  String get searchIntro =>
      'Type a keyword, a widget, \"t\" and a to-do, or anything to search the web.';

  @override
  String searchWeb(String query) {
    return 'Search the web for \"$query\"';
  }

  @override
  String searchAddTodo(String title) {
    return 'Add to-do \"$title\"';
  }

  @override
  String searchTodoAdded(String title) {
    return 'To-do \"$title\" added.';
  }

  @override
  String searchOnTab(String tab) {
    return 'On the tab $tab';
  }

  @override
  String get lockTitle => 'Waylight is locked';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockReason => 'Unlock Waylight';

  @override
  String get settingsLock => 'App lock';

  @override
  String get settingsLockSwitch => 'Lock with fingerprint, face or device PIN';

  @override
  String get settingsLockAfter => 'Lock after';

  @override
  String get settingsLockNow => 'At once';

  @override
  String settingsLockMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get shortcutAddTodo => 'Add to-do';

  @override
  String get shortcutDepartures => 'Departures';
}
