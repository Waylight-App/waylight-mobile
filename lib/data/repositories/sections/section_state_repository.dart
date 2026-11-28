import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:waylight_mobile/data/services/storage/key_value_store.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Remembers which sections of a tab are collapsed (#334), per server, tab
/// and section. The state stays on the device: another phone may want
/// other sections open.
class SectionStateRepository extends ChangeNotifier {
  /// Creates the repository.
  SectionStateRepository({required this._store});

  /// The key of the stored list of collapsed sections.
  static const storageKey = 'dashboard.collapsedSections';

  final KeyValueStore _store;
  final Logger _log = Logger('SectionStateRepository');

  /// Collapsed sections as `server|tab|section`.
  final Set<String> _collapsed = {};

  static String _key(ServerAddress server, String tabId, String section) =>
      '$server|$tabId|$section';

  /// Whether [section] of tab [tabId] on [server] is collapsed.
  bool isCollapsed(ServerAddress server, String tabId, String section) =>
      _collapsed.contains(_key(server, tabId, section));

  /// Reads the stored state; call once at start. Without one, or with one
  /// that cannot be read, every section is open.
  Future<Result<void>> restore() async {
    try {
      final stored = await _store.read(storageKey);
      _collapsed.clear();
      if (stored != null) {
        if (jsonDecode(stored) case final List<Object?> keys) {
          _collapsed.addAll(keys.whereType<String>());
        }
      }
      notifyListeners();
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Ignoring collapsed sections that cannot be read.', e);
      return Result.error(e);
    }
  }

  /// Collapses or expands [section] of tab [tabId] on [server] and stores
  /// it.
  Future<Result<void>> setCollapsed(
    ServerAddress server,
    String tabId,
    String section, {
    required bool collapsed,
  }) async {
    final key = _key(server, tabId, section);
    final changed = collapsed ? _collapsed.add(key) : _collapsed.remove(key);
    if (!changed) return const Result.ok(null);
    notifyListeners();
    try {
      await _store.write(storageKey, jsonEncode(_collapsed.toList()));
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Could not store the collapsed sections.', e);
      return Result.error(e);
    }
  }
}
