import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// What needs the signed-in account's attention (#229): broken connections
/// and widgets that are not set up yet, as the server lists them.
///
/// It keeps the last list, so the dashboard's badge and the attention
/// screen show the same entries and the badge follows a refresh on the
/// screen.
abstract interface class AttentionRepository implements Listenable {
  /// The entries of the last successful refresh, failures first.
  List<AttentionItem> get items;

  /// Reads the list again from [server].
  Future<Result<List<AttentionItem>>> refresh(ServerAddress server);

  /// Forgets the list, e.g. on sign-out.
  Future<void> clear();
}

/// An [AttentionRepository] on `GET /api/attention`.
class AttentionRepositoryRemote extends ChangeNotifier
    implements AttentionRepository {
  /// Creates the repository.
  AttentionRepositoryRemote({required this._api});

  final ModuleApi _api;
  List<AttentionItem> _items = const [];

  @override
  List<AttentionItem> get items => _items;

  @override
  Future<Result<List<AttentionItem>>> refresh(ServerAddress server) async {
    final result = await _api.read(server, '/api/attention', parseAttention);
    if (result case Ok(:final value)) {
      _items = List.unmodifiable(value);
      notifyListeners();
    }
    return result;
  }

  @override
  Future<void> clear() async {
    if (_items.isEmpty) return;
    _items = const [];
    notifyListeners();
  }
}

/// Maps `GET /api/attention`; `null` for an answer of another shape.
/// Entries without an id are left out rather than failing the whole list.
List<AttentionItem>? parseAttention(Object? json) {
  if (json case {'items': final List<Object?> items}) {
    return [for (final item in items) ?_item(item)];
  }
  return null;
}

AttentionItem? _item(Object? json) {
  if (json case {'id': final String id} && final Map<String, Object?> o
      when id.isNotEmpty) {
    String text(String key) => switch (o[key]) {
      final String s => s,
      _ => '',
    };
    final integration = text('integration');
    return AttentionItem(
      id: id,
      kind: AttentionKind.parse(o['kind']),
      integration: integration,
      widgetId: text('widgetId'),
      tabId: text('tabId'),
      title: switch (text('title')) {
        '' => integration,
        final title => title,
      },
      message: switch (o['reason']) {
        {'message': final String message} => message,
        _ => '',
      },
      action: AttentionAction.parse(o['action']),
      field: text('field'),
      since: DateTime.tryParse(text('since')),
    );
  }
  return null;
}
