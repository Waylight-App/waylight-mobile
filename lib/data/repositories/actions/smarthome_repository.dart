import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The Home Assistant entities of the server (#146).
abstract interface class SmartHomeRepository {
  /// The entities [ids] with their current state; all chosen entities when
  /// [ids] is empty.
  Future<Result<List<SmartEntity>>> entities(
    ServerAddress server, {
    List<String> ids = const [],
  });

  /// Runs the entity's action (switch or press).
  Future<Result<void>> act(ServerAddress server, String id);
}

/// A [SmartHomeRepository] on `/api/smarthome`.
class SmartHomeRepositoryRemote implements SmartHomeRepository {
  /// Creates the repository.
  const SmartHomeRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<SmartEntity>>> entities(
    ServerAddress server, {
    List<String> ids = const [],
  }) => ids.isEmpty
      ? _api.read(server, '/api/smarthome/entities', parseEntities)
      : _api.read(
          server,
          '/api/smarthome/states',
          parseEntities,
          query: {'ids': ids.join(',')},
        );

  @override
  Future<Result<void>> act(ServerAddress server, String id) async =>
      switch (await _api.post(
        server,
        '/api/smarthome/entities/${Uri.encodeComponent(id)}/action',
      )) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };
}

/// Maps the entity lists of `/api/smarthome`.
List<SmartEntity>? parseEntities(Object? json) =>
    listOf<SmartEntity>(json, (e) {
      if (e case {
        'id': final String id,
        'name': final String name,
        'state': final String state,
      }) {
        return SmartEntity(
          id: id,
          name: name,
          state: state,
          unit: switch (e['unit']) {
            final String u => u,
            _ => '',
          },
          action: switch (e['action']) {
            'toggle' => EntityAction.toggle,
            'press' => EntityAction.press,
            _ => EntityAction.none,
          },
        );
      }
      return null;
    });
