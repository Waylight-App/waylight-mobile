import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [NotesRepository] without network for tests.
class FakeNotesRepository implements NotesRepository {
  /// What [notes] returns; an empty list by default.
  Result<List<Note>> result = const Result.ok([]);

  /// The arguments of every call.
  final List<bool> calls = [];

  @override
  Future<Result<List<Note>>> notes(
    ServerAddress server, {
    bool pinnedOnly = false,
  }) async {
    calls.add(pinnedOnly);
    return result;
  }
}
