import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/repositories/attention/attention_repository.dart';
import 'package:waylight_mobile/data/repositories/diagnostics/diagnostics_repository.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/repositories/quick_tiles/quick_tiles_repository.dart';
import 'package:waylight_mobile/data/repositories/reminders/reminder_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/address_check.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/backup_health.dart';
import 'package:waylight_mobile/domain/models/diagnostics.dart';
import 'package:waylight_mobile/domain/models/quick_tile.dart';
import 'package:waylight_mobile/domain/models/reminder.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_area.dart';
import 'package:waylight_mobile/ui/settings/view_models/settings_index.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Reads the app's version and build number, e.g. `1.0.0 (12)`.
typedef AppVersionReader = Future<String> Function();

Future<String> _platformVersion() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

/// The state and actions of the settings start page and its areas (#14,
/// #231). Every settings screen hosts its own instance.
class SettingsViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading account and versions.
  SettingsViewModel({
    required this._serverRepository,
    required this._sessionRepository,
    required this._preferencesRepository,
    AppLockRepository? lockRepository,
    PushRepository? pushRepository,
    ThemeRepository? themeRepository,
    ReminderRepository? reminderRepository,
    QuickTilesRepository? quickTilesRepository,
    AppVersionReader appVersion = _platformVersion,
    DiagnosticsRepository? diagnosticsRepository,
    AttentionRepository? attentionRepository,
    this._widgetData,
  }) : _lock = lockRepository,
       _attention = attentionRepository,
       _diagnostics = diagnosticsRepository,
       _readAppVersion = appVersion,
       _push = pushRepository,
       _theme = themeRepository,
       _reminders = reminderRepository,
       _quickTiles = quickTilesRepository {
    _loadTileChoice().ignore();
    _loadBackup().ignore();
    account = Command0(_serverRepository.status)..execute().ignore();
    serverVersion = Command0(_serverRepository.version)..execute().ignore();
    this.appVersion = Command0(() async => Result.ok(await appVersion()))
      ..execute().ignore();
    signOut = Command0(_sessionRepository.signOut);
    disconnect = Command0(_disconnect);
    _preferencesRepository.addListener(notifyListeners);
    _serverRepository.addListener(notifyListeners);
    _lock?.addListener(notifyListeners);
    _theme?.addListener(notifyListeners);
    _reminders?.addListener(notifyListeners);
    _attention?.addListener(notifyListeners);
    if ((_serverRepository.current, _attention) case (
      final server?,
      final attention?,
    )) {
      // After the first frame: the repository notifies the dashboard too,
      // which must not happen while the router builds this screen.
      Future.microtask(() => attention.refresh(server)).ignore();
    }
    _lock?.available().then((available) {
      _lockAvailable = available;
      notifyListeners();
    }).ignore();
    _loadPush().ignore();
    setPush = Command1(_setPush);
  }

  final PushRepository? _push;
  final WidgetDataRepository? _widgetData;
  BackupStatus? _backup;

  /// The traffic light of the server's backups; `null` while unknown and
  /// for accounts the server does not show it to (owner only).
  BackupStatus? get backup => _backup;

  Future<void> _loadBackup() async {
    final server = _serverRepository.current;
    final data = _widgetData;
    if (server == null || data == null) return;
    _backup = switch (await data.read(server, backupStatusQuery)) {
      Ok(:final value) => value,
      Error() => null,
    };
    notifyListeners();
  }

  final AttentionRepository? _attention;

  /// How many things on the server need the person's help (#229); the
  /// start page shows a hint while there are any.
  int get attentionCount => _attention?.items.length ?? 0;
  final DiagnosticsRepository? _diagnostics;
  final AppVersionReader _readAppVersion;

  /// Whether this build can create a diagnostic report (#197).
  bool get diagnosticsAvailable => _diagnostics != null;

  /// Collects the diagnostic report for the preview (#197).
  Future<DiagnosticReport?> diagnosticReport() async =>
      _diagnostics?.report(appVersion: await _readAppVersion());

  /// Opens the share sheet with [report].
  Future<void> shareDiagnostics(DiagnosticReport report) async =>
      _diagnostics?.share(report);
  final ThemeRepository? _theme;
  final ReminderRepository? _reminders;
  final QuickTilesRepository? _quickTiles;
  String _tileEntity = '';

  /// Whether this phone has Quick Settings tiles (#192).
  bool get quickTilesAvailable =>
      _quickTiles != null && defaultTargetPlatform == TargetPlatform.android;

  /// Whether this phone can pair a Wear OS watch (#239, Android only).
  bool get watchPairingAvailable =>
      defaultTargetPlatform == TargetPlatform.android;

  /// Whether this phone has home screen widgets of the app (ADR 0009).
  bool get homeWidgetsAvailable =>
      defaultTargetPlatform == TargetPlatform.android;

  /// The name of the device the smart home tile switches; empty when none.
  String get tileEntity => _tileEntity;

  Future<void> _loadTileChoice() async {
    final choice = await _quickTiles?.choice();
    _tileEntity = choice?.name ?? '';
    notifyListeners();
  }

  /// The devices the smart home tile may switch.
  Future<List<SmartEntity>> tileChoices() async {
    final server = _serverRepository.current;
    final tiles = _quickTiles;
    if (server == null || tiles == null) return const [];
    return switch (await tiles.choices(server)) {
      Ok(:final value) => value,
      Error() => const [],
    };
  }

  /// Makes the smart home tile switch [entity].
  Future<void> chooseTileEntity(SmartEntity entity) async {
    final format = quickTileFormatter;
    if (format == null) return;
    await _quickTiles?.choose(entity, format);
    _tileEntity = entity.name;
    notifyListeners();
  }

  /// The words of the tiles; set by the screen, which has the texts.
  QuickTileFormatter? quickTileFormatter;
  bool _remindersDenied = false;

  /// Whether this build can schedule reminders on the device (#190).
  bool get remindersAvailable => _reminders != null;

  /// The reminders the person chose.
  ReminderSettings get reminders =>
      _reminders?.settings ?? const ReminderSettings();

  /// Whether the last attempt to turn reminders on was refused by the
  /// system's notification permission.
  bool get remindersDenied => _remindersDenied;

  /// Stores [settings]; the first kind turned on asks for the permission.
  Future<void> setReminders(ReminderSettings settings) async {
    final reminders = _reminders;
    if (reminders == null) return;
    _remindersDenied = !await reminders.update(settings);
    notifyListeners();
    final server = _serverRepository.current;
    final format = reminderFormatter;
    if (!_remindersDenied && server != null && format != null) {
      await reminders.reschedule(server, format, force: true);
    }
  }

  /// Whether at least one kind of reminder is on.
  bool get anyReminderOn {
    final r = reminders;
    return r.todos || r.birthdays || r.eventMinutes > 0;
  }

  /// The words of the reminders; set by the screen, which has the texts.
  ReminderFormatter? reminderFormatter;

  /// Whether the system offers wallpaper colours (#198, Android 12+).
  bool get wallpaperAvailable => _theme?.wallpaperAvailable ?? false;

  /// Whether the app uses the wallpaper colours for this server.
  bool get useWallpaper => _theme?.useWallpaper ?? false;

  /// Switches between the Waylight colours and the wallpaper colours for
  /// the current server.
  Future<void> setWallpaper({required bool enabled}) async {
    final server = _serverRepository.current;
    if (server == null) return;
    await _theme?.setWallpaper(server, enabled: enabled);
  }

  bool _pushAvailable = false;
  bool _pushOn = false;

  bool _batteryUnrestricted = true;

  /// Whether this platform can receive notifications from the server
  /// (#59; Android for now).
  bool get pushAvailable => _pushAvailable;

  /// Whether Android lets the app keep its connection without battery
  /// restrictions; shown as a hint while push is on and it is not.
  bool get batteryUnrestricted => _batteryUnrestricted;

  /// Whether notifications are on for this phone.
  bool get pushOn => _pushOn;

  /// Turns notifications on (asks for the permission) or off.
  late final Command1<void, bool> setPush;

  Future<void> _loadPush() async {
    final push = _push;
    if (push == null) return;
    _pushAvailable = await push.available();
    _pushOn = await push.isOn();
    _batteryUnrestricted = await push.batteryUnrestricted();
    notifyListeners();
  }

  /// Asks the person to lift the battery restrictions and reads the answer.
  Future<void> allowInBackground() async {
    final push = _push;
    if (push == null) return;
    await push.requestBatteryUnrestricted();
    _batteryUnrestricted = await push.batteryUnrestricted();
    notifyListeners();
  }

  Future<Result<void>> _setPush(bool on) async {
    final push = _push;
    final server = _serverRepository.current;
    if (push == null || server == null) {
      return const Result.error(NotConnectedException());
    }
    final result = on ? await push.enable(server) : await push.disable(server);
    _pushOn = await push.isOn();
    _batteryUnrestricted = await push.batteryUnrestricted();
    notifyListeners();
    return result;
  }

  final ServerRepository _serverRepository;
  final SessionRepository _sessionRepository;
  final PreferencesRepository _preferencesRepository;
  final AppLockRepository? _lock;
  bool _lockAvailable = false;

  /// Whether the phone has a screen lock the app lock can use (#46).
  bool get lockAvailable => _lockAvailable;

  /// Whether the app lock is on.
  bool get lockEnabled => _lock?.enabled ?? false;

  /// How long the app may be in the background before it locks.
  Duration get lockTimeout => _lock?.timeout ?? Duration.zero;

  /// Turns the app lock on (after one confirmation) or off.
  Future<void> setLock(bool enabled, {required String reason}) async =>
      _lock?.setEnabled(enabled, reason: reason);

  /// Changes how long the app may be in the background.
  Future<void> setLockTimeout(Duration timeout) async =>
      _lock?.setTimeout(timeout);

  /// The signed-in account (name and role) as the server sees it.
  late final Command0<ServerStatus> account;

  /// The version of the server, if the account may see it.
  late final Command0<String> serverVersion;

  /// The version and build number of the app.
  late final Command0<String> appVersion;

  /// Signs out; the router then shows the sign-in screen.
  late final Command0<void> signOut;

  /// Signs out and forgets the server.
  late final Command0<void> disconnect;

  /// The servers used on this device (#51).
  List<ServerAddress> get servers => _serverRepository.known;

  /// Switches to [server] with the session stored for it, if any.
  Future<void> switchTo(ServerAddress server) async {
    await _serverRepository.switchTo(server);
    await _sessionRepository.restore(server);
  }

  /// Leaves the current server, keeping its session, to add another one.
  Future<void> addServer() => _serverRepository.leave();

  /// Removes [server] and the session stored for it.
  Future<void> removeServer(ServerAddress server) async {
    if (server == _serverRepository.current) {
      await _sessionRepository.signOut();
    } else {
      await _sessionRepository.discard(server);
    }
    await _serverRepository.forget(server);
  }

  /// The address of the connected server.
  String get server => _serverRepository.current?.toString() ?? '';

  /// The addresses of the server in the order they are tried (#189).
  List<ServerAddress> get addresses => _serverRepository.addresses;

  /// The address in use right now; `null` when none answered.
  ServerAddress? get activeAddress => _serverRepository.active;

  /// What the last check of [address] found.
  AddressCheck checkOf(ServerAddress address) =>
      _serverRepository.checks[address] ?? AddressCheck.unknown;

  /// Tries the addresses again in their order and uses the first that
  /// answers.
  Future<void> checkAddresses() => _serverRepository.selectAddress();

  /// Reads again what another settings screen may have changed and no
  /// repository announces: push, battery and the tile choice.
  Future<void> refresh() async {
    await _loadPush();
    await _loadTileChoice();
    await _loadBackup();
  }

  String _query = '';

  /// What the person typed into the settings search (#232).
  String get query => _query;

  /// Filters the start page by [query]; empty shows the areas again.
  void search(String query) {
    _query = query;
    notifyListeners();
  }

  /// Whether the start page and the search list [area]: an area without
  /// anything this phone can set stays off; its link still opens.
  bool showsArea(SettingsArea area) =>
      area != SettingsArea.notifications || pushAvailable || remindersAvailable;

  /// Whether this phone and account have [item], so the search may find
  /// it.
  bool available(SettingsItem item) => switch (item) {
    SettingsItem.push || SettingsItem.battery => pushAvailable,
    SettingsItem.reminders => remindersAvailable,
    SettingsItem.lock => lockAvailable,
    SettingsItem.homeWidgets => homeWidgetsAvailable,
    SettingsItem.pairWatch => watchPairingAvailable,
    SettingsItem.quickTiles => quickTilesAvailable,
    SettingsItem.colours => wallpaperAvailable,
    SettingsItem.diagnostics => diagnosticsAvailable,
    SettingsItem.serverVersion => serverVersion.result is Ok,
    _ => true,
  };

  /// Whether another address can be added.
  bool get canAddAddress => addresses.length < ServerRepository.maxAddresses;

  /// Adds [input] as the last address; returns why it was refused, if so.
  Future<InvalidServerAddressReason?> addAddress(String input) async {
    switch (ServerAddress.parse(input)) {
      case Error(error: final InvalidServerAddress e):
        return e.reason;
      case Error():
        return InvalidServerAddressReason.malformed;
      case Ok(:final value):
        if (addresses.contains(value) || !canAddAddress) return null;
        await _serverRepository.setAddresses([...addresses, value]);
        return null;
    }
  }

  /// Removes [address]; the last one stays.
  Future<void> removeAddress(ServerAddress address) async {
    if (addresses.length < 2) return;
    await _serverRepository.setAddresses([
      for (final a in addresses)
        if (a != address) a,
    ]);
  }

  /// Moves [address] one place up, so it is tried earlier.
  Future<void> raiseAddress(ServerAddress address) async {
    final list = [...addresses];
    final i = list.indexOf(address);
    if (i < 1) return;
    list
      ..removeAt(i)
      ..insert(i - 1, address);
    await _serverRepository.setAddresses(list);
  }

  /// The look of the app.
  Appearance get appearance => _preferencesRepository.appearance;

  /// Applies and stores another theme.
  void setTheme(ThemeChoice theme) => _preferencesRepository
      .setAppearance(appearance.copyWith(theme: theme))
      .ignore();

  /// Applies and stores another language.
  void setLanguage(AppLanguage language) => _preferencesRepository
      .setAppearance(appearance.copyWith(language: language))
      .ignore();

  // A session must never outlive its server in the app (#13).
  Future<Result<void>> _disconnect() async {
    await _sessionRepository.signOut();
    return _serverRepository.disconnect();
  }

  @override
  void dispose() {
    _preferencesRepository.removeListener(notifyListeners);
    _serverRepository.removeListener(notifyListeners);
    _lock?.removeListener(notifyListeners);
    _theme?.removeListener(notifyListeners);
    _reminders?.removeListener(notifyListeners);
    _attention?.removeListener(notifyListeners);
    for (final c in [account, serverVersion, appVersion, signOut, disconnect]) {
      c.dispose();
    }
    super.dispose();
  }
}
