import 'package:waylight_mobile/data/services/api/help_api.dart';
import 'package:waylight_mobile/domain/models/help.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The help of the widget kinds (#289).
abstract interface class HelpRepository {
  /// The help of [kind] on [server]; `null` when the server has none, e.g.
  /// an older server without the help.
  Future<Result<WidgetHelp?>> helpOf(ServerAddress server, String kind);
}

/// A [HelpRepository] that asks the server once per address and keeps the
/// answer: the help texts do not change while the app runs.
class HelpRepositoryRemote implements HelpRepository {
  /// Creates the repository.
  HelpRepositoryRemote({required this._api});

  final HelpApi _api;
  final Map<String, Map<String, WidgetHelp>> _byServer = {};

  @override
  Future<Result<WidgetHelp?>> helpOf(ServerAddress server, String kind) async {
    final key = server.resolve('/').toString();
    if (_byServer[key] case final cached?) return Result.ok(cached[kind]);
    switch (await _api.widgets(server)) {
      case Ok(:final value):
        final byKind = {for (final h in value) h.kind: h};
        _byServer[key] = byKind;
        return Result.ok(byKind[kind]);
      case Error(:final error):
        return Result.error(error);
    }
  }
}
