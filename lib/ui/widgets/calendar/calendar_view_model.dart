import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/calendar/calendar_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the calendar screen (#100): the agenda of the next weeks
/// and the calendars new events can go to.
class CalendarViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  CalendarViewModel({
    required this._serverRepository,
    required this._calendarRepository,
  }) {
    load = Command0(_load)..execute().ignore();
    create = Command1(_create);
  }

  /// How many days the agenda covers.
  static const days = 28;

  final ServerRepository _serverRepository;
  final CalendarRepository _calendarRepository;

  List<CalendarEvent> _events = const [];
  List<WritableCalendar> _writable = const [];

  /// Loads agenda and calendars; run again to reload.
  late final Command0<void> load;

  /// Writes a new event and reloads the agenda.
  late final Command1<void, NewEvent> create;

  /// The events, soonest first.
  List<CalendarEvent> get events => _events;

  /// The calendars new events can be written to; empty means read-only.
  List<WritableCalendar> get writable => _writable;

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final agenda = await _calendarRepository.agenda(server, days);
    switch (agenda) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        _events = [...value]..sort((a, b) => a.start.compareTo(b.start));
    }
    // Without writable calendars the screen only reads; a failure here must
    // not hide the agenda.
    _writable = switch (await _calendarRepository.writable(server)) {
      Ok(:final value) => value,
      Error() => const [],
    };
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _create(NewEvent event) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _calendarRepository.create(server, event);
    if (result is Ok<void>) await load.execute();
    return result;
  }

  @override
  void dispose() {
    load.dispose();
    create.dispose();
    super.dispose();
  }
}
