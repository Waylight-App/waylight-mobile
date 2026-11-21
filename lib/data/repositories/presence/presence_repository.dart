import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Today's presence on the server (#200, `ee` feature `presence`).
abstract interface class PresenceRepository {
  /// The board of [group], or everyone when it is empty.
  Future<Result<PresenceBoard>> board(ServerAddress server, {String group});

  /// Sets the signed-in account's status; [PresenceStatus.none] clears it.
  Future<Result<void>> setMine(
    ServerAddress server,
    PresenceStatus status, {
    DateTime? returnOn,
  });
}

/// A [PresenceRepository] on `/api/presence`.
class PresenceRepositoryRemote implements PresenceRepository {
  /// Creates the repository.
  const PresenceRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<PresenceBoard>> board(
    ServerAddress server, {
    String group = '',
  }) => _api.read(
    server,
    '/api/presence',
    parsePresence,
    query: {if (group.isNotEmpty) 'group': group},
  );

  @override
  Future<Result<void>> setMine(
    ServerAddress server,
    PresenceStatus status, {
    DateTime? returnOn,
  }) async => switch (await _api.put(
    server,
    '/api/presence/me',
    body: {
      'status': status.wire,
      'returnOn': status == PresenceStatus.away && returnOn != null
          ? _day(returnOn)
          : '',
    },
  )) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Maps `GET /api/presence`; `null` for an answer of another shape.
PresenceBoard? parsePresence(Object? json) {
  if (json
      case {
            'people': final List<Object?> people,
            'counts': final Map<String, Object?> counts,
          } &&
          final Map<String, Object?> o) {
    final parsed = <PresencePerson>[];
    for (final p in people) {
      final person = _person(p);
      if (person == null) return null;
      parsed.add(person);
    }
    int count(String key) => switch (counts[key]) {
      final int n => n,
      _ => 0,
    };
    return PresenceBoard(
      people: parsed,
      counts: {
        PresenceStatus.office: count('office'),
        PresenceStatus.home: count('home'),
        PresenceStatus.away: count('away'),
        PresenceStatus.none: count('none'),
      },
      mine: _person(o['mine']),
    );
  }
  return null;
}

PresencePerson? _person(Object? json) => switch (json) {
  {'accountId': final String id, 'name': final String name} &&
      final Map<String, Object?> p =>
    PresencePerson(
      accountId: id,
      name: name,
      status: PresenceStatus.parse(p['status']),
      fromAbsence: p['source'] == 'absence',
      returnOn: switch (p['returnOn']) {
        final String d when d.isNotEmpty => DateTime.tryParse(d),
        _ => null,
      },
    ),
  _ => null,
};
