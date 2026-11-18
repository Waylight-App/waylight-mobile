import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/command.dart';

/// The state and actions of the home screen.
///
/// A placeholder until sign-in (#12) and the dashboard (#16) exist.
class HomeViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading the server status.
  HomeViewModel({required this._serverRepository}) {
    load = Command0(_serverRepository.status)..execute().ignore();
    disconnect = Command0(_serverRepository.disconnect);
  }

  final ServerRepository _serverRepository;

  /// Loads the status of the connected server.
  late final Command0<ServerStatus> load;

  /// Forgets the server; the router then shows the connect screen.
  late final Command0<void> disconnect;

  /// The address of the connected server, for display.
  String get server => _serverRepository.current?.toString() ?? '';

  @override
  void dispose() {
    load.dispose();
    disconnect.dispose();
    super.dispose();
  }
}
