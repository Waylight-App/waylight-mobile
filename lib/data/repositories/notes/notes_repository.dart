import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The notes module of the server.
abstract interface class NotesRepository {
  /// The notes of the signed-in account on [server].
  Future<Result<List<Note>>> notes(
    ServerAddress server, {
    bool pinnedOnly = false,
  });

  /// One note, for editing.
  Future<Result<Note>> note(ServerAddress server, String id);

  /// Creates a note.
  Future<Result<Note>> create(ServerAddress server, NoteDraft draft);

  /// Saves [draft] over [note]; fails with `ApiFailure.conflict` when the
  /// note was changed elsewhere in the meantime.
  Future<Result<Note>> update(ServerAddress server, Note note, NoteDraft draft);

  /// Deletes a note.
  Future<Result<void>> delete(ServerAddress server, String id);
}
