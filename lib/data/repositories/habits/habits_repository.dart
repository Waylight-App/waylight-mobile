import 'package:waylight_mobile/domain/models/habit.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The habits of the server (#128).
abstract interface class HabitsRepository {
  /// The habits with today's state.
  Future<Result<List<Habit>>> habits(ServerAddress server);

  /// Ticks today off or on again.
  Future<Result<void>> toggle(ServerAddress server, String id);
}
