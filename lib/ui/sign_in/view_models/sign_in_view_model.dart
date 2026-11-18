import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// What the user entered on the sign-in screen.
typedef Credentials = ({String username, String password, String code});

/// The state and actions of the sign-in screen (#12).
///
/// Navigation after a successful sign-in is done by the router, which
/// listens to the session repository.
class SignInViewModel extends ChangeNotifier {
  /// Creates the view model.
  SignInViewModel({
    required this._serverRepository,
    required this._sessionRepository,
  }) : expired = _sessionRepository.expired {
    signIn = Command1(_signIn);
    useAnotherServer = Command0(_serverRepository.disconnect);
  }

  final ServerRepository _serverRepository;
  final SessionRepository _sessionRepository;
  CodeRequired? _codeRequired;

  /// Signs in with the entered [Credentials].
  late final Command1<SignInResult, Credentials> signIn;

  /// Forgets the server; the router then shows the connect screen.
  late final Command0<void> useAnotherServer;

  /// Whether the server ended the previous session, so the screen can say
  /// why the user has to sign in again.
  final bool expired;

  /// Set once the server asked for a second factor; the screen then shows
  /// the code field.
  CodeRequired? get codeRequired => _codeRequired;

  /// The address of the connected server, for display.
  String get server => _serverRepository.current?.toString() ?? '';

  Future<Result<SignInResult>> _signIn(Credentials input) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _sessionRepository.signIn(
      server,
      username: input.username,
      password: input.password,
      code: input.code,
    );
    if (result case Ok(value: final CodeRequired step)) {
      _codeRequired = step;
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    signIn.dispose();
    useAnotherServer.dispose();
    super.dispose();
  }
}
