import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The settings of a clock widget, as the web interface stores them.
final class ClockConfig {
  /// Creates the settings.
  const ClockConfig({
    this.timeZone = '',
    this.showSeconds = false,
    this.hour12 = false,
  });

  /// Reads the widget configuration; unknown values fall back to defaults.
  factory ClockConfig.fromJson(Map<String, Object?> json) => ClockConfig(
    timeZone: switch (json['timeZone']) {
      final String zone => zone.trim(),
      _ => '',
    },
    showSeconds: json['showSeconds'] == true,
    hour12: json['hour12'] == true,
  );

  /// The IANA time zone, e.g. `Europe/Berlin`; empty for the phone's.
  final String timeZone;

  /// Whether the seconds are shown.
  final bool showSeconds;

  /// Whether a 12-hour clock with AM/PM is shown.
  final bool hour12;
}

/// The time and date of a clock widget (#62), updated every second.
class ClockViewModel extends ChangeNotifier {
  /// Creates the view model; the clock and [tick] can be replaced in tests.
  ClockViewModel({
    required this.config,
    required this.locale,
    this._now = DateTime.now,
    Duration tick = const Duration(seconds: 1),
  }) {
    _location = _resolve(config.timeZone);
    _timer = Timer.periodic(tick, (_) => notifyListeners());
  }

  /// The settings of the widget.
  final ClockConfig config;

  /// The language for the date, e.g. `de`.
  final String locale;

  final DateTime Function() _now;
  late final tz.Location? _location;
  late final Timer _timer;

  static bool _zonesLoaded = false;

  // The zone data is loaded once, when the first clock with a time zone
  // appears, instead of at every start of the app.
  static tz.Location? _resolve(String name) {
    if (name.isEmpty) return null;
    if (!_zonesLoaded) {
      tz_data.initializeTimeZones();
      _zonesLoaded = true;
    }
    try {
      return tz.getLocation(name);
    } on tz.LocationNotFoundException {
      return null;
    }
  }

  DateTime get _current {
    final location = _location;
    return location == null
        ? _now()
        : tz.TZDateTime.from(_now().toUtc(), location);
  }

  /// The time, e.g. `14:05` or `2:05:09 PM`.
  String get time {
    final pattern = switch ((config.hour12, config.showSeconds)) {
      (true, true) => 'h:mm:ss a',
      (true, false) => 'h:mm a',
      (false, true) => 'HH:mm:ss',
      (false, false) => 'HH:mm',
    };
    return DateFormat(pattern, locale).format(_current);
  }

  /// The date, e.g. `Thursday, 19 November 2026`.
  String get date => DateFormat.yMMMMEEEEd(locale).format(_current);

  /// The time zone shown below the date, or empty for the phone's.
  String get zone => _location == null ? '' : config.timeZone;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
