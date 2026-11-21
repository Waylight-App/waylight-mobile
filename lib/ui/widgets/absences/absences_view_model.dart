import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/absences/absences_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/absence.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the absences widget (#201): who is away today and later
/// this week, and the viewer's own entries.
class AbsencesViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  AbsencesViewModel({
    required this._serverRepository,
    required this._absencesRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    load = Command0(_load)..execute().ignore();
    _loadRole().ignore();
  }

  final ServerRepository _serverRepository;
  final AbsencesRepository _absencesRepository;
  final DateTime Function() _now;

  List<Absence> _all = const [];
  bool _off = false;
  bool _canEnter = false;

  /// Loads today and the rest of the week; run again to reload.
  late final Command0<void> load;

  /// Whether absences are switched off or not licensed (HTTP 404).
  bool get off => _off;

  /// Whether the viewer may enter absences; guests and kiosk displays only
  /// read. The server still refuses with an expired licence key.
  bool get canEnter => _canEnter;

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Away today.
  List<Absence> get today => [
    for (final a in _all)
      if (a.covers(_today)) a,
  ];

  /// Away later this week, from tomorrow to Sunday.
  List<Absence> get laterThisWeek => [
    for (final a in _all)
      if (a.from.isAfter(_today)) a,
  ];

  /// The last day of this week (Sunday).
  DateTime get weekEnd =>
      _today.add(Duration(days: DateTime.sunday - _today.weekday));

  Future<void> _loadRole() async {
    if (await _serverRepository.status() case Ok(:final value)) {
      _canEnter = value.role != 'guest' && value.role != 'kiosk';
      notifyListeners();
    }
  }

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    switch (await _absencesRepository.list(server, from: _today, to: weekEnd)) {
      case Ok(:final value):
        _all = value;
        _off = false;
        notifyListeners();
        return const Result.ok(null);
      case Error(error: ApiException(failure: ApiFailure.notFound)):
        _all = const [];
        _off = true;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Enters an absence, or changes [existing]; the error is returned so the
  /// form can show it at its field.
  Future<Result<void>> save(AbsenceInput input, {Absence? existing}) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = existing == null
        ? await _absencesRepository.create(server, input)
        : await _absencesRepository.update(server, existing.id, input);
    if (result case Ok()) await load.execute();
    return result;
  }

  /// Deletes [absence].
  Future<Result<void>> delete(Absence absence) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _absencesRepository.delete(server, absence.id);
    if (result case Ok()) await load.execute();
    return result;
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
