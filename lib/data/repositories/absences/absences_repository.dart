import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/absence.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Absences on the server (#201, `ee` feature `absences`).
abstract interface class AbsencesRepository {
  /// The absences touching the days [from] to [to].
  Future<Result<List<Absence>>> list(
    ServerAddress server, {
    required DateTime from,
    required DateTime to,
  });

  /// Enters an absence for the signed-in account.
  Future<Result<void>> create(ServerAddress server, AbsenceInput input);

  /// Changes the absence [id].
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    AbsenceInput input,
  );

  /// Deletes the absence [id].
  Future<Result<void>> delete(ServerAddress server, String id);
}

/// An [AbsencesRepository] on `/api/absences`.
class AbsencesRepositoryRemote implements AbsencesRepository {
  /// Creates the repository.
  const AbsencesRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<Absence>>> list(
    ServerAddress server, {
    required DateTime from,
    required DateTime to,
  }) => _api.read(
    server,
    '/api/absences',
    parseAbsences,
    query: {'from': absenceDay(from), 'to': absenceDay(to)},
  );

  @override
  Future<Result<void>> create(ServerAddress server, AbsenceInput input) async =>
      _void(await _api.post(server, '/api/absences', body: _body(input)));

  @override
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    AbsenceInput input,
  ) async => _void(
    await _api.put(
      server,
      '/api/absences/${Uri.encodeComponent(id)}',
      body: _body(input),
    ),
  );

  @override
  Future<Result<void>> delete(ServerAddress server, String id) =>
      _api.delete(server, '/api/absences/${Uri.encodeComponent(id)}');

  static Map<String, Object?> _body(AbsenceInput i) => {
    'from': absenceDay(i.from),
    'to': absenceDay(i.to),
    'kind': i.kind.name,
    'note': i.note.trim(),
    'private': i.private,
  };

  static Result<void> _void(Result<Object?> r) => switch (r) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };
}

/// A calendar day as the server writes it, e.g. "2026-11-21".
String absenceDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Maps `GET /api/absences`; `null` for an answer of another shape.
List<Absence>? parseAbsences(Object? json) {
  if (json is! List<Object?>) return null;
  final out = <Absence>[];
  for (final e in json) {
    if (e
        case {
              'id': final String id,
              'name': final String name,
              'from': final String from,
              'to': final String to,
            } &&
            final Map<String, Object?> a) {
      final start = DateTime.tryParse(from);
      final end = DateTime.tryParse(to);
      if (start == null || end == null) return null;
      out.add(
        Absence(
          id: id,
          accountId: switch (a['accountId']) {
            final String s => s,
            _ => '',
          },
          name: name,
          from: start,
          to: end,
          kind: AbsenceKind.parse(a['kind']),
          note: switch (a['note']) {
            final String s => s,
            _ => '',
          },
          private: a['private'] == true,
          editable: a['editable'] == true,
        ),
      );
    } else {
      return null;
    }
  }
  return out;
}
