import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Reads the app's version and build number, e.g. `1.0.0 (12)`.
typedef AppVersionReader = Future<String> Function();

Future<String> _platformVersion() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

/// The state and actions of the settings screen (#14).
class SettingsViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading account and versions.
  SettingsViewModel({
    required this._serverRepository,
    required this._sessionRepository,
    required this._preferencesRepository,
    AppLockRepository? lockRepository,
    AppVersionReader appVersion = _platformVersion,
  }) : _lock = lockRepository {
    account = Command0(_serverRepository.status)..execute().ignore();
    serverVersion = Command0(_serverRepository.version)..execute().ignore();
    this.appVersion = Command0(() async => Result.ok(await appVersion()))
      ..execute().ignore();
    signOut = Command0(_sessionRepository.signOut);
    disconnect = Command0(_disconnect);
    _preferencesRepository.addListener(notifyListeners);
    _lock?.addListener(notifyListeners);
    _lock?.available().then((available) {
      _lockAvailable = available;
      notifyListeners();
    }).ignore();
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

  /// The address of the connected server.
  String get server => _serverRepository.current?.toString() ?? '';

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
    _lock?.removeListener(notifyListeners);
    for (final c in [account, serverVersion, appVersion, signOut, disconnect]) {
      c.dispose();
    }
    super.dispose();
  }
}
