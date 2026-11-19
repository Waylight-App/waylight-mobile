import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/account/account_security_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/account_security.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the account security screen (#110).
class SecurityViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  SecurityViewModel({
    required this._serverRepository,
    required this._security,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  final ServerRepository _serverRepository;
  final AccountSecurityRepository _security;

  List<AccountSession> _sessions = const [];
  bool _totp = false;

  /// Loads sessions and the two-factor state.
  late final Command0<void> load;

  /// The active sessions, the app's own first.
  List<AccountSession> get sessions => _sessions;

  /// Whether two-factor sign-in is on.
  bool get totpEnabled => _totp;

  Future<Result<T>> _with<T>(
    Future<Result<T>> Function(ServerAddress server) call,
  ) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return call(server);
  }

  Future<Result<void>> _load() => _with((server) async {
    final sessions = await _security.sessions(server);
    final totp = await _security.totpEnabled(server);
    switch (sessions) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        _sessions = [
          ...value.where((s) => s.current),
          ...value.where((s) => !s.current),
        ];
    }
    if (totp case Ok(:final value)) _totp = value;
    notifyListeners();
    return const Result.ok(null);
  });

  /// Signs out one session.
  Future<Result<void>> revoke(AccountSession session) async {
    final result = await _with(
      (server) => _security.revoke(server, session.id),
    );
    if (result is Ok<void>) await load.execute();
    return result;
  }

  /// Signs out every other session.
  Future<Result<void>> revokeOthers() async {
    final result = await _with(_security.revokeOthers);
    if (result is Ok<void>) await load.execute();
    return result;
  }

  /// Changes the password.
  Future<Result<void>> changePassword(String current, String next) async {
    final result = await _with(
      (server) =>
          _security.changePassword(server, current: current, next: next),
    );
    if (result is Ok<void>) await load.execute();
    return result;
  }

  /// Starts connecting an authenticator app.
  Future<Result<TotpSetup>> startTotp() => _with(_security.startTotp);

  /// Confirms the setup and returns the recovery codes.
  Future<Result<List<String>>> confirmTotp(String code) async {
    final result = await _with((server) => _security.confirmTotp(server, code));
    if (result is Ok<List<String>>) {
      _totp = true;
      notifyListeners();
    }
    return result;
  }

  /// Turns two-factor sign-in off.
  Future<Result<void>> disableTotp(String password, String code) async {
    final result = await _with(
      (server) => _security.disableTotp(server, password: password, code: code),
    );
    if (result is Ok<void>) {
      _totp = false;
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
