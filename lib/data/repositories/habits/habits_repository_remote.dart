import 'package:waylight_mobile/data/repositories/habits/habits_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/habit.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [HabitsRepository] on `/api/habits`.
class HabitsRepositoryRemote implements HabitsRepository {
  /// Creates the repository.
  const HabitsRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<Habit>>> habits(ServerAddress server) =>
      _api.read(server, '/api/habits', parseHabits);

  @override
  Future<Result<void>> toggle(ServerAddress server, String id) async =>
      switch (await _api.post(
        server,
        '/api/habits/${Uri.encodeComponent(id)}/toggle',
      )) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };
}

/// Maps `GET /api/habits`; a habit is due today when the last day of its
/// heatmap is.
List<Habit>? parseHabits(Object? json) => listOf<Habit>(json, (h) {
  if (h case {
    'id': final String id,
    'name': final String name,
    'doneToday': final bool done,
  }) {
    final heatmap = h['heatmap'];
    final due = switch (heatmap) {
      final List<Object?> days when days.isNotEmpty => switch (days.last) {
        {'due': final bool d} => d,
        _ => true,
      },
      _ => true,
    };
    return Habit(
      id: id,
      name: name,
      doneToday: done,
      dueToday: due,
      emoji: switch (h['emoji']) {
        final String e => e,
        _ => '',
      },
      current: (h['current'] as num?)?.toInt() ?? 0,
      best: (h['best'] as num?)?.toInt() ?? 0,
    );
  }
  return null;
});
