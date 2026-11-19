import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/todos/todos_repository.dart';
import 'package:waylight_mobile/domain/models/todo.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The settings of a to-do widget, as the web interface stores them.
final class TodosConfig {
  /// Creates the settings.
  const TodosConfig({this.showDone = false, this.source = ''});

  /// Reads the widget configuration; unknown values fall back to defaults.
  factory TodosConfig.fromJson(Map<String, Object?> json) => TodosConfig(
    showDone: json['showDone'] == true,
    source: switch (json['source']) {
      // "local" and anything that is not an id mean the built-in list.
      final String s when s != 'local' && _id.hasMatch(s) => s,
      _ => '',
    },
  );

  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Whether ticked-off to-dos are shown too.
  final bool showDone;

  /// The connected external list; empty for the built-in one.
  final String source;
}

/// The state of a to-do widget (#64). Read-only; editing follows in #20.
class TodosViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  TodosViewModel({
    required this.config,
    required this._serverRepository,
    required this._todosRepository,
    this._now = DateTime.now,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  /// The settings of the widget.
  final TodosConfig config;
  final ServerRepository _serverRepository;
  final TodosRepository _todosRepository;
  final DateTime Function() _now;

  /// Loads the to-dos; run again to reload.
  late final Command0<List<Todo>> load;

  /// Today's date, to word due dates as "today" and "tomorrow".
  DateTime get today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<Result<List<Todo>>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _todosRepository.todos(
      server,
      openOnly: !config.showDone,
      source: config.source,
    );
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
