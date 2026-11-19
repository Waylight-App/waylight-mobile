import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/transit/transit_repository.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The settings of a departures widget, as the web interface stores them.
final class TransitConfig {
  /// Creates the settings.
  const TransitConfig({this.stopId = '', this.stopName = '', this.count = 6});

  /// Reads the widget configuration; unknown values fall back to defaults.
  factory TransitConfig.fromJson(Map<String, Object?> json) => TransitConfig(
    stopId: switch (json['stopId']) {
      final String s => s,
      _ => '',
    },
    stopName: switch (json['stopName']) {
      final String s => s.trim(),
      _ => '',
    },
    count: switch (json['count']) {
      final int c => c.clamp(1, 20),
      _ => 6,
    },
  );

  /// The stop; empty until it is chosen in the web interface.
  final String stopId;

  /// The name of the stop, e.g. "Oldenburg Hbf".
  final String stopName;

  /// How many departures are shown.
  final int count;
}

/// The widget has no stop yet; it is chosen in the web interface.
final class NoStopException implements Exception {
  /// Creates the exception.
  const NoStopException();
}

/// The state of a departures widget (#49).
class TransitViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  TransitViewModel({
    required this.config,
    required this._serverRepository,
    required this._transitRepository,
    this._now = DateTime.now,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  /// The settings of the widget.
  final TransitConfig config;
  final ServerRepository _serverRepository;
  final TransitRepository _transitRepository;
  final DateTime Function() _now;

  /// Loads the departures; run again to reload.
  late final Command0<List<Departure>> load;

  /// Whole minutes until [departure] leaves, never below 0.
  int minutesUntil(Departure departure) {
    final minutes = departure.expected.difference(_now()).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  Future<Result<List<Departure>>> _load() async {
    if (config.stopId.isEmpty) return const Result.error(NoStopException());
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _transitRepository.departures(
      server,
      stop: config.stopId,
      count: config.count,
    );
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
