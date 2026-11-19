import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Name of the app, shown in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'Waylight'**
  String get appTitle;

  /// Heading of the screen where the user enters the server address.
  ///
  /// In en, this message translates to:
  /// **'Connect your Waylight'**
  String get connectTitle;

  /// Explanation below the heading of the connect screen.
  ///
  /// In en, this message translates to:
  /// **'Enter the address you open Waylight with in your browser.'**
  String get connectIntro;

  /// Label of the text field for the server address.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get connectAddressLabel;

  /// Example address in the empty text field. Keep the URL as is.
  ///
  /// In en, this message translates to:
  /// **'https://home.example.org'**
  String get connectAddressHint;

  /// Button that checks and saves the server address.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectButton;

  /// Validation error: the address field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the address of your server.'**
  String get connectErrorEmpty;

  /// Validation error: the address cannot be parsed. Keep the URL as is.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid address. Example: https://home.example.org'**
  String get connectErrorInvalid;

  /// Validation error: unsupported URL scheme.
  ///
  /// In en, this message translates to:
  /// **'The address must start with http:// or https://.'**
  String get connectErrorScheme;

  /// Validation error: the URL contains credentials, a query or a fragment.
  ///
  /// In en, this message translates to:
  /// **'Leave out user name, password and anything after ? or #.'**
  String get connectErrorParts;

  /// Error: the server answered, but not with the Waylight API.
  ///
  /// In en, this message translates to:
  /// **'This address does not answer like a Waylight server.'**
  String get connectErrorNotWaylight;

  /// Warning shown below the field when the address starts with http://.
  ///
  /// In en, this message translates to:
  /// **'Without https:// your password travels unencrypted. Use this only in your own network.'**
  String get connectInsecureWarning;

  /// Hint when the server still needs its first setup.
  ///
  /// In en, this message translates to:
  /// **'This server has no account yet. Finish the setup in your browser first.'**
  String get homeSetupRequired;

  /// Button that forgets the server address.
  ///
  /// In en, this message translates to:
  /// **'Use another server'**
  String get homeDisconnect;

  /// Footnote on the connect screen about privacy.
  ///
  /// In en, this message translates to:
  /// **'The app talks to your server and nobody else.'**
  String get connectPrivacy;

  /// Error: no answer from the server.
  ///
  /// In en, this message translates to:
  /// **'The server cannot be reached. Is your phone in the same network or VPN?'**
  String get errorUnreachable;

  /// Error: HTTP 401, the session is missing or expired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get errorUnauthorized;

  /// Error: HTTP 403.
  ///
  /// In en, this message translates to:
  /// **'Your account may not do this.'**
  String get errorForbidden;

  /// Error: HTTP 404, e.g. a disabled module.
  ///
  /// In en, this message translates to:
  /// **'This is not available on your server. The module may be switched off.'**
  String get errorNotFound;

  /// Error: HTTP 422 without a field-specific message.
  ///
  /// In en, this message translates to:
  /// **'Please check your input.'**
  String get errorInvalid;

  /// Error: HTTP 429, locked out after failed attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get errorTooManyRequests;

  /// Error: HTTP 5xx or an unexpected answer.
  ///
  /// In en, this message translates to:
  /// **'The server answered with an error. Please try again later.'**
  String get errorServer;

  /// Fallback error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// Title of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Line below the title naming the server.
  ///
  /// In en, this message translates to:
  /// **'on {server}'**
  String signInServer(String server);

  /// Shown when the server ended the session.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get signInExpired;

  /// Label of the account name field.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get signInUsernameLabel;

  /// Helper text below the account name field.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for the owner account.'**
  String get signInUsernameHelper;

  /// Label of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signInPasswordLabel;

  /// Label of the second-factor code field.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get signInCodeLabel;

  /// Helper text of the code field.
  ///
  /// In en, this message translates to:
  /// **'The code from your authenticator app, or a recovery code.'**
  String get signInCodeHint;

  /// Helper text of the code field for accounts with passkeys only.
  ///
  /// In en, this message translates to:
  /// **'This account uses a passkey. Enter one of your recovery codes.'**
  String get signInCodeHintRecovery;

  /// Button that signs in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// Error: wrong credentials.
  ///
  /// In en, this message translates to:
  /// **'The account name or the password is wrong.'**
  String get signInErrorCredentials;

  /// Error in the second step.
  ///
  /// In en, this message translates to:
  /// **'The password or the code is wrong.'**
  String get signInErrorCode;

  /// Button that signs out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeSignOut;

  /// Placeholder text of a widget without a native view.
  ///
  /// In en, this message translates to:
  /// **'Not available in the app yet.'**
  String get dashboardWidgetNotYet;

  /// Button that reloads the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dashboardRetry;

  /// Shown when the account has no tabs.
  ///
  /// In en, this message translates to:
  /// **'There are no tabs for your account yet. Add one in the web interface.'**
  String get dashboardNoTabs;

  /// Shown on a tab without widgets.
  ///
  /// In en, this message translates to:
  /// **'This tab has no widgets yet.'**
  String get dashboardEmptyTab;

  /// Validation error: http:// to an address outside the private network.
  ///
  /// In en, this message translates to:
  /// **'Plain http:// only works for addresses in your home network. Use https:// for this server.'**
  String get connectErrorInsecure;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get weatherClearSky;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Mainly clear'**
  String get weatherMainlyClear;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherOvercast;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Rime fog'**
  String get weatherRimeFog;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Light drizzle'**
  String get weatherLightDrizzle;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherDrizzle;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Dense drizzle'**
  String get weatherDenseDrizzle;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Freezing drizzle'**
  String get weatherFreezingDrizzle;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Light rain'**
  String get weatherLightRain;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get weatherHeavyRain;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Freezing rain'**
  String get weatherFreezingRain;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Light snow'**
  String get weatherLightSnow;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Heavy snow'**
  String get weatherHeavySnow;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Snow grains'**
  String get weatherSnowGrains;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Rain showers'**
  String get weatherRainShowers;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Violent showers'**
  String get weatherViolentShowers;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Snow showers'**
  String get weatherSnowShowers;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm with hail'**
  String get weatherThunderstormWithHail;

  /// Weather condition, as in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get weatherUnknown;

  /// Temperature.
  ///
  /// In en, this message translates to:
  /// **'{value} °C'**
  String weatherDegrees(int value);

  /// Apparent temperature.
  ///
  /// In en, this message translates to:
  /// **'Feels like {value} °C'**
  String weatherFeelsLike(int value);

  /// Lowest and highest temperature of a day.
  ///
  /// In en, this message translates to:
  /// **'{min}° / {max}°'**
  String weatherRange(int min, int max);

  /// Chance of rain or snow.
  ///
  /// In en, this message translates to:
  /// **'{value} % rain'**
  String weatherPrecipitation(int value);

  /// Weather widget without a place.
  ///
  /// In en, this message translates to:
  /// **'Choose a place for this widget in the web interface.'**
  String get weatherNoPlace;

  /// Default title of the to-do widget.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get todosTitle;

  /// To-do widget without open to-dos.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do.'**
  String get todosEmpty;

  /// Screen reader label of a ticked-off to-do.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todosDone;

  /// Due date that has passed.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get todosOverdue;

  /// Due today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todosToday;

  /// Due tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get todosTomorrow;

  /// Default title of the notes widget.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// Notes widget without notes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get notesNone;

  /// Notes widget showing pinned notes, without any.
  ///
  /// In en, this message translates to:
  /// **'No pinned notes.'**
  String get notesNonePinned;

  /// Screen reader label of a pinned note.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notesPinned;

  /// Default title of the bookmarks widget.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTitle;

  /// Bookmarks widget without links.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet.'**
  String get bookmarksEmpty;

  /// Snack bar when no app could open a link.
  ///
  /// In en, this message translates to:
  /// **'The link could not be opened.'**
  String get linkOpenFailed;

  /// Button that opens the widget's tab in the web interface.
  ///
  /// In en, this message translates to:
  /// **'Open in Waylight'**
  String get dashboardOpenInWaylight;

  /// Default title of the departures widget.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get transitTitle;

  /// Departures widget without a stop.
  ///
  /// In en, this message translates to:
  /// **'Choose a stop for this widget in the web interface.'**
  String get transitNoStop;

  /// Departures widget without departures.
  ///
  /// In en, this message translates to:
  /// **'No departures in the next hours.'**
  String get transitEmpty;

  /// Departure leaves now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get transitNow;

  /// Minutes until a departure.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String transitInMinutes(int minutes);

  /// Delay in minutes.
  ///
  /// In en, this message translates to:
  /// **'+{minutes}'**
  String transitDelay(int minutes);

  /// Departure does not run.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get transitCancelled;

  /// Planned time and platform.
  ///
  /// In en, this message translates to:
  /// **'{time} · platform {track}'**
  String transitTimeTrack(String time, String track);

  /// Default title of the waste widget.
  ///
  /// In en, this message translates to:
  /// **'Waste collection'**
  String get wasteTitle;

  /// Waste widget while no calendar is set up.
  ///
  /// In en, this message translates to:
  /// **'Set up the waste calendar in the web interface.'**
  String get wasteNotConfigured;

  /// Waste widget without dates.
  ///
  /// In en, this message translates to:
  /// **'No collections ahead.'**
  String get wasteEmpty;

  /// Days until a collection.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String wasteInDays(int days);

  /// Age of a widget's data.
  ///
  /// In en, this message translates to:
  /// **'updated just now'**
  String get freshnessJustNow;

  /// Age of a widget's data.
  ///
  /// In en, this message translates to:
  /// **'updated {minutes} min ago'**
  String freshnessMinutesAgo(int minutes);

  /// Data older than twice its refresh interval.
  ///
  /// In en, this message translates to:
  /// **'outdated – {age}'**
  String freshnessStale(String age);

  /// The last reload failed; the older data stays.
  ///
  /// In en, this message translates to:
  /// **'refresh failed – {age}'**
  String freshnessFailed(String age);

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get settingsAddress;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Owner account'**
  String get settingsOwnerAccount;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get settingsRoleOwner;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get settingsRoleAdmin;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get settingsRoleMember;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get settingsRoleGuest;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get settingsLicence;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSource;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicences;

  /// Title while pairing from a QR code.
  ///
  /// In en, this message translates to:
  /// **'Connecting the app'**
  String get pairTitle;

  /// Pairing link without server or code.
  ///
  /// In en, this message translates to:
  /// **'This link is not a complete pairing code. Show a new QR code in Waylight under Settings → Mobile app.'**
  String get pairInvalidLink;

  /// Expired or used pairing code.
  ///
  /// In en, this message translates to:
  /// **'This pairing code is not valid any more. Show a new QR code in Waylight under Settings → Mobile app.'**
  String get pairCodeInvalid;

  /// Button to the connect screen after a failed pairing.
  ///
  /// In en, this message translates to:
  /// **'Enter the address instead'**
  String get pairEnterManually;

  /// Hint on the connect screen.
  ///
  /// In en, this message translates to:
  /// **'Or scan the QR code under Settings → Mobile app in Waylight with your phone\'s camera.'**
  String get connectQrHint;

  /// Button that connects the public demo.
  ///
  /// In en, this message translates to:
  /// **'Try the public demo'**
  String get connectTryDemo;

  /// Banner on the dashboard of the demo.
  ///
  /// In en, this message translates to:
  /// **'This is the public demo. Its data is reset every hour.'**
  String get dashboardDemo;

  /// Error: the server refused a change because of a newer version (409).
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this in the meantime. It was loaded again.'**
  String get errorConflict;

  /// Field to add a to-do.
  ///
  /// In en, this message translates to:
  /// **'New to-do'**
  String get todosAddLabel;

  /// Button that adds the to-do.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get todosAdd;

  /// Button that deletes all ticked-off to-dos.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get todosClearCompleted;

  /// Title field in the to-do sheet.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get todosTitleLabel;

  /// Validation of the title.
  ///
  /// In en, this message translates to:
  /// **'Enter a title.'**
  String get todosTitleRequired;

  /// Due date button without a date.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get todosNoDueDate;

  /// Tooltip of the button that removes the date.
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get todosRemoveDueDate;

  /// Button that deletes the to-do.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get todosDelete;

  /// Button that saves the to-do.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get todosSave;

  /// Banner while stored data is shown.
  ///
  /// In en, this message translates to:
  /// **'Offline · showing the data from {time}'**
  String dashboardOffline(String time);

  /// Button that starts the sign-in in the browser.
  ///
  /// In en, this message translates to:
  /// **'Sign in in the browser (passkey, Microsoft, SSO)'**
  String get signInBrowser;

  /// Title while the browser sign-in is finished.
  ///
  /// In en, this message translates to:
  /// **'Finishing the sign-in'**
  String get authCallbackTitle;

  /// The person cancelled in the browser.
  ///
  /// In en, this message translates to:
  /// **'The sign-in in the browser was cancelled.'**
  String get authCallbackCancelled;

  /// Answer without a matching started sign-in.
  ///
  /// In en, this message translates to:
  /// **'This sign-in was not started in this app, or it took too long. Please start it again.'**
  String get authCallbackUnexpected;

  /// Button back to the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Back to the sign-in'**
  String get authCallbackBack;

  /// Search field and button.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// Hint below the empty search field.
  ///
  /// In en, this message translates to:
  /// **'Type a keyword, a widget, \"t\" and a to-do, or anything to search the web.'**
  String get searchIntro;

  /// Last result: the web search.
  ///
  /// In en, this message translates to:
  /// **'Search the web for \"{query}\"'**
  String searchWeb(String query);

  /// Quick capture result.
  ///
  /// In en, this message translates to:
  /// **'Add to-do \"{title}\"'**
  String searchAddTodo(String title);

  /// Snack bar after quick capture.
  ///
  /// In en, this message translates to:
  /// **'To-do \"{title}\" added.'**
  String searchTodoAdded(String title);

  /// Subtitle of a widget result.
  ///
  /// In en, this message translates to:
  /// **'On the tab {tab}'**
  String searchOnTab(String tab);

  /// Title of the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Waylight is locked'**
  String get lockTitle;

  /// Button on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// Reason shown in the system's biometric prompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock Waylight'**
  String get lockReason;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsLock;

  /// Switch of the app lock.
  ///
  /// In en, this message translates to:
  /// **'Lock with fingerprint, face or device PIN'**
  String get settingsLockSwitch;

  /// Label of the lock timeout.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get settingsLockAfter;

  /// Lock timeout: at once.
  ///
  /// In en, this message translates to:
  /// **'At once'**
  String get settingsLockNow;

  /// Lock timeout in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String settingsLockMinutes(int minutes);

  /// Shortcut on the launcher icon.
  ///
  /// In en, this message translates to:
  /// **'Add to-do'**
  String get shortcutAddTodo;

  /// Shortcut on the launcher icon.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get shortcutDepartures;

  /// Marker of a to-do changed offline.
  ///
  /// In en, this message translates to:
  /// **'Not saved on the server yet'**
  String get todosPending;

  /// Banner when the server refused offline changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change could not be saved.} other{{count} changes could not be saved.}}'**
  String todosConflicts(int count);

  /// Button that opens the list of refused changes.
  ///
  /// In en, this message translates to:
  /// **'Decide'**
  String get todosConflictsDecide;

  /// Reason of a conflict.
  ///
  /// In en, this message translates to:
  /// **'Changed elsewhere in the meantime.'**
  String get todosConflictChanged;

  /// Reason of a rejected change.
  ///
  /// In en, this message translates to:
  /// **'The server refused it: {message}'**
  String todosConflictRejected(String message);

  /// Resend the change.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get todosKeepMine;

  /// Drop the change.
  ///
  /// In en, this message translates to:
  /// **'Keep the server\'s'**
  String get todosKeepServer;

  /// Drop a rejected change.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get todosDiscard;

  /// Title of a refused delete.
  ///
  /// In en, this message translates to:
  /// **'Deleted to-do'**
  String get todosDeletedTodo;

  /// Title of the tab editor.
  ///
  /// In en, this message translates to:
  /// **'Edit tab'**
  String get editTabTitle;

  /// Lets the phone layout follow the desktop grid again.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get editTabReset;

  /// Subtitle of a hidden widget.
  ///
  /// In en, this message translates to:
  /// **'Hidden on phones'**
  String get editTabHidden;

  /// Tooltip of the up button.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get editTabUp;

  /// Tooltip of the down button.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get editTabDown;

  /// Team tab or unknown tab.
  ///
  /// In en, this message translates to:
  /// **'This tab is shared with you and cannot be changed here.'**
  String get editTabNotEditable;

  /// Servers in the settings.
  ///
  /// In en, this message translates to:
  /// **'Switch to this server'**
  String get settingsSwitchServer;

  /// Servers in the settings.
  ///
  /// In en, this message translates to:
  /// **'Remove server'**
  String get settingsRemoveServer;

  /// Servers in the settings.
  ///
  /// In en, this message translates to:
  /// **'Add another server'**
  String get settingsAddServer;

  /// Default title of the system widget.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTitle;

  /// CPU usage in the system widget.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get systemCpu;

  /// Memory usage in the system widget.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get systemMemory;

  /// Swap usage in the system widget.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get systemSwap;

  /// Default title of the services widget.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// Services widget without services.
  ///
  /// In en, this message translates to:
  /// **'No services yet.'**
  String get servicesEmpty;

  /// A service that answers.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get servicesOnline;

  /// A service that does not answer.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get servicesOffline;

  /// A service not checked yet.
  ///
  /// In en, this message translates to:
  /// **'Unchecked'**
  String get servicesUnknown;

  /// Default title of the status overview.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusOverviewTitle;

  /// Default title of the backup monitoring widget.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get backupsTitle;

  /// Backup widget without sources.
  ///
  /// In en, this message translates to:
  /// **'No backups or jobs report yet.'**
  String get backupsEmpty;

  /// A backup that ran in time.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get backupsOk;

  /// A backup without a run in the expected time.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get backupsOverdue;

  /// A backup whose last run failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get backupsFailed;

  /// A backup that has not reported yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get backupsWaiting;

  /// Default title of the countdown widget.
  ///
  /// In en, this message translates to:
  /// **'Countdowns'**
  String get countdownTitle;

  /// Countdown widget without future dates.
  ///
  /// In en, this message translates to:
  /// **'No countdowns ahead.'**
  String get countdownEmpty;

  /// Default title of the birthdays widget.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get birthdaysTitle;

  /// Birthday widget without entries.
  ///
  /// In en, this message translates to:
  /// **'No birthdays yet.'**
  String get birthdaysEmpty;

  /// Default title of the electricity widget.
  ///
  /// In en, this message translates to:
  /// **'Electricity prices'**
  String get electricityTitle;

  /// Shown while only today's prices are known.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s prices follow around 1 pm.'**
  String get electricityTomorrowLater;

  /// Uptime of the host.
  ///
  /// In en, this message translates to:
  /// **'up {days} d {hours} h'**
  String systemUptime(int days, int hours);

  /// Load average of the last minute.
  ///
  /// In en, this message translates to:
  /// **'load {load}'**
  String systemLoad(String load);

  /// Used and total size of a disk.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total}'**
  String systemDiskOf(String used, String total);

  /// Forecast when a disk is full.
  ///
  /// In en, this message translates to:
  /// **'full in {days} days'**
  String systemFullIn(int days);

  /// Date of the last successful run.
  ///
  /// In en, this message translates to:
  /// **'last success {date}'**
  String backupsLastSuccess(String date);

  /// Age on the next birthday.
  ///
  /// In en, this message translates to:
  /// **'turns {age}'**
  String birthdaysTurns(int age);

  /// Current electricity price.
  ///
  /// In en, this message translates to:
  /// **'Now {price}'**
  String electricityNow(String price);

  /// Spoken list of the cheapest hours.
  ///
  /// In en, this message translates to:
  /// **'Cheapest hours: {hours}'**
  String electricityCheapest(String hours);

  /// Default title of the holidays widget.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysTitle;

  /// Holidays widget without entries.
  ///
  /// In en, this message translates to:
  /// **'No holidays ahead.'**
  String get holidaysEmpty;

  /// A holiday going on now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get holidaysNow;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'New Year\'s Day'**
  String get holidayNewYear;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Epiphany'**
  String get holidayEpiphany;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'International Women\'s Day'**
  String get holidayWomensDay;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Good Friday'**
  String get holidayGoodFriday;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Easter Sunday'**
  String get holidayEasterSunday;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Easter Monday'**
  String get holidayEasterMonday;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Labour Day'**
  String get holidayLabourDay;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Ascension Day'**
  String get holidayAscension;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Whit Sunday'**
  String get holidayWhitSunday;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Whit Monday'**
  String get holidayWhitMonday;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Corpus Christi'**
  String get holidayCorpusChristi;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Assumption Day'**
  String get holidayAssumption;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'World Children\'s Day'**
  String get holidayChildrensDay;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Day of German Unity'**
  String get holidayGermanUnity;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Reformation Day'**
  String get holidayReformation;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'All Saints\' Day'**
  String get holidayAllSaints;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Day of Repentance and Prayer'**
  String get holidayRepentance;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Christmas Day'**
  String get holidayChristmasDay;

  /// Public holiday.
  ///
  /// In en, this message translates to:
  /// **'Boxing Day'**
  String get holidayBoxingDay;

  /// Default title of the disk health widget.
  ///
  /// In en, this message translates to:
  /// **'Disk health'**
  String get diskHealthTitle;

  /// Disk health widget without disks.
  ///
  /// In en, this message translates to:
  /// **'No disks reported yet.'**
  String get diskHealthEmpty;

  /// A disk that needs attention.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get diskHealthWarning;

  /// A disk that is failing.
  ///
  /// In en, this message translates to:
  /// **'Failing'**
  String get diskHealthFailing;

  /// A disk without a current verdict.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get diskHealthUnknown;

  /// Default title of the Docker widget.
  ///
  /// In en, this message translates to:
  /// **'Docker'**
  String get dockerTitle;

  /// A container whose health check fails.
  ///
  /// In en, this message translates to:
  /// **'unhealthy'**
  String get dockerUnhealthy;

  /// A running Proxmox guest.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get proxmoxRunning;

  /// A stopped Proxmox guest.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get proxmoxStopped;

  /// Default title of the speed test widget.
  ///
  /// In en, this message translates to:
  /// **'Speed test'**
  String get speedtestTitle;

  /// Speed test widget without results.
  ///
  /// In en, this message translates to:
  /// **'No results yet.'**
  String get speedtestEmpty;

  /// Download speed.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get speedtestDownload;

  /// Upload speed.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get speedtestUpload;

  /// Ping time.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get speedtestPing;

  /// Default title of the timeline widget.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// Timeline widget without events.
  ///
  /// In en, this message translates to:
  /// **'Nothing happened yet.'**
  String get timelineEmpty;

  /// WireGuard widget without peers.
  ///
  /// In en, this message translates to:
  /// **'No peers yet.'**
  String get wireguardEmpty;

  /// Default title of the FRITZ!Box call list.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get callsTitle;

  /// Call list without calls.
  ///
  /// In en, this message translates to:
  /// **'No calls.'**
  String get callsEmpty;

  /// Spoken kind of a call.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get callsIncoming;

  /// Spoken kind of a call.
  ///
  /// In en, this message translates to:
  /// **'Outgoing call'**
  String get callsOutgoing;

  /// A missed call.
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get callsMissed;

  /// Spoken kind of a call.
  ///
  /// In en, this message translates to:
  /// **'Rejected call'**
  String get callsRejected;

  /// Default title of the AdGuard/Pi-hole widget.
  ///
  /// In en, this message translates to:
  /// **'DNS filter'**
  String get dnsFilterTitle;

  /// DNS blocking is on.
  ///
  /// In en, this message translates to:
  /// **'Protection on'**
  String get dnsFilterOn;

  /// DNS blocking is paused.
  ///
  /// In en, this message translates to:
  /// **'Protection paused'**
  String get dnsFilterPaused;

  /// Wear of an SSD.
  ///
  /// In en, this message translates to:
  /// **'{percent} % worn'**
  String diskHealthWear(int percent);

  /// Container counts.
  ///
  /// In en, this message translates to:
  /// **'{running} running · {stopped} stopped · {unhealthy} unhealthy'**
  String dockerSummary(int running, int stopped, int unhealthy);

  /// Average of recent results.
  ///
  /// In en, this message translates to:
  /// **'average {mbps} Mbit/s'**
  String speedtestAverage(int mbps);

  /// Date of the last handshake.
  ///
  /// In en, this message translates to:
  /// **'last handshake {date}'**
  String wireguardHandshake(String date);

  /// Queries in the last day.
  ///
  /// In en, this message translates to:
  /// **'{count} queries in 24 h'**
  String dnsFilterQueries(String count);

  /// Blocked queries.
  ///
  /// In en, this message translates to:
  /// **'Blocked: {count}'**
  String dnsFilterBlocked(String count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
