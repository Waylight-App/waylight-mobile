import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The calendars of the server: the agenda and new events (#100).
abstract interface class CalendarRepository {
  /// The events of the next [days] days.
  Future<Result<List<CalendarEvent>>> agenda(ServerAddress server, int days);

  /// The calendars new events can be written to.
  Future<Result<List<WritableCalendar>>> writable(ServerAddress server);

  /// Writes [event].
  Future<Result<void>> create(ServerAddress server, NewEvent event);
}

/// A [CalendarRepository] on `/api/calendar`.
class CalendarRepositoryRemote implements CalendarRepository {
  /// Creates the repository.
  const CalendarRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<CalendarEvent>>> agenda(ServerAddress server, int days) =>
      _api.read(
        server,
        '/api/calendar/events',
        parseCalendar,
        query: {'days': '$days'},
      );

  @override
  Future<Result<List<WritableCalendar>>> writable(ServerAddress server) =>
      _api.read(server, '/api/calendar/writable', parseWritable);

  @override
  Future<Result<void>> create(ServerAddress server, NewEvent event) async =>
      switch (await _api.post(
        server,
        '/api/calendar/events',
        body: newEventJson(event),
      )) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };
}

/// Maps `GET /api/calendar/writable`.
List<WritableCalendar>? parseWritable(Object? json) =>
    listOf<WritableCalendar>(json, (c) {
      if (c case {'id': final String id, 'name': final String name}) {
        return WritableCalendar(id: id, name: name);
      }
      return null;
    });

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The body of `POST /api/calendar/events`: RFC 3339 instants for timed
/// events, dates with an inclusive end for all-day events.
Map<String, Object?> newEventJson(NewEvent e) => {
  'calendarUrl': e.calendarId,
  'summary': e.summary,
  'location': e.location,
  'allDay': e.allDay,
  'start': e.allDay ? _day(e.start) : e.start.toUtc().toIso8601String(),
  'end': e.allDay ? _day(e.end) : e.end.toUtc().toIso8601String(),
};
