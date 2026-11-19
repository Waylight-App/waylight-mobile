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

  /// Tooltip of the account menu in the app bar.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get dashboardMenu;

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
