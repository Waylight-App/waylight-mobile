import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/habits/habits_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/habit.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the habits widget (#128): today's habits, ticked off with
/// one tap and undone when the server refuses.
class HabitsViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  HabitsViewModel({
    required this._serverRepository,
    required this._habitsRepository,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  final ServerRepository _serverRepository;
  final HabitsRepository _habitsRepository;

  List<Habit> _habits = const [];
  Exception? _lastError;

  /// Loads the habits; run again to reload.
  late final Command0<void> load;

  /// The habits due today.
  List<Habit> get today => _habits.where((h) => h.dueToday).toList();

  /// The last refused change, once.
  Exception? takeLastError() {
    final e = _lastError;
    _lastError = null;
    return e;
  }

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    switch (await _habitsRepository.habits(server)) {
      case Ok(:final value):
        _habits = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Ticks [habit] off for today, or on again.
  Future<void> toggle(Habit habit) async {
    final server = _serverRepository.current;
    if (server == null) return;
    _replace(habit.toggled());
    if (await _habitsRepository.toggle(server, habit.id) case Error(
      :final error,
    )) {
      _replace(habit);
      _lastError = error;
      notifyListeners();
    }
  }

  void _replace(Habit habit) {
    _habits = [for (final h in _habits) h.id == habit.id ? habit : h];
    notifyListeners();
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
