/// Why an entry is on the attention list (`GET /api/attention`, #229).
enum AttentionKind {
  /// A connection that was set up stopped working.
  connection,

  /// A widget or integration is not set up yet.
  setup;

  /// Reads the server's value; anything unknown counts as a setup.
  static AttentionKind parse(Object? value) =>
      value == 'connection' ? connection : setup;
}

/// The one thing a client offers to resolve an attention entry.
enum AttentionAction {
  /// The sign-in at the service expired.
  signIn,

  /// The service did not answer; check again.
  check,

  /// The service refused the stored credential; edit it.
  fix,

  /// The widget misses a setting of its own, such as a stop.
  choose,

  /// The integration is not set up yet.
  connect;

  /// Reads the server's value; anything unknown asks for a check.
  static AttentionAction parse(Object? value) =>
      values.where((a) => a.name == value).firstOrNull ?? check;
}

/// One entry of the attention list.
final class AttentionItem {
  /// Creates the entry.
  const AttentionItem({
    required this.id,
    required this.kind,
    required this.integration,
    required this.title,
    required this.message,
    required this.action,
    this.widgetId = '',
    this.tabId = '',
    this.field = '',
    this.since,
  });

  /// Stable while the entry exists: `widget:<id>` or `module:<name>`.
  final String id;

  /// Whether something broke or was never set up.
  final AttentionKind kind;

  /// The module the entry belongs to, such as `immich`.
  final String integration;

  /// The widget the entry belongs to; empty for a module's connection.
  final String widgetId;

  /// The tab of that widget; empty for a module's connection.
  final String tabId;

  /// The server's name for the entry, currently the module name.
  final String title;

  /// The cause in plain words, as the server words it.
  final String message;

  /// What resolves the entry.
  final AttentionAction action;

  /// For [AttentionAction.choose]: the widget setting that is missing,
  /// such as `stopId`.
  final String field;

  /// When the server first saw the problem.
  final DateTime? since;
}
