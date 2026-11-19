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
  String get homeSetupRequired =>
      'Dieser Server hat noch kein Konto. Schließe zuerst die Einrichtung im Browser ab.';

  @override
  String get homeDisconnect => 'Anderen Server verwenden';

  @override
  String get connectPrivacy =>
      'Die App spricht nur mit deinem Server und mit niemandem sonst.';

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

  @override
  String get signInTitle => 'Anmelden';

  @override
  String signInServer(String server) {
    return 'bei $server';
  }

  @override
  String get signInExpired =>
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.';

  @override
  String get signInUsernameLabel => 'Kontoname';

  @override
  String get signInUsernameHelper => 'Für das Eigentümerkonto leer lassen.';

  @override
  String get signInPasswordLabel => 'Passwort';

  @override
  String get signInCodeLabel => 'Code';

  @override
  String get signInCodeHint =>
      'Der Code aus deiner Authenticator-App oder ein Wiederherstellungscode.';

  @override
  String get signInCodeHintRecovery =>
      'Dieses Konto nutzt einen Passkey. Gib einen deiner Wiederherstellungscodes ein.';

  @override
  String get signInButton => 'Anmelden';

  @override
  String get signInErrorCredentials => 'Kontoname oder Passwort ist falsch.';

  @override
  String get signInErrorCode => 'Passwort oder Code ist falsch.';

  @override
  String get homeSignOut => 'Abmelden';

  @override
  String get dashboardWidgetNotYet => 'Noch nicht in der App verfügbar.';

  @override
  String get dashboardRetry => 'Erneut versuchen';

  @override
  String get dashboardNoTabs =>
      'Für dein Konto gibt es noch keine Tabs. Lege einen in der Weboberfläche an.';

  @override
  String get dashboardEmptyTab => 'Dieser Tab hat noch keine Widgets.';

  @override
  String get connectErrorInsecure =>
      'Unverschlüsseltes http:// geht nur mit Adressen in deinem Heimnetz. Nutze für diesen Server https://.';

  @override
  String get weatherClearSky => 'Klarer Himmel';

  @override
  String get weatherMainlyClear => 'Überwiegend klar';

  @override
  String get weatherPartlyCloudy => 'Teilweise bewölkt';

  @override
  String get weatherOvercast => 'Bedeckt';

  @override
  String get weatherFog => 'Nebel';

  @override
  String get weatherRimeFog => 'Raureifnebel';

  @override
  String get weatherLightDrizzle => 'Leichter Nieselregen';

  @override
  String get weatherDrizzle => 'Nieselregen';

  @override
  String get weatherDenseDrizzle => 'Starker Nieselregen';

  @override
  String get weatherFreezingDrizzle => 'Gefrierender Nieselregen';

  @override
  String get weatherLightRain => 'Leichter Regen';

  @override
  String get weatherRain => 'Regen';

  @override
  String get weatherHeavyRain => 'Starker Regen';

  @override
  String get weatherFreezingRain => 'Gefrierender Regen';

  @override
  String get weatherLightSnow => 'Leichter Schneefall';

  @override
  String get weatherSnow => 'Schneefall';

  @override
  String get weatherHeavySnow => 'Starker Schneefall';

  @override
  String get weatherSnowGrains => 'Schneegriesel';

  @override
  String get weatherRainShowers => 'Regenschauer';

  @override
  String get weatherViolentShowers => 'Heftige Schauer';

  @override
  String get weatherSnowShowers => 'Schneeschauer';

  @override
  String get weatherThunderstorm => 'Gewitter';

  @override
  String get weatherThunderstormWithHail => 'Gewitter mit Hagel';

  @override
  String get weatherUnknown => 'Unbekannt';

  @override
  String weatherDegrees(int value) {
    return '$value °C';
  }

  @override
  String weatherFeelsLike(int value) {
    return 'Gefühlt $value °C';
  }

  @override
  String weatherRange(int min, int max) {
    return '$min° / $max°';
  }

  @override
  String weatherPrecipitation(int value) {
    return '$value % Regen';
  }

  @override
  String get weatherNoPlace =>
      'Wähle für dieses Widget in der Weboberfläche einen Ort.';

  @override
  String get todosTitle => 'To-dos';

  @override
  String get todosEmpty => 'Nichts zu tun.';

  @override
  String get todosDone => 'Erledigt';

  @override
  String get todosOverdue => 'Überfällig';

  @override
  String get todosToday => 'Heute';

  @override
  String get todosTomorrow => 'Morgen';

  @override
  String get notesTitle => 'Notizen';

  @override
  String get notesNone => 'Noch keine Notizen.';

  @override
  String get notesNonePinned => 'Keine angehefteten Notizen.';

  @override
  String get notesPinned => 'Angeheftet';

  @override
  String get bookmarksTitle => 'Lesezeichen';

  @override
  String get bookmarksEmpty => 'Noch keine Lesezeichen.';

  @override
  String get linkOpenFailed => 'Der Link konnte nicht geöffnet werden.';

  @override
  String get dashboardOpenInWaylight => 'In Waylight öffnen';

  @override
  String get transitTitle => 'Abfahrten';

  @override
  String get transitNoStop =>
      'Wähle für dieses Widget in der Weboberfläche eine Haltestelle.';

  @override
  String get transitEmpty => 'Keine Abfahrten in den nächsten Stunden.';

  @override
  String get transitNow => 'jetzt';

  @override
  String transitInMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String transitDelay(int minutes) {
    return '+$minutes';
  }

  @override
  String get transitCancelled => 'fällt aus';

  @override
  String transitTimeTrack(String time, String track) {
    return '$time · Gleis $track';
  }

  @override
  String get wasteTitle => 'Müllabfuhr';

  @override
  String get wasteNotConfigured =>
      'Richte den Müllkalender in der Weboberfläche ein.';

  @override
  String get wasteEmpty => 'Keine anstehenden Abholungen.';

  @override
  String wasteInDays(int days) {
    return 'in $days Tagen';
  }

  @override
  String get freshnessJustNow => 'gerade aktualisiert';

  @override
  String freshnessMinutesAgo(int minutes) {
    return 'vor $minutes Min. aktualisiert';
  }

  @override
  String freshnessStale(String age) {
    return 'veraltet – $age';
  }

  @override
  String freshnessFailed(String age) {
    return 'Aktualisierung fehlgeschlagen – $age';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAddress => 'Adresse';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsOwnerAccount => 'Eigentümerkonto';

  @override
  String get settingsRoleOwner => 'Eigentümer';

  @override
  String get settingsRoleAdmin => 'Admin';

  @override
  String get settingsRoleMember => 'Mitglied';

  @override
  String get settingsRoleGuest => 'Gast';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLight => 'Hell';

  @override
  String get settingsDark => 'Dunkel';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsAppVersion => 'App-Version';

  @override
  String get settingsLicence => 'Lizenz';

  @override
  String get settingsSource => 'Quellcode';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsLicences => 'Open-Source-Lizenzen';

  @override
  String get pairTitle => 'App wird verbunden';

  @override
  String get pairInvalidLink =>
      'Dieser Link enthält keinen vollständigen Kopplungscode. Lass dir in Waylight unter Einstellungen → Mobile App einen neuen QR-Code anzeigen.';

  @override
  String get pairCodeInvalid =>
      'Dieser Kopplungscode ist nicht mehr gültig. Lass dir in Waylight unter Einstellungen → Mobile App einen neuen QR-Code anzeigen.';

  @override
  String get pairEnterManually => 'Adresse stattdessen eingeben';

  @override
  String get connectQrHint =>
      'Oder scanne den QR-Code unter Einstellungen → Mobile App in Waylight mit der Kamera deines Handys.';

  @override
  String get connectTryDemo => 'Öffentliche Demo ausprobieren';

  @override
  String get dashboardDemo =>
      'Das ist die öffentliche Demo. Ihre Daten werden stündlich zurückgesetzt.';

  @override
  String get errorConflict =>
      'Jemand anderes hat das inzwischen geändert. Es wurde neu geladen.';

  @override
  String get todosAddLabel => 'Neues To-do';

  @override
  String get todosAdd => 'Hinzufügen';

  @override
  String get todosClearCompleted => 'Erledigte entfernen';

  @override
  String get todosTitleLabel => 'Titel';

  @override
  String get todosTitleRequired => 'Gib einen Titel ein.';

  @override
  String get todosNoDueDate => 'Kein Fälligkeitsdatum';

  @override
  String get todosRemoveDueDate => 'Fälligkeitsdatum entfernen';

  @override
  String get todosDelete => 'Löschen';

  @override
  String get todosSave => 'Speichern';

  @override
  String dashboardOffline(String time) {
    return 'Offline · Daten von $time';
  }

  @override
  String get signInBrowser => 'Im Browser anmelden (Passkey, Microsoft, SSO)';

  @override
  String get authCallbackTitle => 'Anmeldung wird abgeschlossen';

  @override
  String get authCallbackCancelled =>
      'Die Anmeldung im Browser wurde abgebrochen.';

  @override
  String get authCallbackUnexpected =>
      'Diese Anmeldung wurde nicht in dieser App gestartet oder hat zu lange gedauert. Bitte starte sie erneut.';

  @override
  String get authCallbackBack => 'Zurück zur Anmeldung';
}
