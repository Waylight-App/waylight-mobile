import 'package:waylight_mobile/data/services/quick_tiles/quick_tile_store.dart';
import 'package:waylight_mobile/domain/models/quick_tile.dart';

/// A [QuickTileStore] in memory for tests.
class FakeQuickTileStore implements QuickTileStore {
  /// What each tile shows.
  final Map<QuickTileKind, QuickTileState> states = {};

  /// Whether each tile is offered.
  final Map<QuickTileKind, bool> offered = {};

  /// The chosen entity.
  QuickTileEntity? chosen;

  /// How often an action reported its end.
  int finishedCalls = 0;

  @override
  Future<void> save(QuickTileKind kind, QuickTileState state) async =>
      states[kind] = state;

  @override
  Future<void> offer(QuickTileKind kind, {required bool offered}) async =>
      this.offered[kind] = offered;

  @override
  Future<void> choose(QuickTileEntity entity) async => chosen = entity;

  @override
  Future<QuickTileEntity?> choice() async => chosen;

  @override
  Future<void> clear() async {
    states.clear();
    chosen = null;
  }

  @override
  Future<void> finished() async => finishedCalls++;
}
