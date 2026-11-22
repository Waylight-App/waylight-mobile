import 'package:waylight_mobile/data/repositories/help/help_repository.dart';
import 'package:waylight_mobile/domain/models/help.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [HelpRepository] without network for tests.
class FakeHelpRepository implements HelpRepository {
  /// The help by widget kind.
  Map<String, WidgetHelp> byKind = {};

  /// When set, every call fails with it.
  Result<WidgetHelp?>? failure;

  /// The kinds asked for.
  final List<String> asked = [];

  @override
  Future<Result<WidgetHelp?>> helpOf(ServerAddress server, String kind) async {
    asked.add(kind);
    return failure ?? Result.ok(byKind[kind]);
  }
}
