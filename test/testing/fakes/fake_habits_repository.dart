import 'package:waylight_mobile/data/repositories/habits/habits_repository.dart';
import 'package:waylight_mobile/domain/models/habit.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [HabitsRepository] in memory; [fail] makes toggling fail.
class FakeHabitsRepository implements HabitsRepository {
  /// The habits.
  List<Habit> habitList = [];

  /// The error toggling fails with, if any.
  Exception? fail;

  /// The ids toggled.
  final List<String> toggled = [];

  @override
  Future<Result<List<Habit>>> habits(ServerAddress server) async =>
      Result.ok(habitList);

  @override
  Future<Result<void>> toggle(ServerAddress server, String id) async {
    toggled.add(id);
    if (fail case final e?) return Result.error(e);
    return const Result.ok(null);
  }
}
