import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/focus_timer.dart';

/// Runs the focus timer (#191). On Android the phone runs it, so a phase
/// ends on time with the app closed; elsewhere it runs in the app.
abstract interface class FocusTimerService {
  /// The running or paused phase, or `null`.
  Future<FocusTimerState?> state();

  /// Starts [phase] of [length], replacing a running one.
  Future<void> start(FocusPhase phase, Duration length);

  /// Pauses the running phase.
  Future<void> pause();

  /// Resumes the paused phase.
  Future<void> resume();

  /// Stops the phase without recording it.
  Future<void> stop();

  /// The focus phases finished since the last call, oldest first.
  Future<List<FinishedFocus>> takeFinished();
}

/// A [FocusTimerService] in the app: the state lives in memory and a phase
/// ends when it is asked for after its end. Used in tests and where the
/// native timer is missing.
class InAppFocusTimer implements FocusTimerService {
  /// Creates the timer with [now] as its clock.
  InAppFocusTimer({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  FocusTimerState? _state;
  final List<FinishedFocus> _finished = [];

  @override
  Future<FocusTimerState?> state() async {
    final s = _state;
    if (s != null && !s.paused && !s.endsAt!.isAfter(_now())) {
      _state = null;
      if (s.phase == FocusPhase.focus) {
        _finished.add(
          FinishedFocus(minutes: s.length.inMinutes, endedAt: s.endsAt!),
        );
      }
    }
    return _state;
  }

  @override
  Future<void> start(FocusPhase phase, Duration length) async => _state =
      FocusTimerState(phase: phase, length: length, endsAt: _now().add(length));

  @override
  Future<void> pause() async {
    final s = await state();
    if (s == null || s.paused) return;
    _state = FocusTimerState(
      phase: s.phase,
      length: s.length,
      remaining: s.left(_now()),
    );
  }

  @override
  Future<void> resume() async {
    final s = _state;
    final left = s?.remaining;
    if (s == null || left == null) return;
    _state = FocusTimerState(
      phase: s.phase,
      length: s.length,
      endsAt: _now().add(left),
    );
  }

  @override
  Future<void> stop() async => _state = null;

  @override
  Future<List<FinishedFocus>> takeFinished() async {
    await state();
    final out = List.of(_finished);
    _finished.clear();
    return out;
  }
}

/// A [FocusTimerService] over the channel `app.waylight/focus`; without
/// the native side it falls back to [InAppFocusTimer].
class MethodChannelFocusTimer implements FocusTimerService {
  /// Creates the adapter.
  MethodChannelFocusTimer({
    this._channel = const MethodChannel('app.waylight/focus'),
  });

  final MethodChannel _channel;
  InAppFocusTimer? _fallback;

  Future<T> _call<T>(
    String method,
    Map<String, Object?>? args,
    Future<T> Function(InAppFocusTimer t) fallback,
    T Function(Object? value) parse,
  ) async {
    final f = _fallback;
    if (f != null) return fallback(f);
    try {
      return parse(await _channel.invokeMethod<Object?>(method, args));
    } on MissingPluginException {
      return fallback(_fallback = InAppFocusTimer());
    }
  }

  @override
  Future<FocusTimerState?> state() =>
      _call('state', null, (t) => t.state(), (v) => _parseState(v as String?));

  @override
  Future<void> start(FocusPhase phase, Duration length) => _call(
    'start',
    {'phase': phase.name, 'lengthMs': length.inMilliseconds},
    (t) => t.start(phase, length),
    (_) {},
  );

  @override
  Future<void> pause() => _call('pause', null, (t) => t.pause(), (_) {});

  @override
  Future<void> resume() => _call('resume', null, (t) => t.resume(), (_) {});

  @override
  Future<void> stop() => _call('stop', null, (t) => t.stop(), (_) {});

  @override
  Future<List<FinishedFocus>> takeFinished() => _call(
    'takeFinished',
    null,
    (t) => t.takeFinished(),
    (v) => _parseFinished(v as String?),
  );

  static FocusTimerState? _parseState(String? raw) {
    if (raw == null) return null;
    try {
      if (jsonDecode(raw)
          case {'phase': final String phase, 'lengthMs': final int length} &&
              final Map<String, Object?> o) {
        return FocusTimerState(
          phase: phase == 'rest' ? FocusPhase.rest : FocusPhase.focus,
          length: Duration(milliseconds: length),
          endsAt: switch (o['endsAt']) {
            final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
            _ => null,
          },
          remaining: switch (o['remainingMs']) {
            final int ms => Duration(milliseconds: ms),
            _ => null,
          },
        );
      }
    } on FormatException {
      // A broken state counts as no timer.
    }
    return null;
  }

  static List<FinishedFocus> _parseFinished(String? raw) {
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List<Object?>)
          if (e case {'minutes': final int m, 'endedAt': final int at})
            FinishedFocus(
              minutes: m,
              endedAt: DateTime.fromMillisecondsSinceEpoch(at),
            ),
      ];
    } on FormatException {
      return const [];
    }
  }
}
