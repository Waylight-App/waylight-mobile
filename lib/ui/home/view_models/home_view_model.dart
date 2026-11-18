import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state and actions of the home screen.
///
/// A placeholder until the dashboard (#16) exists.
class HomeViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading the server status.
  HomeViewModel({
    required this._serverRepository,
    required this._sessionRepository,
  }) {
    load = Command0(_serverRepository.status)..execute().ignore();
    signOut = Command0(_sessionRepository.signOut);
    disconnect = Command0(_disconnect);
  }

  final ServerRepository _serverRepository;
  final SessionRepository _sessionRepository;

  /// Loads the status of the connected server.
  late final Command0<ServerStatus> load;

  /// Signs out; the router then shows the sign-in screen.
  late final Command0<void> signOut;

  /// Signs out and forgets the server; the router then shows the connect
  /// screen.
  late final Command0<void> disconnect;

  /// The address of the connected server, for display.
  String get server => _serverRepository.current?.toString() ?? '';

  // A session must never outlive its server in the app (#13).
  Future<Result<void>> _disconnect() async {
    await _sessionRepository.signOut();
    return _serverRepository.disconnect();
  }

  @override
  void dispose() {
    load.dispose();
    signOut.dispose();
    disconnect.dispose();
    super.dispose();
  }
}
