/// How much a compact state needs the viewer's attention (#228). Only
/// [attention] and [problem] are coloured, so a dashboard of healthy
/// widgets stays quiet.
enum CompactLevel {
  /// Nothing to judge: no data yet, or neither good nor bad.
  none,

  /// Everything the widget watches is fine.
  ok,

  /// Asks for a look soon, e.g. an overdue to-do.
  attention,

  /// Something is broken, e.g. a service is down.
  problem;

  /// Reads the server's value; anything unknown counts as [none].
  static CompactLevel parse(Object? value) =>
      values.where((l) => l.name == value).firstOrNull ?? none;
}

/// A text of a compact state: the server's English [text] with its
/// parameters filled in, and the [key] of its translation.
final class CompactText {
  /// Creates the text.
  const CompactText({
    required this.text,
    this.key = '',
    this.params = const {},
  });

  /// The key of the translation in the server's message catalogue.
  final String key;

  /// The English text with the parameters filled in.
  final String text;

  /// The values of the placeholders.
  final Map<String, String> params;
}

/// One chip of a [CompactAction], e.g. *office* of the presence status.
final class CompactChoice {
  /// Creates the choice.
  const CompactChoice({
    required this.id,
    required this.label,
    this.body,
    this.selected = false,
  });

  /// The name of the choice.
  final String id;

  /// What the chip says.
  final CompactText label;

  /// The JSON body sent for this choice; `null` sends none.
  final Map<String, Object?>? body;

  /// Whether this is the current choice.
  final bool selected;
}

/// The one primary action of a compact view: the request to send, or one
/// request per [choices] entry.
final class CompactAction {
  /// Creates the action.
  const CompactAction({
    required this.id,
    required this.label,
    required this.method,
    required this.path,
    this.body,
    this.choices = const [],
  });

  /// The name of the action, such as `focus.start`.
  final String id;

  /// What the button says.
  final CompactText label;

  /// The HTTP method, such as `POST`.
  final String method;

  /// The API path the request goes to, such as `/api/focus/start`.
  final String path;

  /// The JSON body; `null` sends none.
  final Map<String, Object?>? body;

  /// Chips instead of one button; empty for a plain action.
  final List<CompactChoice> choices;
}

/// The short state of a widget (#228): what small tiles, home screen
/// widgets, Quick Settings tiles and the watch show instead of the full
/// data, the same on every client.
final class CompactState {
  /// Creates the state.
  const CompactState({
    required this.title,
    this.detail,
    this.level = CompactLevel.none,
    this.count,
    this.updatedAt,
    this.action,
  });

  /// The one line every client shows, e.g. "3 open · 1 overdue".
  final CompactText title;

  /// An optional second line.
  final CompactText? detail;

  /// How much it needs attention.
  final CompactLevel level;

  /// An optional number for badges.
  final int? count;

  /// When the underlying data was last read or changed.
  final DateTime? updatedAt;

  /// The one primary action, if the widget offers one.
  final CompactAction? action;
}

/// A module's compact state endpoint as `GET /api/modules` lists it
/// (Waylight-App/waylight#634).
final class CompactEndpoint {
  /// Creates the endpoint.
  const CompactEndpoint({
    required this.module,
    required this.path,
    this.params = const [],
  });

  /// The module, such as `backupmonitor`.
  final String module;

  /// The API path, such as `/api/backupmonitor/compact`.
  final String path;

  /// The query parameters the state depends on, such as `entity` for one
  /// smart home device; a widget without them has no compact state.
  final List<String> params;
}
