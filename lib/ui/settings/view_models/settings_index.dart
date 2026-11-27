import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';

/// A single setting the settings search finds (#232), with its area and
/// the words people may look for in English and German.
///
/// The words are in addition to the setting's and the area's title in the
/// app's language, which the search always includes. Keep them lower case.
enum SettingsItem {
  /// Name and role of the signed-in account.
  account(SettingsArea.account, [
    'account',
    'konto',
    'user',
    'benutzer',
    'profile',
    'profil',
    'name',
    'role',
    'rolle',
  ]),

  /// Password, two-factor sign-in, passkeys and sessions.
  security(SettingsArea.account, [
    'password',
    'passwort',
    'two-factor',
    '2fa',
    'zwei-faktor',
    'passkey',
    'session',
    'sitzung',
    'sign-in',
    'anmeldung',
    'security',
    'sicherheit',
  ]),

  /// Signing out.
  signOut(SettingsArea.account, [
    'sign out',
    'log out',
    'logout',
    'abmelden',
    'ausloggen',
  ]),

  /// The address of the server and the one in use.
  serverAddress(SettingsArea.server, ['server', 'address', 'adresse', 'url']),

  /// The version of the server.
  serverVersion(SettingsArea.server, ['version', 'server']),

  /// The addresses in the order they are tried (#189).
  addresses(SettingsArea.server, [
    'address',
    'adresse',
    'home network',
    'heimnetz',
    'away',
    'unterwegs',
    'vpn',
    'ip',
  ]),

  /// Other servers used on this phone, adding one.
  otherServers(SettingsArea.server, [
    'server',
    'switch',
    'wechseln',
    'add',
    'hinzufugen',
    'instance',
    'instanz',
  ]),

  /// Trying the addresses again.
  checkAddresses(SettingsArea.server, [
    'check',
    'prufen',
    'connection',
    'verbindung',
    'reachable',
    'erreichbar',
    'retry',
  ]),

  /// Leaving the server.
  disconnect(SettingsArea.server, [
    'disconnect',
    'trennen',
    'forget',
    'vergessen',
    'other server',
  ]),

  /// Light, dark or like the system.
  theme(SettingsArea.appearance, [
    'theme',
    'dark',
    'dunkel',
    'light',
    'hell',
    'design',
    'mode',
    'modus',
  ]),

  /// Waylight or wallpaper colours (#198).
  colours(SettingsArea.appearance, [
    'colour',
    'color',
    'farbe',
    'wallpaper',
    'hintergrundbild',
    'material you',
  ]),

  /// The account's text size on top of the system's (#291).
  textSize(SettingsArea.appearance, [
    'text size',
    'textgrosse',
    'font',
    'schrift',
    'larger',
    'grosser',
    'accessibility',
    'barrierefreiheit',
  ]),

  /// The account's high-contrast colours (#291).
  highContrast(SettingsArea.appearance, [
    'contrast',
    'kontrast',
    'accessibility',
    'barrierefreiheit',
    'low vision',
    'sehschwache',
  ]),

  /// The account's simple view of the dashboard (#291).
  simpleView(SettingsArea.appearance, [
    'simple',
    'einfach',
    'one column',
    'eine spalte',
    'accessibility',
    'barrierefreiheit',
  ]),

  /// The language of the app.
  language(SettingsArea.appearance, [
    'language',
    'sprache',
    'english',
    'englisch',
    'deutsch',
    'german',
  ]),

  /// Push notifications (#59).
  push(SettingsArea.notifications, [
    'push',
    'notification',
    'benachrichtigung',
    'mitteilung',
    'relay',
  ]),

  /// Lifting Android's battery restrictions for push.
  battery(SettingsArea.notifications, [
    'battery',
    'akku',
    'energy',
    'energie',
    'background',
    'hintergrund',
    'optimisation',
    'optimization',
    'optimierung',
  ]),

  /// Reminders the phone shows by itself (#190).
  reminders(SettingsArea.notifications, [
    'reminder',
    'erinnerung',
    'todo',
    'to-do',
    'birthday',
    'geburtstag',
    'event',
    'termin',
    'alarm',
  ]),

  /// The app lock (#46).
  lock(SettingsArea.phone, [
    'lock',
    'sperre',
    'pin',
    'fingerprint',
    'fingerabdruck',
    'face',
    'gesicht',
    'biometric',
    'biometrie',
  ]),

  /// How to add home screen widgets.
  homeWidgets(SettingsArea.phone, ['widget', 'home screen', 'startbildschirm']),

  /// The Quick Settings tiles (#192).
  quickTiles(SettingsArea.phone, [
    'quick settings',
    'schnelleinstellungen',
    'tile',
    'kachel',
  ]),

  /// Pairing a Wear OS watch (#239).
  pairWatch(SettingsArea.phone, [
    'watch',
    'uhr',
    'smartwatch',
    'wear os',
    'pair',
    'koppeln',
  ]),

  /// Sending a key to the setup assistant (#303).
  setupPaste(SettingsArea.phone, [
    'paste',
    'einfügen',
    'setup',
    'einrichtung',
    'qr',
    'key',
    'schlüssel',
  ]),

  /// How to start a wall display (#193).
  wallDisplay(SettingsArea.phone, [
    'wall',
    'wand',
    'kiosk',
    'tablet',
    'display',
    'bildschirm',
  ]),

  /// The version of the app.
  appVersion(SettingsArea.about, ['version', 'build', 'update']),

  /// The source code.
  source(SettingsArea.about, ['source', 'quellcode', 'github', 'code']),

  /// The privacy documentation.
  privacy(SettingsArea.about, ['privacy', 'datenschutz', 'data', 'daten']),

  /// The diagnostic report (#197).
  diagnostics(SettingsArea.about, [
    'diagnostic',
    'diagnose',
    'log',
    'report',
    'bericht',
    'support',
    'bug',
    'fehler',
  ]),

  /// The open-source licences.
  licences(SettingsArea.about, ['licence', 'license', 'lizenz', 'open source']);

  const SettingsItem(this.area, this.synonyms);

  /// The area whose screen shows the setting.
  final SettingsArea area;

  /// Words in English and German that also find the setting.
  final List<String> synonyms;
}

/// One result of the settings search: an area (`item` is null), or a
/// single setting in it.
typedef SettingsHit = ({SettingsArea area, SettingsItem? item});

/// Finds the areas and settings for [query]: every word of the query must
/// appear in the title, the area's title or a synonym. [available] leaves
/// out settings this phone or account does not have; [title] and
/// [areaTitle] give the texts in the app's language.
List<SettingsHit> searchSettings(
  String query, {
  required bool Function(SettingsItem item) available,
  required String Function(SettingsItem item) title,
  required String Function(SettingsArea area) areaTitle,
}) {
  final words = fold(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return const [];
  bool matches(String text) => words.every(fold(text).contains);
  return [
    for (final area in SettingsArea.values) ...[
      if (matches(areaTitle(area))) (area: area, item: null),
      for (final item in SettingsItem.values)
        if (item.area == area &&
            available(item) &&
            matches([title(item), areaTitle(area), ...item.synonyms].join(' ')))
          (area: area, item: item),
    ],
  ];
}

/// Lower case without umlauts and accents, so `prufen` finds `prüfen` and
/// `Akku` finds `akku`.
String fold(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final c = String.fromCharCode(rune);
    out.write(_folds[c] ?? c);
  }
  return out.toString();
}

const _folds = {
  'ä': 'a',
  'ö': 'o',
  'ü': 'u',
  'ß': 'ss',
  'é': 'e',
  'è': 'e',
  'à': 'a',
};
