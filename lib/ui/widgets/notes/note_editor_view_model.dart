import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the note editor (#101): an existing note to change, or a
/// new one.
class NoteEditorViewModel extends ChangeNotifier {
  /// Creates the view model; an empty [noteId] starts a new note.
  NoteEditorViewModel({
    required this.noteId,
    required this._serverRepository,
    required this._notesRepository,
  }) {
    load = Command0(_load)..execute().ignore();
    save = Command1(_save);
    delete = Command0(_delete);
  }

  /// The note being edited; empty for a new note.
  final String noteId;
  final ServerRepository _serverRepository;
  final NotesRepository _notesRepository;

  Note? _note;

  /// Loads the note; a new note needs nothing.
  late final Command0<void> load;

  /// Saves the draft; fails with `ApiFailure.conflict` when the note was
  /// changed elsewhere since it was loaded.
  late final Command1<Note, NoteDraft> save;

  /// Deletes the note.
  late final Command0<void> delete;

  /// The loaded note, or `null` for a new one or while loading.
  Note? get note => _note;

  /// Whether this creates a note.
  bool get isNew => noteId.isEmpty && _note == null;

  Future<Result<void>> _load() async {
    if (noteId.isEmpty) return const Result.ok(null);
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    switch (await _notesRepository.note(server, noteId)) {
      case Ok(:final value):
        _note = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<Result<Note>> _save(NoteDraft draft) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final current = _note;
    final result = current == null
        ? await _notesRepository.create(server, draft)
        : await _notesRepository.update(server, current, draft);
    if (result case Ok(:final value)) {
      _note = value;
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> _delete() async {
    final server = _serverRepository.current;
    final current = _note;
    if (server == null || current == null) return const Result.ok(null);
    return _notesRepository.delete(server, current.id);
  }

  @override
  void dispose() {
    load.dispose();
    save.dispose();
    delete.dispose();
    super.dispose();
  }
}
