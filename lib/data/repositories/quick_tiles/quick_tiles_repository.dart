import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/presence/presence_repository.dart';
import 'package:waylight_mobile/data/services/quick_tiles/quick_tile_store.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/domain/models/quick_tile.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Keeps the Quick Settings tiles up to date and runs their actions (#192).
/// The tiles reach the server only through this repository, with the app's
/// session, so they hold no logic of their own.
class QuickTilesRepository {
  /// Creates the repository.
  const QuickTilesRepository({
    required this._smartHome,
    required this._presence,
    required this._store,
  });

  final SmartHomeRepository _smartHome;
  final PresenceRepository _presence;
  final QuickTileStore _store;

  /// Reads the current states. The status tile is offered only while the
  /// server has presence; other failures keep what the tiles show.
  Future<void> refresh(
    ServerAddress server, {
    required QuickTileFormatter format,
  }) async {
    switch (await _presence.board(server)) {
      case Ok(:final value):
        await _store.offer(QuickTileKind.status, offered: true);
        await _store.save(
          QuickTileKind.status,
          format.status(value.mine?.status ?? PresenceStatus.none),
        );
      case Error(error: ApiException(failure: ApiFailure.notFound)):
        await _store.offer(QuickTileKind.status, offered: false);
      case Error():
        break;
    }
    if (await _store.choice() case final choice?) {
      if (await _entity(server, choice.id) case Ok(:final value)) {
        await _store.save(QuickTileKind.smartHome, format.smartHome(value));
      }
    }
  }

  /// Runs the action of the tile [kind] and saves the state it leads to.
  /// On a failure the tile shows that the server was not reachable.
  Future<Result<void>> run(
    ServerAddress server,
    QuickTileKind kind, {
    required QuickTileFormatter format,
  }) async {
    switch (kind) {
      case QuickTileKind.capture:
        return const Result.ok(null);
      case QuickTileKind.status:
        return _cycleStatus(server, format);
      case QuickTileKind.smartHome:
        final choice = await _store.choice();
        if (choice == null) {
          return const Result.error(ApiException(ApiFailure.notFound));
        }
        return _switch(server, choice, format);
    }
  }

  /// The entities a tile may switch: those the owner allowed to switch or
  /// press.
  Future<Result<List<SmartEntity>>> choices(ServerAddress server) async =>
      switch (await _smartHome.entities(server)) {
        Ok(:final value) => Result.ok(value.where(switchableOnTile).toList()),
        Error(:final error) => Result.error(error),
      };

  /// Makes the smart home tile switch [entity] and shows its state.
  Future<void> choose(SmartEntity entity, QuickTileFormatter format) async {
    await _store.choose(QuickTileEntity(id: entity.id, name: entity.name));
    await _store.save(QuickTileKind.smartHome, format.smartHome(entity));
  }

  /// The entity the smart home tile switches, if one was chosen.
  Future<QuickTileEntity?> choice() => _store.choice();

  /// Forgets every state and choice and hides the status tile.
  Future<void> clear() async {
    await _store.clear();
    await _store.offer(QuickTileKind.status, offered: false);
  }

  /// Tells the native side that a tile's action has ended.
  Future<void> finish() => _store.finished();

  Future<Result<void>> _cycleStatus(
    ServerAddress server,
    QuickTileFormatter format,
  ) async {
    final board = await _presence.board(server);
    final Result<PresenceStatus> next = switch (board) {
      Ok(:final value) => Result.ok(
        nextStatus(value.mine?.status ?? PresenceStatus.none),
      ),
      Error(:final error) => Result.error(error),
    };
    final result = switch (next) {
      Ok(:final value) => switch (await _presence.setMine(server, value)) {
        Ok() => Result.ok(value),
        Error(:final error) => Result<PresenceStatus>.error(error),
      },
      Error(:final error) => Result<PresenceStatus>.error(error),
    };
    switch (result) {
      case Ok(:final value):
        await _store.save(QuickTileKind.status, format.status(value));
        return const Result.ok(null);
      case Error(error: ApiException(failure: ApiFailure.notFound)):
        await _store.offer(QuickTileKind.status, offered: false);
        return const Result.error(ApiException(ApiFailure.notFound));
      case Error(:final error):
        await _store.save(
          QuickTileKind.status,
          format.unreachable(QuickTileKind.status, ''),
        );
        return Result.error(error);
    }
  }

  Future<Result<void>> _switch(
    ServerAddress server,
    QuickTileEntity choice,
    QuickTileFormatter format,
  ) async {
    final acted = await _smartHome.act(server, choice.id);
    final state = switch (acted) {
      Ok() => await _entity(server, choice.id),
      Error(:final error) => Result<SmartEntity>.error(error),
    };
    switch (state) {
      case Ok(:final value):
        await _store.save(QuickTileKind.smartHome, format.smartHome(value));
        return const Result.ok(null);
      case Error(:final error):
        await _store.save(
          QuickTileKind.smartHome,
          format.unreachable(QuickTileKind.smartHome, choice.name),
        );
        return Result.error(error);
    }
  }

  Future<Result<SmartEntity>> _entity(ServerAddress server, String id) async =>
      switch (await _smartHome.entities(server, ids: [id])) {
        Ok(value: [final e, ...]) => Result.ok(e),
        Ok() => const Result.error(ApiException(ApiFailure.notFound)),
        Error(:final error) => Result.error(error),
      };
}
