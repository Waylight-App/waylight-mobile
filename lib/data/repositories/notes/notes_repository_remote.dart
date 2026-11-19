import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/services/api/notes_api.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [NotesRepository] that asks the server every time; keeping data for
/// offline use follows in #23.
class NotesRepositoryRemote implements NotesRepository {
  /// Creates the repository.
  const NotesRepositoryRemote({required this._api});

  final NotesApi _api;

  @override
  Future<Result<List<Note>>> notes(
    ServerAddress server, {
    bool pinnedOnly = false,
  }) => _api.notes(server, pinnedOnly: pinnedOnly);
}
