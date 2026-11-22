import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/household.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The family and household modules of the server: chores, meals, gifts,
/// board, contracts, documents and meters (Waylight-App/waylight#675,
/// #676). The widgets read the lists and run a few quick actions.
abstract interface class HouseholdRepository {
  /// The visible chores, the ones due soonest first.
  Future<Result<List<Chore>>> chores(ServerAddress server);

  /// Marks [id] done; the server moves it on and passes it to the next
  /// assignee.
  Future<Result<void>> markChoreDone(ServerAddress server, String id);

  /// The dishes of the next [days] days, from [from].
  Future<Result<List<Meal>>> meals(
    ServerAddress server, {
    required DateTime from,
    int days = 7,
  });

  /// The signed-in account's gift ideas.
  Future<Result<List<GiftIdea>>> gifts(ServerAddress server);

  /// Marks [idea] as bought or open again.
  Future<Result<void>> setGiftBought(
    ServerAddress server,
    GiftIdea idea, {
    required bool bought,
  });

  /// The notes on the family board that have not expired.
  Future<Result<List<BoardNote>>> board(ServerAddress server);

  /// The visible contracts, the next deadline first.
  Future<Result<List<Contract>>> contracts(ServerAddress server);

  /// The visible documents, running warranties first.
  Future<Result<List<DocumentRecord>>> documents(ServerAddress server);

  /// The visible meters with their newest reading.
  Future<Result<List<Meter>>> meters(ServerAddress server);

  /// Adds a reading of [value] on [day] to the meter [id].
  Future<Result<void>> addReading(
    ServerAddress server,
    String id, {
    required DateTime day,
    required double value,
  });
}

/// A [HouseholdRepository] on the module endpoints.
class HouseholdRepositoryRemote implements HouseholdRepository {
  /// Creates the repository.
  const HouseholdRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<Chore>>> chores(ServerAddress server) =>
      _api.read(server, '/api/chores', parseChores);

  @override
  Future<Result<void>> markChoreDone(ServerAddress server, String id) async =>
      _void(await _api.post(server, '/api/chores/$id/done'));

  @override
  Future<Result<List<Meal>>> meals(
    ServerAddress server, {
    required DateTime from,
    int days = 7,
  }) => _api.read(
    server,
    '/api/meals',
    parseMeals,
    query: {'from': _day(from), 'days': '$days'},
  );

  @override
  Future<Result<List<GiftIdea>>> gifts(ServerAddress server) =>
      _api.read(server, '/api/gifts', parseGifts);

  @override
  Future<Result<void>> setGiftBought(
    ServerAddress server,
    GiftIdea idea, {
    required bool bought,
  }) async => _void(
    await _api.put(
      server,
      '/api/gifts/${idea.id}',
      // The server replaces the whole idea.
      body: {
        'person': idea.person,
        'title': idea.title,
        'link': idea.link,
        'note': idea.note,
        'bought': bought,
      },
    ),
  );

  @override
  Future<Result<List<BoardNote>>> board(ServerAddress server) =>
      _api.read(server, '/api/board', parseBoard);

  @override
  Future<Result<List<Contract>>> contracts(ServerAddress server) =>
      _api.read(server, '/api/contracts', parseContracts);

  @override
  Future<Result<List<DocumentRecord>>> documents(ServerAddress server) =>
      _api.read(server, '/api/documents', parseDocuments);

  @override
  Future<Result<List<Meter>>> meters(ServerAddress server) =>
      _api.read(server, '/api/meters', parseMeters);

  @override
  Future<Result<void>> addReading(
    ServerAddress server,
    String id, {
    required DateTime day,
    required double value,
  }) async => _void(
    await _api.post(
      server,
      '/api/meters/$id/readings',
      body: {'day': _day(day), 'value': value},
    ),
  );

  static Result<void> _void(Result<Object?> result) => switch (result) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String _text(Object? v) => v is String ? v : '';

/// Maps a list of records; records without an id are left out rather than
/// failing the whole list.
List<T>? _records<T>(Object? json, T? Function(Map<String, Object?>) record) =>
    json is List<Object?>
    ? [
        for (final e in json)
          if (e case {'id': final String id} when id.isNotEmpty)
            ?record(e as Map<String, Object?>),
      ]
    : null;

/// Maps `GET /api/chores`.
List<Chore>? parseChores(Object? json) => _records(
  json,
  (o) => Chore(
    id: _text(o['id']),
    title: _text(o['title']),
    assignee: _text(o['assignee']),
    due: asDay(o['due']),
    dueNow: o['dueNow'] == true,
    overdue: o['overdue'] == true,
  ),
);

/// Maps `GET /api/meals`.
List<Meal>? parseMeals(Object? json) => _records(
  json,
  (o) => Meal(
    id: _text(o['id']),
    dish: _text(o['dish']),
    date: asDay(o['date']),
    meal: _text(o['meal']),
  ),
);

/// Maps `GET /api/gifts`.
List<GiftIdea>? parseGifts(Object? json) => _records(
  json,
  (o) => GiftIdea(
    id: _text(o['id']),
    person: _text(o['person']),
    title: _text(o['title']),
    link: _text(o['link']),
    note: _text(o['note']),
    bought: o['bought'] == true,
  ),
);

/// Maps `GET /api/board`.
List<BoardNote>? parseBoard(Object? json) => _records(
  json,
  (o) => BoardNote(
    id: _text(o['id']),
    text: _text(o['text']),
    pinned: o['pinned'] == true,
    expiresOn: asDay(o['expiresOn']),
  ),
);

/// Maps `GET /api/contracts`.
List<Contract>? parseContracts(Object? json) => _records(
  json,
  (o) => Contract(
    id: _text(o['id']),
    name: _text(o['name']),
    provider: _text(o['provider']),
    monthlyCents: switch (o['monthlyCents']) {
      final num n => n.toInt(),
      _ => 0,
    },
    deadline: asDay(o['deadline']),
    open: o['open'] != false,
    soon: o['soon'] == true,
  ),
);

/// Maps `GET /api/documents`.
List<DocumentRecord>? parseDocuments(Object? json) => _records(
  json,
  (o) => DocumentRecord(
    id: _text(o['id']),
    title: _text(o['title']),
    status: WarrantyStatus.parse(o['status']),
    warrantyEnd: asDay(o['warrantyEnd']),
    hasFile: _text(o['fileName']).isNotEmpty,
  ),
);

/// Maps `GET /api/meters`.
List<Meter>? parseMeters(Object? json) => _records(
  json,
  (o) => Meter(
    id: _text(o['id']),
    name: _text(o['name']),
    kind: _text(o['kind']),
    unit: _text(o['unit']),
    lastDay: switch (o['last']) {
      {'day': final Object? d} => asDay(d),
      _ => null,
    },
    lastValue: switch (o['last']) {
      {'value': final num v} => v.toDouble(),
      _ => null,
    },
  ),
);
