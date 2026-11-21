import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/data/services/home_widgets/home_widget_store.dart';
import 'package:waylight_mobile/domain/models/compact_derived.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Keeps the home screen widgets up to date (#42, #48): it reads the data
/// through the same repositories as the app and stores one card per widget.
class HomeWidgetsRepository {
  /// Creates the repository.
  HomeWidgetsRepository({
    required this._dashboard,
    required this._todos,
    required this._transit,
    required this._store,
    this._compact,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DashboardRepository _dashboard;
  final TodosRepository _todos;
  final TransitRepository _transit;
  final HomeWidgetStore _store;
  final CompactStateRepository? _compact;
  final DateTime Function() _clock;
  DateTime? _last;

  /// How many entries a widget shows at most.
  static const maxLines = 5;

  /// The shortest time between two refreshes from the app.
  static const minInterval = Duration(minutes: 5);

  /// Refreshes the cards, formatted by [format]; [dashboard] saves loading
  /// it again. A refresh within [minInterval] of the last one is skipped
  /// unless [force] is set. A card that fails to load keeps its older data.
  Future<Result<void>> refresh(
    ServerAddress server, {
    required HomeWidgetFormatter format,
    Dashboard? dashboard,
    bool force = false,
  }) async {
    final now = _clock();
    if (!force && _last != null && now.difference(_last!) < minInterval) {
      return const Result.ok(null);
    }
    _last = now;
    var saved = false;
    if (await _today(server, now) case final today?) {
      await _store.save(
        HomeWidgetKind.todos,
        format.todos(today, now, compact: await _serverState(server, 'todos')),
      );
      saved = true;
    }
    final board =
        dashboard ??
        switch (await _dashboard.dashboard(server)) {
          Ok(:final value) => value,
          Error() => null,
        };
    final transit = board?.tabs
        .expand((t) => t.widgets)
        .where((w) => w.kind == 'transit')
        .firstOrNull;
    final stop = transit?.config['stopId'];
    final name = switch (transit?.config['stopName']) {
      final String n => n,
      _ => '',
    };
    if (stop is! String || stop.isEmpty) {
      if (board != null) {
        await _store.save(
          HomeWidgetKind.departures,
          format.departures('', null, now),
        );
        saved = true;
      }
    } else if (await _transit.departures(server, stop: stop, count: maxLines)
        case Ok(:final value)) {
      await _store.save(
        HomeWidgetKind.departures,
        format.departures(
          name,
          value,
          now,
          compact: compactDepartures(value, now),
        ),
      );
      saved = true;
    }
    return saved
        ? const Result.ok(null)
        : const Result.error(HomeWidgetsUnavailable());
  }

  /// Removes the cards and stops the refresh in the background.
  Future<void> clear() async {
    _last = null;
    await _store.schedule(enabled: false);
    await _store.clear();
  }

  /// Starts the refresh in the background while signed in.
  Future<void> schedule() => _store.schedule(enabled: true);

  /// Tells the native job that the background refresh has ended.
  Future<void> finishBackground() => _store.finished();

  /// The compact state of [kind] when the server offers one (#242); `null`
  /// otherwise or on error, so the card shows its lines only.
  Future<CompactState?> _serverState(ServerAddress server, String kind) async {
    final compact = _compact;
    if (compact == null) return null;
    // The background refresh starts without the module list (#274).
    await compact.load(server, reuse: true);
    if (!compact.supports(kind)) return null;
    return switch (await compact.state(server, kind)) {
      Ok(:final value) => value,
      Error() => null,
    };
  }

  /// Open to-dos due today or overdue, at most [maxLines]; `null` on error.
  Future<List<Todo>?> _today(ServerAddress server, DateTime now) async {
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    return switch (await _todos.todos(server)) {
      Ok(:final value) => [
        for (final t in value)
          if (!t.done && (t.overdue || (t.due?.isBefore(endOfDay) ?? false))) t,
      ].take(maxLines).toList(),
      Error() => null,
    };
  }
}

/// No card could be loaded; the widgets keep their older data.
final class HomeWidgetsUnavailable implements Exception {
  /// Creates the error.
  const HomeWidgetsUnavailable();
}
