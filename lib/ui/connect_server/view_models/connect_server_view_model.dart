import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state and actions of the screen that connects a server.
class ConnectServerViewModel extends ChangeNotifier {
  /// Creates the view model.
  ConnectServerViewModel({required this._serverRepository}) {
    connect = Command1(_connect);
  }

  final ServerRepository _serverRepository;
  bool _insecure = false;

  /// Checks the entered address and saves it if a Waylight server answers.
  late final Command1<ServerStatus, String> connect;

  /// The public demo, to try the app without a server of one's own (#44).
  static const demoAddress = 'https://demo.getwaylight.app';

  /// Connects the public demo.
  Future<void> tryDemo() => connect.execute(demoAddress);

  /// Whether the entered address uses plain HTTP; the screen warns then.
  bool get insecure => _insecure;

  /// Updates [insecure] for the text the user is typing.
  void onAddressChanged(String input) {
    final insecure = input.trim().toLowerCase().startsWith('http://');
    if (insecure == _insecure) return;
    _insecure = insecure;
    notifyListeners();
  }

  Future<Result<ServerStatus>> _connect(String input) async {
    switch (ServerAddress.parse(input)) {
      case Ok(:final value):
        return _serverRepository.connect(value);
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    connect.dispose();
    super.dispose();
  }
}
