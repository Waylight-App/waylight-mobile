import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/attention/attention_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state and actions of *Needs your attention* (#229).
class AttentionViewModel extends ChangeNotifier {
  /// Creates the view model and reads the list.
  AttentionViewModel({
    required this._serverRepository,
    required this._attentionRepository,
  }) {
    _attentionRepository.addListener(notifyListeners);
    load = Command0(_load)..execute().ignore();
    check = Command1(_check);
  }

  final ServerRepository _serverRepository;
  final AttentionRepository _attentionRepository;

  /// Reads the list again.
  late final Command0<List<AttentionItem>> load;

  /// Asks the server again about the entry with the given id; the result
  /// tells whether it is still listed.
  late final Command1<bool, String> check;

  /// Connections that stopped working, oldest first.
  List<AttentionItem> get broken => [
    for (final item in _attentionRepository.items)
      if (item.kind == AttentionKind.connection) item,
  ];

  /// Widgets and integrations that are not set up yet, oldest first.
  List<AttentionItem> get setup => [
    for (final item in _attentionRepository.items)
      if (item.kind == AttentionKind.setup) item,
  ];

  /// Where the web interface resolves [item]: the settings of its
  /// integration. The web interface falls back to its first section for
  /// integrations without settings of their own.
  Uri? webUrl(AttentionItem item) =>
      (_serverRepository.active ?? _serverRepository.current)
          ?.resolve('/')
          .replace(
            queryParameters: item.integration.isEmpty
                ? null
                : {'settings': item.integration},
          );

  Future<Result<List<AttentionItem>>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _attentionRepository.refresh(server);
  }

  Future<Result<bool>> _check(String id) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return switch (await _attentionRepository.refresh(server)) {
      Ok(:final value) => Result.ok(value.any((item) => item.id == id)),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  void dispose() {
    _attentionRepository.removeListener(notifyListeners);
    load.dispose();
    check.dispose();
    super.dispose();
  }
}
