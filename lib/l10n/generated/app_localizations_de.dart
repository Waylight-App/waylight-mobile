// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Waylight';

  @override
  String get connectTitle => 'Verbinde dein Waylight';

  @override
  String get connectIntro =>
      'Gib die Adresse ein, mit der du Waylight im Browser öffnest.';

  @override
  String get connectAddressLabel => 'Serveradresse';

  @override
  String get connectAddressHint => 'https://home.example.org';

  @override
  String get connectButton => 'Verbinden';

  @override
  String get connectErrorEmpty => 'Gib die Adresse deines Servers ein.';

  @override
  String get connectErrorInvalid =>
      'Das ist keine gültige Adresse. Beispiel: https://home.example.org';

  @override
  String get connectErrorScheme =>
      'Die Adresse muss mit http:// oder https:// beginnen.';

  @override
  String get connectErrorParts =>
      'Lass Benutzername, Passwort und alles nach ? oder # weg.';

  @override
  String get connectErrorNotWaylight =>
      'Unter dieser Adresse antwortet kein Waylight-Server.';

  @override
  String get connectInsecureWarning =>
      'Ohne https:// wird dein Passwort unverschlüsselt übertragen. Nutze das nur in deinem eigenen Netz.';

  @override
  String homeConnectedTo(String server) {
    return 'Verbunden mit $server';
  }

  @override
  String get homeSetupRequired =>
      'Dieser Server hat noch kein Konto. Schließe zuerst die Einrichtung im Browser ab.';

  @override
  String get homeComingSoon =>
      'Anmeldung und dein Dashboard folgen in den nächsten Versionen.';

  @override
  String get homeDisconnect => 'Anderen Server verwenden';

  @override
  String get connectPrivacy =>
      'Die App spricht nur mit deinem Server und mit niemandem sonst.';

  @override
  String get homeServerTitle => 'Server';

  @override
  String get errorUnreachable =>
      'Der Server ist nicht erreichbar. Ist dein Handy im selben Netz oder VPN?';

  @override
  String get errorUnauthorized =>
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.';

  @override
  String get errorForbidden => 'Dein Konto darf das nicht.';

  @override
  String get errorNotFound =>
      'Das gibt es auf deinem Server nicht. Vielleicht ist das Modul abgeschaltet.';

  @override
  String get errorInvalid => 'Bitte prüfe deine Eingabe.';

  @override
  String get errorTooManyRequests =>
      'Zu viele Versuche. Bitte warte ein paar Minuten und versuche es dann erneut.';

  @override
  String get errorServer =>
      'Der Server hat mit einem Fehler geantwortet. Bitte versuche es später noch einmal.';

  @override
  String get errorUnknown =>
      'Etwas ist schiefgelaufen. Bitte versuche es noch einmal.';
}
