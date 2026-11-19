import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/services/platform/device_auth.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';

/// The optional app lock (#46): when on, the app asks for biometrics or the
/// device PIN when it starts and when it returns after `timeout` in the
/// background. Nothing about it goes to the server.
class AppLockRepository extends ChangeNotifier {
  /// Creates the repository; the clock can be replaced in tests.
  AppLockRepository({
    required this._auth,
    required this._store,
    this._now = DateTime.now,
  });

  /// The keys of the stored settings.
  static const enabledKey = 'lock.enabled';

  /// See [enabledKey].
  static const timeoutKey = 'lock.timeoutSeconds';

  /// The choices for [timeout].
  static const timeouts = [
    Duration.zero,
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  final DeviceAuth _auth;
  final KeyValueStore _store;
  final DateTime Function() _now;

  bool _enabled = false;
  bool _locked = false;
  Duration _timeout = const Duration(minutes: 1);
  DateTime? _hiddenAt;

  /// Whether the lock is on.
  bool get enabled => _enabled;

  /// Whether the app waits to be unlocked.
  bool get locked => _locked;

  /// How long the app may be in the background before it locks.
  Duration get timeout => _timeout;

  /// Whether the phone has a screen lock to ask for.
  Future<bool> available() => _auth.available();

  /// Loads the settings; a lock that is on locks the app at start.
  Future<void> restore() async {
    try {
      _enabled = await _store.read(enabledKey) == 'true';
      final seconds = int.tryParse(await _store.read(timeoutKey) ?? '');
      if (seconds != null) _timeout = Duration(seconds: seconds);
    } on Exception {
      _enabled = false;
    }
    _locked = _enabled;
    notifyListeners();
  }

  /// Turns the lock on after the person confirmed once, or off.
  Future<bool> setEnabled(bool enabled, {required String reason}) async {
    if (enabled && !await _auth.confirm(reason)) return false;
    _enabled = enabled;
    await _store.write(enabledKey, '$enabled');
    notifyListeners();
    return true;
  }

  /// Changes how long the app may be in the background.
  Future<void> setTimeout(Duration timeout) async {
    _timeout = timeout;
    await _store.write(timeoutKey, '${timeout.inSeconds}');
    notifyListeners();
  }

  /// The app went to the background.
  void onHidden() => _hiddenAt = _now();

  /// The app came back; it locks when it was away for [timeout] or longer.
  void onResumed() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (!_enabled || hiddenAt == null) return;
    if (_now().difference(hiddenAt) >= _timeout) {
      _locked = true;
      notifyListeners();
    }
  }

  /// Asks for biometrics or the PIN; unlocks on success.
  Future<bool> unlock(String reason) async {
    if (!await _auth.confirm(reason)) return false;
    _locked = false;
    notifyListeners();
    return true;
  }
}
