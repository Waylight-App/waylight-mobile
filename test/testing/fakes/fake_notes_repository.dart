import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
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

  /// The notes by id for [note], [update] and [delete].
  final Map<String, Note> byId = {};

  /// The changes asked for, as `create:<title>`, `update:<id>` or
  /// `delete:<id>`.
  final List<String> changes = [];

  /// The error changes fail with, if any.
  Exception? fail;

  @override
  Future<Result<Note>> note(ServerAddress server, String id) async =>
      switch (byId[id]) {
        final n? => Result.ok(n),
        null => const Result.error(ApiException(ApiFailure.notFound)),
      };

  @override
  Future<Result<Note>> create(ServerAddress server, NoteDraft draft) async {
    changes.add('create:${draft.title}');
    if (fail case final e?) return Result.error(e);
    final n = Note(
      id: 'new',
      title: draft.title,
      body: draft.body,
      pinned: draft.pinned,
      version: 1,
    );
    byId[n.id] = n;
    return Result.ok(n);
  }

  @override
  Future<Result<Note>> update(
    ServerAddress server,
    Note note,
    NoteDraft draft,
  ) async {
    changes.add('update:${note.id}');
    if (fail case final e?) return Result.error(e);
    final n = Note(
      id: note.id,
      title: draft.title,
      body: draft.body,
      pinned: draft.pinned,
      version: note.version + 1,
    );
    byId[n.id] = n;
    return Result.ok(n);
  }

  @override
  Future<Result<void>> delete(ServerAddress server, String id) async {
    changes.add('delete:$id');
    if (fail case final e?) return Result.error(e);
    byId.remove(id);
    return const Result.ok(null);
  }
}
