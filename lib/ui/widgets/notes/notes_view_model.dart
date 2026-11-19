import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Which notes a notes widget shows, as the web interface stores it.
enum NotesScope {
  /// Only pinned notes; the default.
  pinned,

  /// All notes, pinned first.
  all;

  /// Reads the widget configuration.
  static NotesScope fromJson(Map<String, Object?> json) =>
      json['scope'] == 'all' ? all : pinned;
}

/// The state of a notes widget (#65).
class NotesViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  NotesViewModel({
    required this.scope,
    required this._serverRepository,
    required this._notesRepository,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  /// Which notes are shown.
  final NotesScope scope;
  final ServerRepository _serverRepository;
  final NotesRepository _notesRepository;

  /// Loads the notes; run again to reload.
  late final Command0<List<Note>> load;

  Future<Result<List<Note>>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _notesRepository.notes(
      server,
      pinnedOnly: scope == NotesScope.pinned,
    );
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
