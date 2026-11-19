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
      notes.add(
        Note(id: id, title: title, body: body, pinned: item['pinned'] == true),
      );
    } else {
      return null;
    }
  }
  return notes;
}
