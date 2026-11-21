import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/actions/focus_repository.dart';
import 'package:waylight_mobile/data/services/focus/focus_timer_service.dart';
import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/focus_timer.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The focus timer of the app (#191): one state for the widget and the
/// notification, kept outside any screen. Finished focus phases are
/// recorded on the server; offline they wait in a queue on the device.
class FocusTimerRepository extends ChangeNotifier {
  /// Creates the repository.
  FocusTimerRepository({
    required this._timer,
    required this._sessions,
    required this._store,
    Future<bool> Function()? askPermission,
  }) : _askPermission = askPermission ?? (() async => true);

  /// How long a focus phase lasts.
  static const focusLength = Duration(minutes: 25);

  /// How long a break lasts.
  static const restLength = Duration(minutes: 5);

  static const _queueKey = 'focus.unsent';

  final FocusTimerService _timer;
  final FocusRepository _sessions;
  final KeyValueStore _store;
  final Future<bool> Function() _askPermission;
  bool _asked = false;
  FocusTimerState? _state;

  /// The running or paused phase, or `null`.
  FocusTimerState? get state => _state;

  /// Reads the timer again and records finished focus phases on [server];
  /// call when the widget appears, when the app comes back and when a
  /// phase should have ended.
  Future<void> refresh(ServerAddress? server) async {
    final next = await _timer.state();
    final finished = await _timer.takeFinished();
    if (finished.isNotEmpty) await _enqueue(finished);
    if (server != null) await _flush(server);
    if (next != _state) {
      _state = next;
      notifyListeners();
    }
  }

  /// Starts [phase]; the first start asks for the notification permission
  /// (the timer runs without it, only silently).
  Future<void> start(FocusPhase phase) async {
    if (!_asked) {
      _asked = true;
      await _askPermission();
    }
    await _timer.start(
      phase,
      phase == FocusPhase.focus ? focusLength : restLength,
    );
    await _reload();
  }

  /// Pauses the running phase.
  Future<void> pause() async {
    await _timer.pause();
    await _reload();
  }

  /// Resumes the paused phase.
  Future<void> resume() async {
    await _timer.resume();
    await _reload();
  }

  /// Stops without recording.
  Future<void> stop() async {
    await _timer.stop();
    await _reload();
  }

  Future<void> _reload() async {
    _state = await _timer.state();
    notifyListeners();
  }

  Future<void> _enqueue(List<FinishedFocus> finished) async {
    final queue = await _queue();
    await _store.write(
      _queueKey,
      jsonEncode([
        ...queue,
        for (final f in finished)
          {
            'minutes': f.minutes,
            'endedAt': f.endedAt.toUtc().toIso8601String(),
          },
      ]),
    );
  }

  Future<void> _flush(ServerAddress server) async {
    final queue = await _queue();
    if (queue.isEmpty) return;
    final left = <Map<String, Object?>>[];
    for (final (i, e) in queue.indexed) {
      final ok = switch ((e['minutes'], DateTime.tryParse('${e['endedAt']}'))) {
        (final int m, final at?) =>
          await _sessions.save(server, minutes: m, endedAt: at) is Ok,
        // An entry that cannot be read is dropped.
        _ => true,
      };
      if (!ok) {
        // Offline or refused: keep this and the rest for the next time.
        left.addAll(queue.sublist(i));
        break;
      }
    }
    if (left.isEmpty) {
      await _store.delete(_queueKey);
    } else {
      await _store.write(_queueKey, jsonEncode(left));
    }
  }

  Future<List<Map<String, Object?>>> _queue() async {
    final raw = await _store.read(_queueKey);
    if (raw == null) return [];
    try {
      return [
        for (final e in jsonDecode(raw) as List<Object?>)
          if (e is Map<String, Object?>) e,
      ];
    } on FormatException {
      return [];
    }
  }
}
