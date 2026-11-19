import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The notes endpoints of the server (`api/modules/notes.yaml`).
class NotesApi {
  /// Creates the service on top of an [ApiClient].
  const NotesApi(this._client);

  final ApiClient _client;

  /// Reads `GET /api/notes`, pinned first; [pinnedOnly] leaves out the
  /// others.
  Future<Result<List<Note>>> notes(
    ServerAddress server, {
    bool pinnedOnly = false,
  }) async {
    final uri = server
        .resolve('/api/notes')
        .replace(queryParameters: {if (pinnedOnly) 'pinned': 'true'});
    final result = await _client.getJson(uri);
    switch (result) {
      case Ok(:final value):
        final notes = parseNotes(value);
        return notes == null
            ? const Result.error(ApiException(ApiFailure.server))
            : Result.ok(notes);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Reads one note (`GET /api/notes/{id}`).
  Future<Result<Note>> note(ServerAddress server, String id) async =>
      _single(await _client.getJson(server.resolve(_path(id))));

  /// Creates a note (`POST /api/notes`).
  Future<Result<Note>> create(ServerAddress server, NoteDraft draft) async =>
      _single(
        await _client.postJson(
          server.resolve('/api/notes'),
          body: _body(draft),
        ),
      );

  /// Saves [draft] over the note [id] edited at [version]; a newer version
  /// on the server answers `ApiFailure.conflict`.
  Future<Result<Note>> update(
    ServerAddress server,
    String id,
    NoteDraft draft, {
    required int version,
  }) async => _single(
    await _client.putJson(
      server.resolve(_path(id)),
      body: {..._body(draft), 'version': version},
    ),
  );

  /// Deletes a note.
  Future<Result<void>> delete(ServerAddress server, String id) =>
      _client.delete(server.resolve(_path(id)));

  static String _path(String id) => '/api/notes/${Uri.encodeComponent(id)}';

  static Map<String, Object?> _body(NoteDraft d) => {
    'title': d.title,
    'body': d.body,
    'pinned': d.pinned,
  };

  static Result<Note> _single(Result<Object?> result) => switch (result) {
    Ok(:final value) => switch (parseNote(value)) {
      final note? => Result.ok(note),
      null => const Result.error(ApiException(ApiFailure.server)),
    },
    Error(:final error) => Result.error(error),
  };
}

Note _note(Map<Object?, Object?> item, String id, String title, String body) =>
    Note(
      id: id,
      title: title,
      body: body,
      pinned: item['pinned'] == true,
      version: (item['version'] as num?)?.toInt() ?? 0,
    );

/// Maps one note; `null` if it does not match.
Note? parseNote(Object? json) {
  if (json case {
    'id': final String id,
    'title': final String title,
    'body': final String body,
  }) {
    return _note(json, id, title, body);
  }
  return null;
}

/// Maps the JSON of `GET /api/notes`; `null` if it does not match.
List<Note>? parseNotes(Object? json) {
  if (json is! List<Object?>) return null;
  final notes = <Note>[];
  for (final item in json) {
    if (item case {
      'id': final String id,
      'title': final String title,
      'body': final String body,
    }) {
      notes.add(_note(item, id, title, body));
    } else {
      return null;
    }
  }
  return notes;
}
