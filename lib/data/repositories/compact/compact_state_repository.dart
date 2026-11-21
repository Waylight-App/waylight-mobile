import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The short state of a widget (#228), as the server computes it
/// (`GET /api/<module>/compact`), so small tiles, home screen widgets,
/// Quick Settings tiles and the watch say the same.
abstract interface class CompactStateRepository {
  /// Whether the server offers a compact state for widgets of [kind].
  bool supports(String kind);

  /// The compact state of the widget kind [kind]; the offline copy when
  /// the server cannot be reached.
  Future<Result<CompactState>> state(ServerAddress server, String kind);
}

/// A [CompactStateRepository] on the modules' `/compact` endpoints.
class CompactStateRepositoryRemote implements CompactStateRepository {
  /// Creates the repository.
  const CompactStateRepositoryRemote({required this._api});

  final ModuleApi _api;

  /// The widget kinds whose module answers `GET /api/<kind>/compact`
  /// (Waylight-App/waylight#604). Kind and module share their name.
  static const kinds = {'todos', 'habits', 'focus'};

  @override
  bool supports(String kind) => kinds.contains(kind);

  @override
  Future<Result<CompactState>> state(ServerAddress server, String kind) {
    // The kind becomes part of the path, so only known names go there.
    assert(supports(kind), 'No compact state for $kind.');
    return _api.read(server, '/api/$kind/compact', parseCompactState);
  }
}

/// Maps `GET /api/<module>/compact`; `null` for an answer of another
/// shape.
CompactState? parseCompactState(Object? json) {
  if (json case {'title': final Object? t} && final Map<String, Object?> o) {
    final title = _text(t);
    if (title == null) return null;
    return CompactState(
      title: title,
      detail: _text(o['detail']),
      level: CompactLevel.parse(o['level']),
      count: switch (o['count']) {
        final int n => n,
        _ => null,
      },
      updatedAt: switch (o['updatedAt']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      },
      action: _action(o['action']),
    );
  }
  return null;
}

CompactText? _text(Object? json) => switch (json) {
  {'text': final String text} && final Map<String, Object?> o => CompactText(
    text: text,
    key: switch (o['key']) {
      final String k => k,
      _ => '',
    },
    params: switch (o['params']) {
      final Map<String, Object?> p => {
        for (final MapEntry(:key, :value) in p.entries)
          if (value is String) key: value,
      },
      _ => const {},
    },
  ),
  _ => null,
};

Map<String, Object?>? _body(Object? json) => switch (json) {
  final Map<String, Object?> body => body,
  _ => null,
};

CompactAction? _action(Object? json) {
  if (json
      case {
            'id': final String id,
            'method': final String method,
            'path': final String path,
          } &&
          final Map<String, Object?> o
      when path.startsWith('/api/')) {
    return CompactAction(
      id: id,
      label: _text(o['label']) ?? CompactText(text: id),
      method: method.toUpperCase(),
      path: path,
      body: _body(o['body']),
      choices: switch (o['choices']) {
        final List<Object?> choices => [
          for (final c in choices)
            if (c case {'id': final String cid} && final Map<String, Object?> m)
              CompactChoice(
                id: cid,
                label: _text(m['label']) ?? CompactText(text: cid),
                body: _body(m['body']),
                selected: m['selected'] == true,
              ),
        ],
        _ => const [],
      },
    );
  }
  return null;
}
