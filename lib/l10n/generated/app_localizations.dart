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

  /// Default title of the briefing widget.
  ///
  /// In en, this message translates to:
  /// **'Daily briefing'**
  String get briefingTitle;

  /// Briefing section.
  ///
  /// In en, this message translates to:
  /// **'Weather warnings'**
  String get briefingWarnings;

  /// Briefing section with failures.
  ///
  /// In en, this message translates to:
  /// **'Since last evening'**
  String get briefingIncidents;

  /// Briefing section.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get briefingTodos;

  /// Briefing section.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get briefingEvents;

  /// Health warnings of Sonarr/Radarr.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get arrHealth;

  /// Upcoming episodes and films.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get arrUpcoming;

  /// Download queue.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get arrQueue;

  /// Default title of the media widget.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaTitle;

  /// Media playing now.
  ///
  /// In en, this message translates to:
  /// **'Playing now'**
  String get mediaPlaying;

  /// Recently added media.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get mediaRecent;

  /// Default title of the music releases widget.
  ///
  /// In en, this message translates to:
  /// **'New releases'**
  String get releasesTitle;

  /// Default title of the game deals widget.
  ///
  /// In en, this message translates to:
  /// **'Game deals'**
  String get gameDealsTitle;

  /// Free games now.
  ///
  /// In en, this message translates to:
  /// **'Free now'**
  String get gameDealsFree;

  /// Discounted games.
  ///
  /// In en, this message translates to:
  /// **'On sale'**
  String get gameDealsDeals;

  /// Free games next.
  ///
  /// In en, this message translates to:
  /// **'Free soon'**
  String get gameDealsNext;

  /// Default title of the space widget.
  ///
  /// In en, this message translates to:
  /// **'Rocket launches'**
  String get spaceTitle;

  /// Default title of the read later widget.
  ///
  /// In en, this message translates to:
  /// **'Read later'**
  String get readLaterTitle;

  /// A list widget without entries.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get listEmpty;

  /// Default title of the fuel widget.
  ///
  /// In en, this message translates to:
  /// **'Fuel prices'**
  String get fuelTitle;

  /// Fuel widget without stations.
  ///
  /// In en, this message translates to:
  /// **'No stations found.'**
  String get fuelEmpty;

  /// A closed station.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get fuelClosed;

  /// Default title of the markets widget.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get marketsTitle;

  /// Default title of the calendar widget.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// Calendar widget without events.
  ///
  /// In en, this message translates to:
  /// **'No appointments ahead.'**
  String get calendarEmpty;

  /// An all-day event.
  ///
  /// In en, this message translates to:
  /// **'all day'**
  String get calendarAllDay;

  /// Default title of the phone list widget.
  ///
  /// In en, this message translates to:
  /// **'Phone list'**
  String get phoneListTitle;

  /// Phone list without entries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get phoneListEmpty;

  /// Default title of the study widget.
  ///
  /// In en, this message translates to:
  /// **'Study progress'**
  String get studyTitle;

  /// Weighted grade average.
  ///
  /// In en, this message translates to:
  /// **'Average grade'**
  String get studyAverage;

  /// A module in progress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get studyInProgress;

  /// Number of photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get appPhotos;

  /// Number of videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get appVideos;

  /// Number of accounts.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get appUsers;

  /// Pending app updates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get appUpdates;

  /// Nextcloud in maintenance mode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get appMaintenance;

  /// Used storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get appStorage;

  /// Default title of the sports widget.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sportsTitle;

  /// More entries than shown.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String listMore(int count);

  /// Passed credits.
  ///
  /// In en, this message translates to:
  /// **'{passed} of {total} credits'**
  String studyCredits(String passed, String total);

  /// Games played.
  ///
  /// In en, this message translates to:
  /// **'{games} games'**
  String sportsPlayed(int games);

  /// Points in the table.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String sportsPoints(int points);

  /// Default title of the shopping widget.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingTitle;

  /// Shopping widget without a list.
  ///
  /// In en, this message translates to:
  /// **'Create a shopping list in the web interface first.'**
  String get shoppingNotConfigured;

  /// Shopping list without items.
  ///
  /// In en, this message translates to:
  /// **'Nothing to buy.'**
  String get shoppingEmpty;

  /// Field and button to add an item.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shoppingAdd;

  /// Default title of the habits widget.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTitle;

  /// Habits widget without habits due.
  ///
  /// In en, this message translates to:
  /// **'No habits due today.'**
  String get habitsEmpty;

  /// Button that removes ticked-off items.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} in the basket'**
  String shoppingClear(int count);

  /// Current and best streak.
  ///
  /// In en, this message translates to:
  /// **'{current} days in a row · best {best}'**
  String habitsStreak(int current, int best);

  /// Default title of the feed widget.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get rssTitle;

  /// Feed widget without unread items.
  ///
  /// In en, this message translates to:
  /// **'All caught up.'**
  String get rssCaughtUp;

  /// Button on a feed item.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get rssMarkRead;

  /// Button on a read feed item.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get rssMarkUnread;

  /// Default title of the parcels widget.
  ///
  /// In en, this message translates to:
  /// **'Parcels'**
  String get parcelsTitle;

  /// Parcels widget without parcels.
  ///
  /// In en, this message translates to:
  /// **'No parcels on their way.'**
  String get parcelsEmpty;

  /// Button and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Add parcel'**
  String get parcelsAdd;

  /// Field for the tracking number.
  ///
  /// In en, this message translates to:
  /// **'Tracking number'**
  String get parcelsNumber;

  /// Field for a description.
  ///
  /// In en, this message translates to:
  /// **'What is it? (optional)'**
  String get parcelsLabel;

  /// Closes the dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get parcelsCancel;

  /// Opens the tracking page.
  ///
  /// In en, this message translates to:
  /// **'Track at the carrier'**
  String get parcelsTrack;

  /// Deletes the parcel.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get parcelsDelete;

  /// Parcel not handed over yet.
  ///
  /// In en, this message translates to:
  /// **'announced'**
  String get parcelsAnnounced;

  /// Parcel in transit.
  ///
  /// In en, this message translates to:
  /// **'on its way'**
  String get parcelsOnTheWay;

  /// Delivered parcel.
  ///
  /// In en, this message translates to:
  /// **'delivered'**
  String get parcelsDelivered;

  /// Parcel with an unusual state.
  ///
  /// In en, this message translates to:
  /// **'check'**
  String get parcelsCheck;

  /// Default title of the smart home widget.
  ///
  /// In en, this message translates to:
  /// **'Smart home'**
  String get smartHomeTitle;

  /// Smart home widget without entities.
  ///
  /// In en, this message translates to:
  /// **'Choose entities in the web interface.'**
  String get smartHomeEmpty;

  /// Runs a scene or presses a button.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get smartHomeRun;

  /// Expected delivery date.
  ///
  /// In en, this message translates to:
  /// **'expected {date}'**
  String parcelsExpected(String date);

  /// Default title of the photo frame.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photoFrameTitle;

  /// Photo frame without photos.
  ///
  /// In en, this message translates to:
  /// **'No photos in this album yet.'**
  String get photoFrameEmpty;

  /// Default title of the radar widget.
  ///
  /// In en, this message translates to:
  /// **'Rain radar'**
  String get radarTitle;

  /// Radar widget without a place.
  ///
  /// In en, this message translates to:
  /// **'Choose a place in the web interface.'**
  String get radarNoPlace;

  /// NASA astronomy picture of the day.
  ///
  /// In en, this message translates to:
  /// **'Picture of the day'**
  String get apodTitle;

  /// JSON widget without an endpoint.
  ///
  /// In en, this message translates to:
  /// **'Choose an endpoint in the web interface.'**
  String get apiWidgetNoEndpoint;

  /// Default title of the mail widget.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get mailTitle;

  /// Default title of the drop zone.
  ///
  /// In en, this message translates to:
  /// **'Drop zone'**
  String get dropTitle;

  /// Drop zone without items.
  ///
  /// In en, this message translates to:
  /// **'Nothing dropped yet.'**
  String get dropEmpty;

  /// Default title of the focus timer.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// Starts a focus session.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get focusStart;

  /// Stops a focus session.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get focusStop;

  /// Unread count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 unread messages} =1{1 unread message} other{{count} unread messages}}'**
  String mailUnread(int count);

  /// Focus time today.
  ///
  /// In en, this message translates to:
  /// **'Today: {minutes} min in {sessions} sessions'**
  String focusToday(int minutes, int sessions);

  /// Opens a service in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get servicesOpen;

  /// Sends Wake-on-LAN to a service.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get servicesWake;

  /// Restarts a container.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get dockerRestart;

  /// Shows the log of a container.
  ///
  /// In en, this message translates to:
  /// **'Show log'**
  String get dockerLogs;

  /// Starts a Proxmox guest.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get proxmoxStart;

  /// Shuts a Proxmox guest down.
  ///
  /// In en, this message translates to:
  /// **'Shut down'**
  String get proxmoxShutdown;

  /// After sending Wake-on-LAN.
  ///
  /// In en, this message translates to:
  /// **'Wake-up sent to {name}.'**
  String servicesWakeSent(String name);

  /// Confirmation before a restart.
  ///
  /// In en, this message translates to:
  /// **'Restart {name}?'**
  String dockerRestartConfirm(String name);

  /// After a restart was sent.
  ///
  /// In en, this message translates to:
  /// **'{name} is restarting.'**
  String dockerRestarted(String name);

  /// After a power action was sent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}.'**
  String proxmoxSent(String name);

  /// Pauses DNS blocking.
  ///
  /// In en, this message translates to:
  /// **'Pause for {minutes} minutes'**
  String dnsFilterPause(int minutes);

  /// Spoken label of a warning.
  ///
  /// In en, this message translates to:
  /// **'Weather warning'**
  String get weatherWarning;

  /// Today's UV index.
  ///
  /// In en, this message translates to:
  /// **'UV index today'**
  String get weatherUv;

  /// End of a warning.
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String weatherWarningUntil(String time);

  /// New event of the calendar.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calendarNewEvent;

  /// Title of a new event.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get calendarEventTitle;

  /// Location of a new event.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get calendarEventLocation;

  /// Saves a new event.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get calendarSave;

  /// Opens the calendar screen.
  ///
  /// In en, this message translates to:
  /// **'Show agenda'**
  String get calendarShowAll;

  /// Opens the shopping list screen.
  ///
  /// In en, this message translates to:
  /// **'Open list'**
  String get shoppingOpen;

  /// After a new event was saved.
  ///
  /// In en, this message translates to:
  /// **'Added {title}.'**
  String calendarEventAdded(String title);

  /// Opens the smart home screen.
  ///
  /// In en, this message translates to:
  /// **'All devices'**
  String get smartHomeAll;

  /// Opens the feed reader.
  ///
  /// In en, this message translates to:
  /// **'Open reader'**
  String get rssOpen;

  /// Marks every item read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get rssAllRead;

  /// Filter: unread items only.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get rssUnreadOnly;

  /// Filter: all feeds.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rssAllFeeds;

  /// Opens the timeline screen.
  ///
  /// In en, this message translates to:
  /// **'All events'**
  String get timelineOpen;

  /// Filter: all events.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get timelineAll;

  /// Filter: critical events.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get timelineCritical;

  /// Title of the editor for a new note.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteNew;

  /// Title of the editor.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEdit;

  /// Hint of the note text.
  ///
  /// In en, this message translates to:
  /// **'Text (Markdown)'**
  String get noteBodyHint;

  /// After saving a note.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// Saving failed because of a newer version.
  ///
  /// In en, this message translates to:
  /// **'This note was changed elsewhere. Reload it and edit again.'**
  String get noteConflict;

  /// Saving without a title.
  ///
  /// In en, this message translates to:
  /// **'Give the note a title.'**
  String get noteTitleMissing;

  /// Deletes a note.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get noteDelete;

  /// Confirmation before deleting a note.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get noteDeleteConfirm;

  /// Pins a note.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get notePin;

  /// Unpins a note.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get noteUnpin;

  /// Spoken label of an unread article.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get readLaterUnread;

  /// Saves a link to read later.
  ///
  /// In en, this message translates to:
  /// **'Save link'**
  String get readLaterSave;

  /// Opens the article's page.
  ///
  /// In en, this message translates to:
  /// **'Open original'**
  String get readLaterOriginal;

  /// Archives an article.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get readLaterArchive;

  /// Article without a reader copy.
  ///
  /// In en, this message translates to:
  /// **'There is no reader copy of this page; open the original.'**
  String get readLaterNoCopy;

  /// Sends a text to the drop zone.
  ///
  /// In en, this message translates to:
  /// **'Send text'**
  String get dropSend;

  /// Opens the service details.
  ///
  /// In en, this message translates to:
  /// **'Uptime and outages'**
  String get serviceDetails;

  /// Heading of the uptime card.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get serviceUptime;

  /// Uptime period.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get serviceDay;

  /// Uptime period.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get serviceWeek;

  /// Uptime period.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get serviceMonth;

  /// Uptime period.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get serviceQuarter;

  /// Heading of the outages card.
  ///
  /// In en, this message translates to:
  /// **'Outages'**
  String get serviceIncidents;

  /// Service without outages.
  ///
  /// In en, this message translates to:
  /// **'No outages recorded.'**
  String get serviceNoIncidents;

  /// An ongoing outage.
  ///
  /// In en, this message translates to:
  /// **'Down since {time}'**
  String serviceDownSince(String time);

  /// Account security screen.
  ///
  /// In en, this message translates to:
  /// **'Password and sign-in'**
  String get securityTitle;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get securityPassword;

  /// Button and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get securityChangePassword;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get securityCurrentPassword;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get securityNewPassword;

  /// After changing the password.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Other devices are signed out.'**
  String get securityPasswordChanged;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in'**
  String get securityTotp;

  /// Two-factor is on.
  ///
  /// In en, this message translates to:
  /// **'On: a code from your authenticator app is asked at sign-in.'**
  String get securityTotpOn;

  /// Two-factor is off.
  ///
  /// In en, this message translates to:
  /// **'Off.'**
  String get securityTotpIsOff;

  /// Starts the two-factor setup.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get securityTotpSetUp;

  /// Turns two-factor off.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get securityTotpOff;

  /// Setup instructions.
  ///
  /// In en, this message translates to:
  /// **'Add this key to your authenticator app, or open the app directly, then enter the code it shows.'**
  String get securityTotpHint;

  /// Opens the otpauth link.
  ///
  /// In en, this message translates to:
  /// **'Open authenticator app'**
  String get securityOpenAuthenticator;

  /// Field for a one-time code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get securityCode;

  /// Confirms the setup.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get securityConfirm;

  /// Dialog with one-time recovery codes.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes'**
  String get securityRecoveryCodes;

  /// Closes the recovery codes.
  ///
  /// In en, this message translates to:
  /// **'I saved them'**
  String get securityCodesSaved;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get securitySessions;

  /// The app's own session.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get securityThisDevice;

  /// Signs out one session.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get securitySignOutSession;

  /// Signs out every other session.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices'**
  String get securitySignOutOthers;

  /// After revoking a session.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get securitySessionEnded;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Turns push notifications on.
  ///
  /// In en, this message translates to:
  /// **'Notifications on this phone'**
  String get settingsPushSwitch;

  /// Explains push notifications.
  ///
  /// In en, this message translates to:
  /// **'Messages of Waylight’s notification rules arrive end-to-end encrypted. Turn on the channel “Waylight app” in the web interface too.'**
  String get settingsPushHint;

  /// Permission denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for this app in the system settings.'**
  String get settingsPushDenied;

  /// F-Droid build or no Firebase.
  ///
  /// In en, this message translates to:
  /// **'This version of the app has no push notifications.'**
  String get settingsPushNotInBuild;

  /// Asks the local AI for a summary.
  ///
  /// In en, this message translates to:
  /// **'Summarise'**
  String get summaryAction;

  /// Heading of the summary sheet.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// Notice below an AI summary.
  ///
  /// In en, this message translates to:
  /// **'Written by the server\'s local AI; it can be wrong.'**
  String get summaryByAi;

  /// Button and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get bookmarkAdd;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit bookmark'**
  String get bookmarkEdit;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get bookmarkFolder;

  /// Choice.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get bookmarkNoFolder;

  /// Button below a search answer.
  ///
  /// In en, this message translates to:
  /// **'Open widget'**
  String get searchOpenWidget;

  /// Title of the share screen.
  ///
  /// In en, this message translates to:
  /// **'Save to Waylight'**
  String get shareTitle;

  /// Share target.
  ///
  /// In en, this message translates to:
  /// **'As a to-do'**
  String get shareTodo;

  /// Share target.
  ///
  /// In en, this message translates to:
  /// **'As a note'**
  String get shareNote;

  /// After saving shared content.
  ///
  /// In en, this message translates to:
  /// **'Saved: {target}'**
  String shareSaved(String target);

  /// Home screen widget title.
  ///
  /// In en, this message translates to:
  /// **'To-dos today'**
  String get homeWidgetTodos;

  /// Home screen widget, no to-dos.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get homeWidgetTodosEmpty;

  /// Home screen widget title.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get homeWidgetDepartures;

  /// Home screen widget without a stop.
  ///
  /// In en, this message translates to:
  /// **'Add a transit widget with a stop to the dashboard'**
  String get homeWidgetNoStop;

  /// Home screen widget, nothing leaves.
  ///
  /// In en, this message translates to:
  /// **'No departures'**
  String get homeWidgetNoDepartures;

  /// A cancelled departure.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get homeWidgetCancelled;

  /// Age of a home screen widget.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String homeWidgetUpdated(String time);

  /// Field below an AI summary to ask a question.
  ///
  /// In en, this message translates to:
  /// **'Ask about it'**
  String get summaryAsk;

  /// Grafana widgets (#165).
  ///
  /// In en, this message translates to:
  /// **'Grafana alerts'**
  String get grafanaAlertsTitle;

  /// Grafana widgets (#165).
  ///
  /// In en, this message translates to:
  /// **'No alert is firing.'**
  String get grafanaAllQuiet;

  /// Grafana widgets (#165).
  ///
  /// In en, this message translates to:
  /// **'firing'**
  String get grafanaFiring;

  /// Grafana widgets (#165).
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get grafanaPending;

  /// Grafana widgets (#165).
  ///
  /// In en, this message translates to:
  /// **'Alert list'**
  String get grafanaAlertList;

  /// Grafana widgets (#165).
  ///
  /// In en, this message translates to:
  /// **'Grafana panel'**
  String get grafanaPanelTitle;

  /// Grafana widgets (#165).
  ///
  /// In en, this message translates to:
  /// **'Choose a dashboard and a panel in the web interface.'**
  String get grafanaChoosePanel;

  /// Screen reader text of a panel image.
  ///
  /// In en, this message translates to:
  /// **'Grafana panel {title}'**
  String grafanaPanelAlt(String title);

  /// Privacy note of the store flavour, which can receive push notifications through Google (#176).
  ///
  /// In en, this message translates to:
  /// **'Your data goes to your server only. If you switch on push notifications, Google delivers them, end-to-end encrypted.'**
  String get connectPrivacyPush;
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
