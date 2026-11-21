import 'package:flutter/foundation.dart';
import 'package:waylight_mobile/data/repositories/appearance/theme_repository.dart';
import 'package:waylight_mobile/data/repositories/first_start/first_start_repository.dart';
import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// One question of the first start (#287). Each one has its place in the
/// settings as well, so skipping loses nothing.
enum FirstStartStep {
  /// Push notifications and the battery hint.
  notifications,

  /// The app lock.
  lock,

  /// A second address of the server, for home and away (#189).
  addresses,

  /// Light, dark and the colours.
  look,
}

/// The state and actions of the first-start questions after the first
/// sign-in to a server (#287).
class FirstStartViewModel extends ChangeNotifier {
  /// Creates the view model and finds out which questions this phone has.
  FirstStartViewModel({
    required this._serverRepository,
    required this._firstStartRepository,
    required this._preferencesRepository,
    PushRepository? pushRepository,
    AppLockRepository? lockRepository,
    ThemeRepository? themeRepository,
  }) : _push = pushRepository,
       _lock = lockRepository,
       _theme = themeRepository {
    setPush = Command1(_setPush);
    _serverRepository.addListener(notifyListeners);
    _preferencesRepository.addListener(notifyListeners);
    _lock?.addListener(notifyListeners);
    _theme?.addListener(notifyListeners);
    _load().ignore();
  }

  final ServerRepository _serverRepository;
  final FirstStartRepository _firstStartRepository;
  final PreferencesRepository _preferencesRepository;
  final PushRepository? _push;
  final AppLockRepository? _lock;
  final ThemeRepository? _theme;

  List<FirstStartStep> _steps = const [];
  int _index = 0;
  bool _pushOn = false;
  bool _batteryUnrestricted = true;

  /// The questions this phone has; empty while they are being found out.
  List<FirstStartStep> get steps => _steps;

  /// The position of the current question in [steps].
  int get index => _index;

  /// The current question; only valid once [steps] is not empty.
  FirstStartStep get step => _steps[_index];

  /// Whether the current question is the last one.
  bool get isLast => _index == _steps.length - 1;

  Future<void> _load() async {
    final push = _push;
    final pushAvailable = push != null && await push.available();
    if (pushAvailable) {
      _pushOn = await push.isOn();
      _batteryUnrestricted = await push.batteryUnrestricted();
    }
    final lockAvailable = await _lock?.available() ?? false;
    _steps = [
      if (pushAvailable) FirstStartStep.notifications,
      if (lockAvailable) FirstStartStep.lock,
      FirstStartStep.addresses,
      FirstStartStep.look,
    ];
    notifyListeners();
  }

  /// Goes to the next question; after the last one the first start ends.
  Future<void> next() async {
    if (isLast) return finish();
    _index++;
    notifyListeners();
  }

  /// Goes back to the previous question.
  void back() {
    if (_index == 0) return;
    _index--;
    notifyListeners();
  }

  /// Ends the first start; the router then opens the dashboard.
  Future<void> finish() async {
    final server = _serverRepository.current;
    if (server != null) await _firstStartRepository.markDone(server);
  }

  /// Whether notifications are on for this phone.
  bool get pushOn => _pushOn;

  /// Whether Android lets the app keep its connection without battery
  /// restrictions; worth a hint while push is on and it is not.
  bool get batteryUnrestricted => _batteryUnrestricted;

  /// Turns notifications on (asks for the permission) or off.
  late final Command1<void, bool> setPush;

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

  /// Asks the person to lift the battery restrictions and reads the answer.
  Future<void> allowInBackground() async {
    final push = _push;
    if (push == null) return;
    await push.requestBatteryUnrestricted();
    _batteryUnrestricted = await push.batteryUnrestricted();
    notifyListeners();
  }

  /// Whether the app lock is on.
  bool get lockEnabled => _lock?.enabled ?? false;

  /// Turns the app lock on (after one confirmation) or off.
  Future<void> setLock(bool enabled, {required String reason}) async =>
      _lock?.setEnabled(enabled, reason: reason);

  /// The addresses of the server in the order they are tried.
  List<ServerAddress> get addresses => _serverRepository.addresses;

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

  /// Light, dark or as the system.
  ThemeChoice get theme => _preferencesRepository.appearance.theme;

  /// Applies and stores another theme.
  void setTheme(ThemeChoice theme) => _preferencesRepository
      .setAppearance(_preferencesRepository.appearance.copyWith(theme: theme))
      .ignore();

  /// Whether the system offers wallpaper colours (#198, Android 12+).
  bool get wallpaperAvailable => _theme?.wallpaperAvailable ?? false;

  /// Whether the app uses the wallpaper colours for this server.
  bool get useWallpaper => _theme?.useWallpaper ?? false;

  /// Switches between the Waylight colours and the wallpaper colours.
  Future<void> setWallpaper({required bool enabled}) async {
    final server = _serverRepository.current;
    if (server == null) return;
    await _theme?.setWallpaper(server, enabled: enabled);
  }

  @override
  void dispose() {
    _serverRepository.removeListener(notifyListeners);
    _preferencesRepository.removeListener(notifyListeners);
    _lock?.removeListener(notifyListeners);
    _theme?.removeListener(notifyListeners);
    setPush.dispose();
    super.dispose();
  }
}
