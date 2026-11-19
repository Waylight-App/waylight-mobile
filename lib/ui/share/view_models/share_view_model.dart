import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/actions/drop_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/data/repositories/bookmarks/bookmarks_repository.dart';
import 'package:waylight_mobile/data/repositories/notes/notes_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Where shared content can go, each backed by a server module.
enum ShareTarget {
  /// A to-do with the text as title.
  todo('todos'),

  /// A note with the first line as title.
  note('notes'),

  /// The link saved to read later.
  readLater('readlater'),

  /// The link as a bookmark.
  bookmark('bookmarks'),

  /// The text in the drop zone, for another device.
  drop('drop');

  const ShareTarget(this.module);

  /// The server module that has to be switched on.
  final String module;

  /// Whether the target needs a link in the shared text.
  bool get needsLink => this == readLater || this == bookmark;
}

/// The state of the screen for content shared from other apps (#21).
class ShareViewModel extends ChangeNotifier {
  /// Creates the view model for [text] and loads the enabled modules.
  ShareViewModel({
    required this.text,
    required this._serverRepository,
    required this._data,
    required this._todos,
    required this._notes,
    required this._readLater,
    required this._bookmarks,
    required this._drop,
  }) : link = firstLink(text) {
    load = Command0(_load)..execute().ignore();
    save = Command1(_save);
  }

  /// The shared text.
  final String text;

  /// The first web address in [text], if any.
  final Uri? link;

  final ServerRepository _serverRepository;
  final WidgetDataRepository _data;
  final TodosRepository _todos;
  final NotesRepository _notes;
  final ReadLaterRepository _readLater;
  final BookmarksRepository _bookmarks;
  final DropRepository _drop;

  Set<String> _modules = const {};

  /// Loads which modules are switched on.
  late final Command0<void> load;

  /// Saves the shared content to a target.
  late final Command1<void, ShareTarget> save;

  /// The targets this server offers for the shared content.
  List<ShareTarget> get targets => [
    for (final t in ShareTarget.values)
      if (_modules.contains(t.module) && (!t.needsLink || link != null)) t,
  ];

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    switch (await _data.read(server, modulesQuery)) {
      case Ok(:final value):
        _modules = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<Result<void>> _save(ShareTarget target) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final lines = text.trim().split('\n');
    final title = lines.first.trim();
    final result = switch (target) {
      ShareTarget.todo => await _todos.create(server, title: title),
      ShareTarget.note => await _notes.create(
        server,
        NoteDraft(title: title, body: lines.skip(1).join('\n').trim()),
      ),
      ShareTarget.readLater => await _readLater.save(server, link!),
      ShareTarget.bookmark => await _bookmarks.create(
        server,
        BookmarkDraft(
          title: title == link.toString() ? link!.host : title,
          url: link!,
        ),
      ),
      ShareTarget.drop => await _drop.sendText(server, text.trim()),
    };
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  void dispose() {
    load.dispose();
    save.dispose();
    super.dispose();
  }
}

/// The first http(s) address in [text], if any.
Uri? firstLink(String text) {
  final match = RegExp(r'https?://[^\s<>"]+').firstMatch(text);
  return match == null ? null : Uri.tryParse(match[0]!);
}
