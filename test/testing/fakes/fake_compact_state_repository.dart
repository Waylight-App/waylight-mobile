import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [CompactStateRepository] in memory.
class FakeCompactStateRepository implements CompactStateRepository {
  /// Creates the fake for the kinds in [kinds].
  FakeCompactStateRepository({this.kinds = const {}});

  /// The kinds with a compact state.
  final Set<String> kinds;

  /// What [state] returns.
  Result<CompactState> result = const Result.ok(
    CompactState(title: CompactText(text: '')),
  );

  /// What [state] returns for a kind instead of [result].
  final Map<String, Result<CompactState>> byKind = {};

  /// The kinds asked for.
  final List<String> asked = [];

  /// The configurations passed along with [asked].
  final List<Map<String, Object?>> configs = [];

  /// The servers passed to [load].
  final List<ServerAddress> loaded = [];

  @override
  Future<void> load(ServerAddress server, {bool reuse = false}) async =>
      loaded.add(server);

  @override
  bool supports(String kind, {Map<String, Object?> config = const {}}) =>
      kinds.contains(kind);

  /// The actions run, with their choice.
  final List<(CompactAction, CompactChoice?)> ran = [];

  /// What [run] returns.
  Result<void> runResult = const Result.ok(null);

  @override
  Future<Result<void>> run(
    ServerAddress server,
    CompactAction action, {
    CompactChoice? choice,
  }) async {
    ran.add((action, choice));
    return runResult;
  }

  @override
  Future<Result<CompactState>> state(
    ServerAddress server,
    String kind, {
    Map<String, Object?> config = const {},
  }) async {
    asked.add(kind);
    configs.add(config);
    return byKind[kind] ?? result;
  }
}
