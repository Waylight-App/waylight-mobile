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
  String get connectPrivacy => 'Dein Waylight. Deine Daten. Dein Server.';

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
  String get weatherNoPlace => 'Noch kein Ort gewählt.';

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
  String get attentionTitle => 'Braucht deine Aufmerksamkeit';

  @override
  String attentionBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sachen brauchen deine Aufmerksamkeit',
      one: '1 Sache braucht deine Aufmerksamkeit',
    );
    return '$_temp0';
  }

  @override
  String get attentionBroken => 'Funktioniert nicht mehr';

  @override
  String get attentionSetup => 'Noch nicht eingerichtet';

  @override
  String get attentionEmpty => 'Alles ist eingerichtet und funktioniert.';

  @override
  String get attentionSignIn => 'Neu anmelden';

  @override
  String get attentionCheck => 'Erneut prüfen';

  @override
  String get attentionFix => 'Zugang korrigieren';

  @override
  String get attentionChoose => 'Einrichten';

  @override
  String get attentionConnect => 'Verbinden';

  @override
  String get attentionStillBroken => 'Funktioniert immer noch nicht.';

  @override
  String get dashboardOpenInWaylight => 'In Waylight öffnen';

  @override
  String get transitTitle => 'Abfahrten';

  @override
  String get transitNoStop => 'Noch keine Haltestelle gewählt.';

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
  String get wasteNotConfigured => 'Noch kein Müllkalender eingerichtet.';

  @override
  String get setUpAction => 'Einrichten';

  @override
  String get setUpMissing => 'Dieses Widget ist noch nicht eingerichtet.';

  @override
  String get setUpSearchHint => 'Mindestens zwei Buchstaben eingeben';

  @override
  String get setUpNoResults => 'Nichts gefunden.';

  @override
  String get setUpStopTitle => 'Haltestelle wählen';

  @override
  String get setUpPlaceTitle => 'Ort wählen';

  @override
  String get setUpWasteTitle => 'Müllkalender abonnieren';

  @override
  String get setUpWasteHint =>
      'Die Adresse des Kalenders (ICS) deines Entsorgers, beginnend mit https:// oder webcal://.';

  @override
  String get setUpWasteLabel => 'Kalenderadresse';

  @override
  String get setUpSave => 'Speichern';

  @override
  String get setUpCancel => 'Abbrechen';

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
  String get pairWatchTitle => 'Uhr koppeln';

  @override
  String get pairWatchEntry => 'Uhr koppeln';

  @override
  String get pairWatchIntro =>
      'Öffne Waylight auf deiner Wear-OS-Uhr und wähle „Mit Handy koppeln“. Die Uhr zeigt einen QR-Code. Beide Geräte müssen im selben WLAN sein.';

  @override
  String get pairWatchScan => 'Code der Uhr scannen';

  @override
  String get pairWatchScanAgain => 'Anderen Code scannen';

  @override
  String get pairWatchScanPrompt => 'Richte die Kamera auf den QR-Code der Uhr';

  @override
  String pairWatchFound(String address) {
    return 'Uhr gefunden unter $address';
  }

  @override
  String get pairWatchSend => 'Diese Uhr koppeln';

  @override
  String get pairWatchDone =>
      'Die Uhr ist gekoppelt. Sie erscheint in Waylight unter Einstellungen → Apps, wo du sie auch abmelden kannst.';

  @override
  String get pairWatchUnavailable =>
      'Zum Koppeln einer Uhr brauchst du die Android-App.';

  @override
  String get pairWatchInvalidCode =>
      'Das ist nicht der Code einer Waylight-Uhr. Öffne auf der Uhr „Mit Handy koppeln“ und scanne den Code, den sie zeigt.';

  @override
  String get pairWatchUnreachable =>
      'Die Uhr antwortet nicht. Prüfe, ob Handy und Uhr im selben WLAN sind und die Uhr den Code noch zeigt.';

  @override
  String get pairWatchNotDecryptable =>
      'Die Uhr konnte die Nachricht nicht lesen. Scanne den Code, den die Uhr jetzt zeigt.';

  @override
  String get pairWatchRejected =>
      'Der Server hat das Koppeln nicht angenommen. Versuch es noch einmal.';

  @override
  String get pairWatchInvalidServer =>
      'Die Uhr nimmt die Adresse dieses Servers nicht an. Unverschlüsseltes HTTP geht nur mit Adressen im Heimnetz.';

  @override
  String get pairWatchServerUnreachable =>
      'Die Uhr erreicht deinen Server nicht. Prüfe ihre Netzwerkverbindung.';

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

  @override
  String get searchHint => 'Suchen';

  @override
  String get searchIntro =>
      'Tippe ein Schlüsselwort, ein Widget, „t“ und ein To-do oder etwas für die Websuche.';

  @override
  String searchWeb(String query) {
    return 'Im Web nach „$query“ suchen';
  }

  @override
  String searchAddTodo(String title) {
    return 'To-do „$title“ anlegen';
  }

  @override
  String searchTodoAdded(String title) {
    return 'To-do „$title“ angelegt.';
  }

  @override
  String searchOnTab(String tab) {
    return 'Im Tab $tab';
  }

  @override
  String get lockTitle => 'Waylight ist gesperrt';

  @override
  String get lockUnlock => 'Entsperren';

  @override
  String get lockReason => 'Waylight entsperren';

  @override
  String get settingsLock => 'App-Sperre';

  @override
  String get settingsLockSwitch =>
      'Mit Fingerabdruck, Gesicht oder Geräte-PIN sperren';

  @override
  String get settingsLockAfter => 'Sperren nach';

  @override
  String get settingsLockNow => 'Sofort';

  @override
  String settingsLockMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get shortcutAddTodo => 'To-do hinzufügen';

  @override
  String get shortcutDepartures => 'Abfahrten';

  @override
  String get todosPending => 'Noch nicht auf dem Server gespeichert';

  @override
  String todosConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen konnten nicht gespeichert werden.',
      one: '1 Änderung konnte nicht gespeichert werden.',
    );
    return '$_temp0';
  }

  @override
  String get todosConflictsDecide => 'Entscheiden';

  @override
  String get todosConflictChanged => 'Inzwischen anderswo geändert.';

  @override
  String todosConflictRejected(String message) {
    return 'Vom Server abgelehnt: $message';
  }

  @override
  String get todosKeepMine => 'Meins behalten';

  @override
  String get todosKeepServer => 'Server-Version behalten';

  @override
  String get todosDiscard => 'Verwerfen';

  @override
  String get todosDeletedTodo => 'Gelöschtes To-do';

  @override
  String get editTabTitle => 'Tab anordnen';

  @override
  String get editTabReset => 'Zurücksetzen';

  @override
  String get editTabHidden => 'Auf Handys ausgeblendet';

  @override
  String get editTabUp => 'Nach vorne';

  @override
  String get editTabDown => 'Nach hinten';

  @override
  String get settingsSwitchServer => 'Zu diesem Server wechseln';

  @override
  String get settingsRemoveServer => 'Server entfernen';

  @override
  String get settingsAddServer => 'Weiteren Server hinzufügen';

  @override
  String get systemTitle => 'System';

  @override
  String get systemCpu => 'CPU';

  @override
  String get systemMemory => 'Arbeitsspeicher';

  @override
  String get systemSwap => 'Swap';

  @override
  String get servicesTitle => 'Dienste';

  @override
  String get servicesEmpty => 'Noch keine Dienste.';

  @override
  String get servicesOnline => 'Online';

  @override
  String get servicesOffline => 'Offline';

  @override
  String get servicesUnknown => 'Ungeprüft';

  @override
  String get statusOverviewTitle => 'Status';

  @override
  String get backupsTitle => 'Backups';

  @override
  String get backupsEmpty => 'Noch keine Backups oder Jobs gemeldet.';

  @override
  String get backupsOk => 'OK';

  @override
  String get backupsOverdue => 'Überfällig';

  @override
  String get backupsFailed => 'Fehlgeschlagen';

  @override
  String get backupsWaiting => 'Wartet';

  @override
  String get countdownTitle => 'Countdowns';

  @override
  String get countdownEmpty => 'Keine anstehenden Countdowns.';

  @override
  String get birthdaysTitle => 'Geburtstage';

  @override
  String get birthdaysEmpty => 'Noch keine Geburtstage.';

  @override
  String get electricityTitle => 'Strompreise';

  @override
  String get electricityTomorrowLater =>
      'Die Preise für morgen folgen gegen 13 Uhr.';

  @override
  String systemUptime(int days, int hours) {
    return 'läuft seit $days T $hours Std.';
  }

  @override
  String systemLoad(String load) {
    return 'Last $load';
  }

  @override
  String systemDiskOf(String used, String total) {
    return '$used von $total';
  }

  @override
  String systemFullIn(int days) {
    return 'voll in $days Tagen';
  }

  @override
  String backupsLastSuccess(String date) {
    return 'zuletzt erfolgreich $date';
  }

  @override
  String birthdaysTurns(int age) {
    return 'wird $age';
  }

  @override
  String electricityNow(String price) {
    return 'Jetzt $price';
  }

  @override
  String electricityCheapest(String hours) {
    return 'Günstigste Stunden: $hours';
  }

  @override
  String get holidaysTitle => 'Feiertage';

  @override
  String get holidaysEmpty => 'Keine Feiertage in Sicht.';

  @override
  String get holidaysNow => 'jetzt';

  @override
  String get holidayNewYear => 'Neujahr';

  @override
  String get holidayEpiphany => 'Heilige Drei Könige';

  @override
  String get holidayWomensDay => 'Internationaler Frauentag';

  @override
  String get holidayGoodFriday => 'Karfreitag';

  @override
  String get holidayEasterSunday => 'Ostersonntag';

  @override
  String get holidayEasterMonday => 'Ostermontag';

  @override
  String get holidayLabourDay => 'Tag der Arbeit';

  @override
  String get holidayAscension => 'Christi Himmelfahrt';

  @override
  String get holidayWhitSunday => 'Pfingstsonntag';

  @override
  String get holidayWhitMonday => 'Pfingstmontag';

  @override
  String get holidayCorpusChristi => 'Fronleichnam';

  @override
  String get holidayAssumption => 'Mariä Himmelfahrt';

  @override
  String get holidayChildrensDay => 'Weltkindertag';

  @override
  String get holidayGermanUnity => 'Tag der Deutschen Einheit';

  @override
  String get holidayReformation => 'Reformationstag';

  @override
  String get holidayAllSaints => 'Allerheiligen';

  @override
  String get holidayRepentance => 'Buß- und Bettag';

  @override
  String get holidayChristmasDay => '1. Weihnachtstag';

  @override
  String get holidayBoxingDay => '2. Weihnachtstag';

  @override
  String get diskHealthTitle => 'Festplatten';

  @override
  String get diskHealthEmpty => 'Noch keine Festplatten gemeldet.';

  @override
  String get diskHealthWarning => 'Warnung';

  @override
  String get diskHealthFailing => 'Defekt';

  @override
  String get diskHealthUnknown => 'Unbekannt';

  @override
  String get dockerTitle => 'Docker';

  @override
  String get dockerUnhealthy => 'fehlerhaft';

  @override
  String get proxmoxRunning => 'Läuft';

  @override
  String get proxmoxStopped => 'Gestoppt';

  @override
  String get speedtestTitle => 'Speedtest';

  @override
  String get speedtestEmpty => 'Noch keine Ergebnisse.';

  @override
  String get speedtestDownload => 'Download';

  @override
  String get speedtestUpload => 'Upload';

  @override
  String get speedtestPing => 'Ping';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get timelineEmpty => 'Noch nichts passiert.';

  @override
  String get wireguardEmpty => 'Noch keine Peers.';

  @override
  String get callsTitle => 'Anrufe';

  @override
  String get callsEmpty => 'Keine Anrufe.';

  @override
  String get callsIncoming => 'Eingehender Anruf';

  @override
  String get callsOutgoing => 'Ausgehender Anruf';

  @override
  String get callsMissed => 'verpasst';

  @override
  String get callsRejected => 'Abgewiesener Anruf';

  @override
  String get dnsFilterTitle => 'DNS-Filter';

  @override
  String get dnsFilterOn => 'Schutz aktiv';

  @override
  String get dnsFilterPaused => 'Schutz pausiert';

  @override
  String diskHealthWear(int percent) {
    return '$percent % abgenutzt';
  }

  @override
  String dockerSummary(int running, int stopped, int unhealthy) {
    return '$running laufen · $stopped gestoppt · $unhealthy fehlerhaft';
  }

  @override
  String speedtestAverage(int mbps) {
    return 'Schnitt $mbps Mbit/s';
  }

  @override
  String wireguardHandshake(String date) {
    return 'letzter Handshake $date';
  }

  @override
  String dnsFilterQueries(String count) {
    return '$count Anfragen in 24 Std.';
  }

  @override
  String dnsFilterBlocked(String count) {
    return 'Blockiert: $count';
  }

  @override
  String get briefingTitle => 'Tagesüberblick';

  @override
  String get briefingWarnings => 'Wetterwarnungen';

  @override
  String get briefingIncidents => 'Seit gestern Abend';

  @override
  String get briefingTodos => 'Aufgaben';

  @override
  String get briefingEvents => 'Termine';

  @override
  String get arrHealth => 'Warnungen';

  @override
  String get arrUpcoming => 'Demnächst';

  @override
  String get arrQueue => 'Downloads';

  @override
  String get mediaTitle => 'Medien';

  @override
  String get mediaPlaying => 'Läuft gerade';

  @override
  String get mediaRecent => 'Neu hinzugefügt';

  @override
  String get releasesTitle => 'Neuerscheinungen';

  @override
  String get gameDealsTitle => 'Spiele-Angebote';

  @override
  String get gameDealsFree => 'Jetzt gratis';

  @override
  String get gameDealsDeals => 'Im Angebot';

  @override
  String get gameDealsNext => 'Bald gratis';

  @override
  String get spaceTitle => 'Raketenstarts';

  @override
  String get readLaterTitle => 'Später lesen';

  @override
  String get listEmpty => 'Noch nichts da.';

  @override
  String get fuelTitle => 'Spritpreise';

  @override
  String get fuelEmpty => 'Keine Tankstellen gefunden.';

  @override
  String get fuelClosed => 'geschlossen';

  @override
  String get marketsTitle => 'Märkte';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get calendarEmpty => 'Keine Termine in Sicht.';

  @override
  String get calendarAllDay => 'ganztägig';

  @override
  String get phoneListTitle => 'Telefonliste';

  @override
  String get phoneListEmpty => 'Noch keine Einträge.';

  @override
  String get studyTitle => 'Studienfortschritt';

  @override
  String get studyAverage => 'Notenschnitt';

  @override
  String get studyInProgress => 'läuft';

  @override
  String get appPhotos => 'Fotos';

  @override
  String get appVideos => 'Videos';

  @override
  String get appUsers => 'Nutzer';

  @override
  String get appUpdates => 'App-Updates';

  @override
  String get appMaintenance => 'Wartungsmodus';

  @override
  String get appStorage => 'Speicher';

  @override
  String get sportsTitle => 'Sport';

  @override
  String listMore(int count) {
    return '$count weitere';
  }

  @override
  String studyCredits(String passed, String total) {
    return '$passed von $total ECTS';
  }

  @override
  String sportsPlayed(int games) {
    return '$games Spiele';
  }

  @override
  String sportsPoints(int points) {
    return '$points Pkt.';
  }

  @override
  String get shoppingTitle => 'Einkaufsliste';

  @override
  String get shoppingNotConfigured =>
      'Lege zuerst im Web eine Einkaufsliste an.';

  @override
  String get shoppingEmpty => 'Nichts zu kaufen.';

  @override
  String get shoppingAdd => 'Artikel hinzufügen';

  @override
  String get habitsTitle => 'Gewohnheiten';

  @override
  String get habitsEmpty => 'Heute keine Gewohnheiten fällig.';

  @override
  String shoppingClear(int count) {
    return '$count im Korb entfernen';
  }

  @override
  String habitsStreak(int current, int best) {
    return '$current Tage in Folge · Rekord $best';
  }

  @override
  String get rssTitle => 'Feeds';

  @override
  String get rssCaughtUp => 'Alles gelesen.';

  @override
  String get rssMarkRead => 'Als gelesen markieren';

  @override
  String get rssMarkUnread => 'Als ungelesen markieren';

  @override
  String get parcelsTitle => 'Pakete';

  @override
  String get parcelsEmpty => 'Keine Pakete unterwegs.';

  @override
  String get parcelsAdd => 'Paket hinzufügen';

  @override
  String get parcelsNumber => 'Sendungsnummer';

  @override
  String get parcelsLabel => 'Was ist es? (optional)';

  @override
  String get parcelsCancel => 'Abbrechen';

  @override
  String get parcelsTrack => 'Beim Paketdienst verfolgen';

  @override
  String get parcelsDelete => 'Nicht mehr verfolgen';

  @override
  String get parcelsAnnounced => 'angekündigt';

  @override
  String get parcelsOnTheWay => 'unterwegs';

  @override
  String get parcelsDelivered => 'zugestellt';

  @override
  String get parcelsCheck => 'prüfen';

  @override
  String get smartHomeTitle => 'Smart Home';

  @override
  String get smartHomeEmpty => 'Wähle im Web Entitäten aus.';

  @override
  String get smartHomeRun => 'Ausführen';

  @override
  String parcelsExpected(String date) {
    return 'erwartet $date';
  }

  @override
  String get photoFrameTitle => 'Fotos';

  @override
  String get photoFrameEmpty => 'Noch keine Fotos in diesem Album.';

  @override
  String get radarTitle => 'Regenradar';

  @override
  String get radarNoPlace => 'Wähle im Web einen Ort.';

  @override
  String get apodTitle => 'Bild des Tages';

  @override
  String get apiWidgetNoEndpoint => 'Wähle im Web einen Endpunkt.';

  @override
  String get mailTitle => 'Mail';

  @override
  String get dropTitle => 'Ablage';

  @override
  String get dropEmpty => 'Noch nichts abgelegt.';

  @override
  String get focusTitle => 'Fokus';

  @override
  String get focusStart => 'Starten';

  @override
  String get focusStop => 'Stoppen';

  @override
  String mailUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesene Nachrichten',
      one: '1 ungelesene Nachricht',
      zero: '0 ungelesene Nachrichten',
    );
    return '$_temp0';
  }

  @override
  String focusToday(int minutes, int sessions) {
    return 'Heute: $minutes Min. in $sessions Sitzungen';
  }

  @override
  String get servicesOpen => 'Öffnen';

  @override
  String get servicesWake => 'Aufwecken';

  @override
  String get dockerRestart => 'Neu starten';

  @override
  String get dockerLogs => 'Log anzeigen';

  @override
  String get proxmoxStart => 'Starten';

  @override
  String get proxmoxShutdown => 'Herunterfahren';

  @override
  String servicesWakeSent(String name) {
    return 'Weckruf an $name gesendet.';
  }

  @override
  String dockerRestartConfirm(String name) {
    return '$name neu starten?';
  }

  @override
  String dockerRestarted(String name) {
    return '$name startet neu.';
  }

  @override
  String proxmoxSent(String name) {
    return 'An $name gesendet.';
  }

  @override
  String dnsFilterPause(int minutes) {
    return '$minutes Minuten pausieren';
  }

  @override
  String get weatherWarning => 'Wetterwarnung';

  @override
  String get weatherUv => 'UV-Index heute';

  @override
  String weatherWarningUntil(String time) {
    return 'bis $time';
  }

  @override
  String get calendarNewEvent => 'Neuer Termin';

  @override
  String get calendarEventTitle => 'Titel';

  @override
  String get calendarEventLocation => 'Ort (optional)';

  @override
  String get calendarSave => 'Speichern';

  @override
  String get calendarShowAll => 'Terminübersicht';

  @override
  String get shoppingOpen => 'Liste öffnen';

  @override
  String calendarEventAdded(String title) {
    return '$title eingetragen.';
  }

  @override
  String get smartHomeAll => 'Alle Geräte';

  @override
  String get rssOpen => 'Reader öffnen';

  @override
  String get rssAllRead => 'Alle als gelesen markieren';

  @override
  String get rssUnreadOnly => 'Ungelesen';

  @override
  String get rssAllFeeds => 'Alle';

  @override
  String get timelineOpen => 'Alle Ereignisse';

  @override
  String get timelineAll => 'Alle';

  @override
  String get timelineCritical => 'Kritisch';

  @override
  String get noteNew => 'Neue Notiz';

  @override
  String get noteEdit => 'Notiz bearbeiten';

  @override
  String get noteBodyHint => 'Text (Markdown)';

  @override
  String get noteSaved => 'Notiz gespeichert.';

  @override
  String get noteConflict =>
      'Diese Notiz wurde woanders geändert. Lade sie neu und bearbeite sie erneut.';

  @override
  String get noteTitleMissing => 'Gib der Notiz einen Titel.';

  @override
  String get noteDelete => 'Löschen';

  @override
  String get noteDeleteConfirm => 'Diese Notiz löschen?';

  @override
  String get notePin => 'Anheften';

  @override
  String get noteUnpin => 'Lösen';

  @override
  String get readLaterUnread => 'Ungelesen';

  @override
  String get readLaterSave => 'Link speichern';

  @override
  String get readLaterOriginal => 'Original öffnen';

  @override
  String get readLaterArchive => 'Archivieren';

  @override
  String get readLaterNoCopy =>
      'Von dieser Seite gibt es keine Lesekopie; öffne das Original.';

  @override
  String get dropSend => 'Text senden';

  @override
  String get serviceDetails => 'Verfügbarkeit und Ausfälle';

  @override
  String get serviceUptime => 'Verfügbarkeit';

  @override
  String get serviceDay => 'Letzte 24 Stunden';

  @override
  String get serviceWeek => 'Letzte 7 Tage';

  @override
  String get serviceMonth => 'Letzte 30 Tage';

  @override
  String get serviceQuarter => 'Letzte 90 Tage';

  @override
  String get serviceIncidents => 'Ausfälle';

  @override
  String get serviceNoIncidents => 'Keine Ausfälle erfasst.';

  @override
  String serviceDownSince(String time) {
    return 'Ausgefallen seit $time';
  }

  @override
  String get securityTitle => 'Passwort und Anmeldung';

  @override
  String get securityPassword => 'Passwort';

  @override
  String get securityChangePassword => 'Passwort ändern';

  @override
  String get securityCurrentPassword => 'Aktuelles Passwort';

  @override
  String get securityNewPassword => 'Neues Passwort';

  @override
  String get securityPasswordChanged =>
      'Passwort geändert. Andere Geräte sind abgemeldet.';

  @override
  String get securityTotp => 'Zwei-Faktor-Anmeldung';

  @override
  String get securityTotpOn =>
      'An: Bei der Anmeldung wird ein Code deiner Authenticator-App abgefragt.';

  @override
  String get securityTotpIsOff => 'Aus.';

  @override
  String get securityTotpSetUp => 'Einrichten';

  @override
  String get securityTotpOff => 'Ausschalten';

  @override
  String get securityTotpHint =>
      'Füge diesen Schlüssel in deiner Authenticator-App hinzu oder öffne die App direkt und gib dann den angezeigten Code ein.';

  @override
  String get securityOpenAuthenticator => 'Authenticator-App öffnen';

  @override
  String get securityCode => 'Code';

  @override
  String get securityConfirm => 'Bestätigen';

  @override
  String get securityRecoveryCodes => 'Wiederherstellungscodes';

  @override
  String get securityCodesSaved => 'Ich habe sie gespeichert';

  @override
  String get securitySessions => 'Angemeldete Geräte';

  @override
  String get securityThisDevice => 'Dieses Gerät';

  @override
  String get securitySignOutSession => 'Abmelden';

  @override
  String get securitySignOutOthers => 'Alle anderen Geräte abmelden';

  @override
  String get securitySessionEnded => 'Abgemeldet.';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsPushSwitch => 'Benachrichtigungen auf diesem Handy';

  @override
  String get settingsPushHint =>
      'Nachrichten aus den Benachrichtigungsregeln von Waylight kommen Ende-zu-Ende-verschlüsselt über den Waylight-Relay an, ohne Google. Solange es an ist, zeigt Android dauerhaft „Waylight ist verbunden“. Schalte im Web auch den Kanal „Waylight-App“ ein.';

  @override
  String get settingsPushDenied =>
      'Benachrichtigungen sind für diese App in den Systemeinstellungen gesperrt.';

  @override
  String get settingsPushNotInBuild =>
      'Diese Version der App hat keine Push-Benachrichtigungen.';

  @override
  String get summaryAction => 'Zusammenfassen';

  @override
  String get summaryTitle => 'Zusammenfassung';

  @override
  String get summaryByAi =>
      'Von der lokalen KI des Servers geschrieben; sie kann sich irren.';

  @override
  String get bookmarkAdd => 'Lesezeichen hinzufügen';

  @override
  String get bookmarkEdit => 'Lesezeichen bearbeiten';

  @override
  String get bookmarkFolder => 'Ordner';

  @override
  String get bookmarkNoFolder => 'Kein Ordner';

  @override
  String get searchOpenWidget => 'Widget öffnen';

  @override
  String get shareTitle => 'In Waylight speichern';

  @override
  String get shareTodo => 'Als Aufgabe';

  @override
  String get shareNote => 'Als Notiz';

  @override
  String shareSaved(String target) {
    return 'Gespeichert: $target';
  }

  @override
  String get homeWidgetTodos => 'Aufgaben heute';

  @override
  String get homeWidgetTodosEmpty => 'Heute nichts fällig';

  @override
  String get homeWidgetDepartures => 'Abfahrten';

  @override
  String get homeWidgetNoStop =>
      'Füge dem Dashboard ein ÖPNV-Widget mit Haltestelle hinzu';

  @override
  String get homeWidgetNoDepartures => 'Keine Abfahrten';

  @override
  String get homeWidgetCancelled => 'fällt aus';

  @override
  String homeWidgetUpdated(String time) {
    return 'Stand $time';
  }

  @override
  String get summaryAsk => 'Frage dazu stellen';

  @override
  String get grafanaAlertsTitle => 'Grafana-Alarme';

  @override
  String get grafanaAllQuiet => 'Kein Alarm ist aktiv.';

  @override
  String get grafanaFiring => 'aktiv';

  @override
  String get grafanaPending => 'ausstehend';

  @override
  String get grafanaAlertList => 'Alarmliste';

  @override
  String get grafanaPanelTitle => 'Grafana-Panel';

  @override
  String get grafanaChoosePanel =>
      'Wähle in der Weboberfläche ein Dashboard und ein Panel.';

  @override
  String grafanaPanelAlt(String title) {
    return 'Grafana-Panel $title';
  }

  @override
  String get settingsPushBattery =>
      'Android kann die Verbindung zum Akkusparen trennen.';

  @override
  String get settingsPushBatteryAction => 'Erlauben';

  @override
  String get dashboardOpenWidget => 'in voller Größe öffnen';

  @override
  String get dashboardOpenDetails => 'Details öffnen';

  @override
  String get focusStartFocus => 'Fokus starten';

  @override
  String get widgetSizeFull => 'Volle Breite';

  @override
  String get widgetSizeSmall => 'Klein';

  @override
  String get widgetSizeMedium => 'Mittel';

  @override
  String get widgetSizeLarge => 'Groß';

  @override
  String get widgetSizeStrip => 'Leiste';

  @override
  String editTabSize(String size) {
    return 'Größe: $size';
  }

  @override
  String editTabSizeOf(String widget) {
    return 'Größe von $widget';
  }

  @override
  String get editTabHint =>
      'Halten und ziehen zum Verschieben. Tippe auf die Größe, um sie zu ändern. − blendet ein Widget auf Handys aus.';

  @override
  String get editTabDone => 'Fertig';

  @override
  String editTabHide(String widget) {
    return '$widget auf Handys ausblenden';
  }

  @override
  String get editTabHideOnPhones => 'Auf Handys ausblenden';

  @override
  String editTabShow(String widget) {
    return '$widget wieder anzeigen';
  }

  @override
  String get editTabDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get editTabDiscard => 'Verwerfen';

  @override
  String get editTabKeep => 'Weiter bearbeiten';

  @override
  String get dashboardTapToOpen => 'Antippen, um alles zu sehen';

  @override
  String todosCompactOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offen',
      one: '1 offen',
    );
    return '$_temp0';
  }

  @override
  String todosCompactNext(String title) {
    return 'als Nächstes: $title';
  }

  @override
  String transitThen(String times) {
    return 'danach $times';
  }

  @override
  String calendarMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count weitere',
      one: '+1 weiterer',
    );
    return '$_temp0';
  }

  @override
  String statusAllUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dienste laufen',
      one: '1 Dienst läuft',
    );
    return '$_temp0';
  }

  @override
  String statusSomeDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dienste ausgefallen',
      one: '1 Dienst ausgefallen',
    );
    return '$_temp0';
  }

  @override
  String get galleryOpen => 'Widget hinzufügen';

  @override
  String galleryTitle(String tab) {
    return 'Zu „$tab“ hinzufügen';
  }

  @override
  String get gallerySearch => 'Widgets suchen';

  @override
  String get galleryAdded => 'Hinzugefügt';

  @override
  String galleryAddSized(String widget, String size) {
    return '$widget als Kachel „$size“ hinzufügen';
  }

  @override
  String get galleryEmpty => 'Keine passenden Widgets.';

  @override
  String get editTabMore => 'Mehr';

  @override
  String get diagnosticsCreate => 'Diagnosebericht erstellen';

  @override
  String get diagnosticsHint =>
      'Für eine Fehlermeldung: App- und Server-Version, Gerät und die letzten Fehler, ohne Adressen oder Passwörter.';

  @override
  String get diagnosticsTitle => 'Diagnosebericht';

  @override
  String get diagnosticsPreview =>
      'Das ist alles, was der Bericht enthält. Er verlässt das Handy nur, wenn du ihn teilst.';

  @override
  String get diagnosticsShare => 'Teilen';

  @override
  String get settingsColours => 'Farben';

  @override
  String get settingsColoursWaylight => 'Wie Waylight';

  @override
  String get settingsColoursWallpaper => 'Hintergrundbild';

  @override
  String get addressesTitle => 'Adressen';

  @override
  String get addressesHint =>
      'Werden in dieser Reihenfolge probiert; die erste, die antwortet und deine Sitzung kennt, wird benutzt, z. B. zuerst das Heimnetz, dann die Adresse für unterwegs.';

  @override
  String get addressInUse => 'In Benutzung';

  @override
  String get addressUnreachable => 'Gerade nicht erreichbar';

  @override
  String get addressRejected =>
      'Antwortet, kennt deine Sitzung aber nicht – ein anderer Server unter dieser Adresse?';

  @override
  String get addressRaise => 'Früher probieren';

  @override
  String get addressRemove => 'Adresse entfernen';

  @override
  String get addressAdd => 'Adresse hinzufügen';

  @override
  String get reminderTodoBody => 'Heute fällig';

  @override
  String get reminderEventAllDay => 'Heute ganztägig';

  @override
  String reminderEventAt(String time, int minutes) {
    return 'Um $time, in $minutes Min.';
  }

  @override
  String reminderBirthdayTitle(String name) {
    return '$name hat Geburtstag';
  }

  @override
  String reminderBirthdayAge(int age) {
    return 'Wird heute $age';
  }

  @override
  String get reminderBirthdayBody => 'Geburtstag heute';

  @override
  String get settingsReminders => 'Erinnerungen auf diesem Handy';

  @override
  String get settingsRemindersHint =>
      'Zeigt das Handy selbst an, auch offline. Wird aktualisiert, sobald die App das Dashboard lädt.';

  @override
  String get settingsReminderTodos => 'Aufgaben am Fälligkeitstag um 8:00';

  @override
  String get settingsReminderEvents => 'Termine';

  @override
  String get settingsReminderEventsOff => 'Aus';

  @override
  String settingsReminderMinutes(int minutes) {
    return '$minutes Min. vorher';
  }

  @override
  String get settingsReminderBirthdays => 'Geburtstage um 8:00';

  @override
  String get settingsReminderDenied =>
      'Benachrichtigungen für Waylight sind in den Systemeinstellungen ausgeschaltet.';

  @override
  String get focusStartBreak => 'Pause';

  @override
  String get focusPause => 'Anhalten';

  @override
  String get focusResume => 'Weiter';

  @override
  String get focusRunning => 'Fokus';

  @override
  String get focusBreak => 'Pause';

  @override
  String get kioskUse => 'Als Wandbildschirm nutzen';

  @override
  String get kioskUseHint =>
      'Füge den Link eines Kiosk-Bildschirms aus der Weboberfläche ein (Einstellungen → Konten → Kiosk-Bildschirme).';

  @override
  String get kioskStart => 'Starten';

  @override
  String get kioskLinkInvalid =>
      'Das ist kein Kiosk-Link. Er sieht so aus: https://…/kiosk#…';

  @override
  String get kioskLinkRejected =>
      'Der Server kennt diesen Link nicht mehr. Erstelle in der Weboberfläche einen neuen.';

  @override
  String get kioskLinkFailed =>
      'Der Wandbildschirm konnte nicht starten. Ist der Server erreichbar?';

  @override
  String get kioskNoTabs => 'Keine Tabs für diesen Bildschirm.';

  @override
  String get kioskLeave => 'Wandbildschirm verlassen (gedrückt halten)';

  @override
  String get kioskLeaveReason =>
      'Bestätige, um den Wandbildschirm zu verlassen';

  @override
  String get presenceTitle => 'Anwesenheit';

  @override
  String get presenceOffice => 'Büro';

  @override
  String get presenceHome => 'Homeoffice';

  @override
  String get presenceAway => 'Weg';

  @override
  String get presenceNone => 'Nicht gesetzt';

  @override
  String get presenceMine => 'Mein Status heute';

  @override
  String get presenceReturnOn => 'Zurück am';

  @override
  String presenceBack(String date) {
    return 'zurück $date';
  }

  @override
  String get presenceFromAbsence => 'aus den Abwesenheiten';

  @override
  String get presenceEmpty => 'Niemand in dieser Gruppe.';

  @override
  String get presenceOff =>
      'Anwesenheit ist für diese Organisation ausgeschaltet.';

  @override
  String presenceCounts(int office, int home, int away, int none) {
    return '$office im Büro · $home im Homeoffice · $away weg · $none nicht gesetzt';
  }

  @override
  String get absencesTitle => 'Abwesenheiten';

  @override
  String get absencesToday => 'Heute nicht da';

  @override
  String get absencesWeek => 'Später diese Woche';

  @override
  String get absencesNobodyToday => 'Heute sind alle da.';

  @override
  String get absencesNobodyWeek => 'Diese Woche keine weiteren Abwesenheiten.';

  @override
  String get absencesOff => 'Abwesenheiten gibt es auf diesem Server nicht.';

  @override
  String get absenceHoliday => 'Urlaub';

  @override
  String get absenceSick => 'Krank';

  @override
  String get absenceRemote => 'Remote';

  @override
  String get absenceAway => 'Abwesend';

  @override
  String absenceRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get absenceAdd => 'Abwesenheit eintragen';

  @override
  String absenceEdit(String name) {
    return 'Abwesenheit von $name bearbeiten';
  }

  @override
  String get absenceDelete => 'Löschen';

  @override
  String get absenceFrom => 'Von';

  @override
  String get absenceTo => 'Bis (einschließlich)';

  @override
  String get absenceKind => 'Art';

  @override
  String get absenceNote => 'Notiz (optional)';

  @override
  String get absencePrivate =>
      'Privat: andere sehen nur, dass ich nicht da bin';

  @override
  String get absencePrivateBadge => 'privat';

  @override
  String get absenceErrorDates =>
      'Der letzte Tag darf nicht vor dem ersten liegen.';

  @override
  String get announcementsTitle => 'Ankündigungen';

  @override
  String get announcementsEmpty => 'Keine Ankündigungen.';

  @override
  String get announcementsOff =>
      'Ankündigungen gibt es auf diesem Server nicht.';

  @override
  String get announcementUnread => 'ungelesen';

  @override
  String get announcementPinned => 'Angeheftet';

  @override
  String get announcementWrite => 'Ankündigung schreiben';

  @override
  String get announcementEdit => 'Ankündigung bearbeiten';

  @override
  String get announcementDelete => 'Löschen';

  @override
  String get announcementPublish => 'Veröffentlichen';

  @override
  String get announcementTitleField => 'Titel';

  @override
  String get announcementBodyField => 'Text';

  @override
  String get announcementMarkdownHint =>
      'Markdown: **fett**, *kursiv*, Listen und Links.';

  @override
  String get announcementExpires => 'Läuft ab';

  @override
  String get announcementNoExpiry => 'Kein Ablauf';

  @override
  String get announcementNotify => 'An die Benachrichtigungskanäle senden';

  @override
  String get parcelsScan => 'Etikett scannen';

  @override
  String get parcelsScanPrompt =>
      'Richte die Kamera auf den Barcode des Versandetiketts';

  @override
  String get parcelsScanNoNumber =>
      'In diesem Code steht keine Sendungsnummer. Tippe sie ein oder scanne den Barcode neben der Nummer.';

  @override
  String get quickTileStatus => 'Mein Status';

  @override
  String get quickTileOn => 'An';

  @override
  String get quickTileOff => 'Aus';

  @override
  String get quickTileUnreachable => 'Nicht erreichbar';

  @override
  String get quickTileChooseTitle => 'Smart-Home-Kachel';

  @override
  String get quickTileChooseHint =>
      'Wähle das Gerät, das die Waylight-Kachel in den Schnelleinstellungen schaltet.';

  @override
  String quickTileChosen(String name) {
    return 'Die Kachel schaltet jetzt $name.';
  }

  @override
  String get quickTileNoDevices =>
      'Kein Gerät darf geschaltet werden. Der Besitzer wählt sie in der Weboberfläche aus.';

  @override
  String get quickTilesTitle => 'Schnelleinstellungen';

  @override
  String get quickTilesHint =>
      'Füge Waylights Kacheln in den Schnelleinstellungen des Handys hinzu: Aufgabe anlegen, Gerät schalten, Status setzen.';

  @override
  String get quickTileSmartHomeChoice => 'Gerät der Smart-Home-Kachel';

  @override
  String get quickTileNoChoice => 'Noch nicht gewählt';

  @override
  String get settingsAreaAccount => 'Konto & Sicherheit';

  @override
  String get settingsAreaServer => 'Server & Verbindung';

  @override
  String get settingsAreaNotifications => 'Benachrichtigungen & Erinnerungen';

  @override
  String get settingsAreaPhone => 'Dieses Handy';

  @override
  String get settingsAreaAbout => 'Über & Hilfe';

  @override
  String get settingsAreaEmpty =>
      'Auf diesem Handy gibt es hier nichts einzustellen.';

  @override
  String get settingsStatusNoAddress => 'Keine Adresse antwortet';

  @override
  String get settingsStatusPushOn => 'Push an';

  @override
  String get settingsStatusPushOff => 'Push aus';

  @override
  String get settingsStatusRemindersOn => 'Erinnerungen an';

  @override
  String get settingsStatusRemindersOff => 'Erinnerungen aus';

  @override
  String get settingsStatusLockOn => 'App-Sperre an';

  @override
  String get settingsStatusLockOff => 'App-Sperre aus';

  @override
  String get settingsStatusPhone => 'Widgets und Kacheln';

  @override
  String settingsStatusVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsConnection => 'Verbindung';

  @override
  String get settingsOtherServers => 'Andere Server';

  @override
  String get settingsAdvanced => 'Erweitert';

  @override
  String get settingsCheckNow => 'Adressen jetzt prüfen';

  @override
  String get settingsCheckNowHint =>
      'Probiert die Adressen der Reihe nach und nimmt die erste, die antwortet.';

  @override
  String get settingsHomeWidgets => 'Widgets auf dem Startbildschirm';

  @override
  String get settingsHomeWidgetsHint =>
      'Halte eine freie Stelle auf dem Startbildschirm gedrückt, wähle Widgets und such dir eines von Waylight aus.';

  @override
  String get settingsWallDisplayHint =>
      'Wähle unter Server & Verbindung „Weiteren Server hinzufügen“, dann „Als Wandbildschirm nutzen“ und füge den Link einer Kiosk-Anzeige ein.';

  @override
  String get tagTitle => 'NFC-Tag';

  @override
  String tagConfirm(String name) {
    return '$name schalten?';
  }

  @override
  String get tagConfirmAction => 'Ja, schalten';

  @override
  String get tagClose => 'Schließen';

  @override
  String get tagUnknown =>
      'Dieser Tag enthält keine Waylight-Aktion, die diese App kennt.';

  @override
  String tagTicked(String name) {
    return '$name für heute abgehakt.';
  }

  @override
  String tagAlreadyDone(String name) {
    return '$name war heute schon abgehakt.';
  }

  @override
  String tagSwitched(String name) {
    return '$name geschaltet.';
  }

  @override
  String tagPressed(String name) {
    return '$name gestartet.';
  }

  @override
  String tagAdded(String name) {
    return '$name steht auf der Einkaufsliste.';
  }

  @override
  String get tagWrite => 'Auf NFC-Tag schreiben';

  @override
  String get tagWriteHint =>
      'Der Tag speichert nur einen Link zu dieser Aktion. Auf einem Handy ohne dein Waylight-Konto bewirkt er nichts.';

  @override
  String get tagWriteStart => 'Tag beschreiben';

  @override
  String get tagHold => 'Halte den Tag an die Rückseite des Handys.';

  @override
  String get tagAsk => 'Vor dem Schalten fragen';

  @override
  String get tagWritten =>
      'Fertig. Berühre den Tag mit dem entsperrten Handy, um die Aktion auszuführen.';

  @override
  String get tagLocked =>
      'Dieser Tag ist gesperrt und lässt sich nicht beschreiben.';

  @override
  String get tagTooSmall =>
      'Dieser Tag ist zu klein für den Link. Nimm einen NTAG213 oder größer.';

  @override
  String get tagUnsupported => 'Diese Art Tag kann keinen Link speichern.';

  @override
  String get tagLost =>
      'Der Tag wurde zu früh entfernt. Halte ihn still, bis es fertig ist.';

  @override
  String get tagFailed => 'Der Tag konnte nicht beschrieben werden.';

  @override
  String get tagTryAgain => 'Noch einmal';

  @override
  String get tagNoNfc => 'Dieses Handy hat kein NFC.';

  @override
  String get tagNfcOff =>
      'NFC ist ausgeschaltet. Schalte es in den Systemeinstellungen ein.';

  @override
  String get tagShopping => 'NFC-Tag für einen Artikel';

  @override
  String get tagShoppingItem => 'Artikel';

  @override
  String get deviceControlNoState => 'Kein Zustand';

  @override
  String get deviceControlSignIn => 'Waylight öffnen und anmelden';

  @override
  String get absencePerson => 'Person';

  @override
  String get absenceMe => 'Ich';

  @override
  String get settingsSearch => 'Einstellungen durchsuchen';

  @override
  String settingsSearchEmpty(String query) {
    return 'Keine Einstellung passt zu „$query“.';
  }

  @override
  String get settingsSearchClear => 'Suche leeren';

  @override
  String get settingsSearchBattery => 'Akku-Hinweis';

  @override
  String get settingsAttentionShow => 'Anzeigen';

  @override
  String compactWeather(String temp, String feels) {
    return '$temp °C, gefühlt $feels °C';
  }

  @override
  String compactWeatherToday(String min, String max, String rain) {
    return '$min bis $max °C, $rain % Regen';
  }

  @override
  String compactDeparture(String line, String headsign, String minutes) {
    return '$line nach $headsign in $minutes min';
  }

  @override
  String compactDepartureCancelled(String line, String headsign) {
    return '$line nach $headsign fällt aus';
  }

  @override
  String compactDepartureDelay(String delay) {
    return '$delay min später';
  }

  @override
  String get compactNoDepartures => 'Keine Abfahrten';

  @override
  String compactWasteToday(String label) {
    return '$label heute';
  }

  @override
  String compactWasteTomorrow(String label) {
    return '$label morgen';
  }

  @override
  String compactWasteInDays(String label, String days) {
    return '$label in $days Tagen';
  }

  @override
  String get compactNoCollections => 'Keine Abholung geplant';

  @override
  String get dashboardNothingToShow =>
      'Auf diesem Tab gibt es gerade nichts zu sehen.';
}
