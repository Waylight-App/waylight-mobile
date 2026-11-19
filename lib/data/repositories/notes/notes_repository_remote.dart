import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/services/api/notes_api.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [NotesRepository] on `/api/notes`.
class NotesRepositoryRemote implements NotesRepository {
  /// Creates the repository.
  const NotesRepositoryRemote({required this._api});

  final NotesApi _api;

  @override
  Future<Result<List<Note>>> notes(
    ServerAddress server, {
    bool pinnedOnly = false,
  }) => _api.notes(server, pinnedOnly: pinnedOnly);

  @override
  Future<Result<Note>> note(ServerAddress server, String id) =>
      _api.note(server, id);

  @override
  Future<Result<Note>> create(ServerAddress server, NoteDraft draft) =>
      _api.create(server, draft);

  @override
  Future<Result<Note>> update(
    ServerAddress server,
    Note note,
    NoteDraft draft,
  ) => _api.update(server, note.id, draft, version: note.version);

  @override
  Future<Result<void>> delete(ServerAddress server, String id) =>
      _api.delete(server, id);
}
