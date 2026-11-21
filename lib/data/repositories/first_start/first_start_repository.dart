import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';

/// Remembers on which servers the first-start questions were answered or
/// skipped (#287), so they show once after the first sign-in to each.
class FirstStartRepository extends ChangeNotifier {
  /// Creates the repository.
  FirstStartRepository({required this._store});

  /// The key of the stored list of servers.
  static const doneKey = 'firstStart.done';

  final KeyValueStore _store;
  final Logger _log = Logger('FirstStartRepository');
  final Set<String> _done = {};

  /// Whether the first start on [server] is behind the person.
  bool isDone(ServerAddress server) => _done.contains(server.toString());

  /// Reads the stored list; call once at start, after the session.
  ///
  /// [signedInOn] is the server of a restored session. Before this list
  /// existed, people already signed in had set the app up by hand, so on
  /// the first start with it their server counts as done.
  Future<void> restore({ServerAddress? signedInOn}) async {
    try {
      final stored = await _store.read(doneKey);
      if (stored == null) {
        if (signedInOn != null) await markDone(signedInOn);
        return;
      }
      _done.clear();
      if (jsonDecode(stored) case final List<Object?> servers) {
        _done.addAll(servers.whereType<String>());
      }
      notifyListeners();
    } on Exception catch (e) {
      // A broken entry must not trap the person in the questions.
      _log.warning('Could not read the first-start state.', e);
      if (signedInOn != null) _done.add(signedInOn.toString());
    }
  }

  /// Stores that the first start on [server] is finished.
  Future<void> markDone(ServerAddress server) async {
    if (!_done.add(server.toString())) return;
    notifyListeners();
    try {
      await _store.write(doneKey, jsonEncode(_done.toList()));
    } on Exception catch (e) {
      _log.warning('Could not store the first-start state.', e);
    }
  }
}
