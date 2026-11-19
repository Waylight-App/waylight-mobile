import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/lock/app_lock_repository.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Unlocks the app (#46); the router leaves the lock screen afterwards.
class LockViewModel extends ChangeNotifier {
  /// Creates the view model.
  LockViewModel({required this._lock}) {
    unlock = Command1(_unlock);
  }

  final AppLockRepository _lock;

  /// Asks for biometrics or the device PIN with the given reason.
  late final Command1<bool, String> unlock;

  Future<Result<bool>> _unlock(String reason) async =>
      Result.ok(await _lock.unlock(reason));

  @override
  void dispose() {
    unlock.dispose();
    super.dispose();
  }
}
