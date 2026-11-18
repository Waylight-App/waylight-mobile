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
  String homeConnectedTo(String server) {
    return 'Connected to $server';
  }

  @override
  String get homeSetupRequired =>
      'This server has no account yet. Finish the setup in your browser first.';

  @override
  String get homeComingSoon => 'Your dashboard follows in the next version.';

  @override
  String get homeDisconnect => 'Use another server';

  @override
  String get connectPrivacy => 'The app talks to your server and nobody else.';

  @override
  String get homeServerTitle => 'Server';

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
}
