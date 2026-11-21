/// A notice for everyone on the instance (`GET /api/announcements`, #202).
final class Announcement {
  /// Creates the announcement.
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.pinned = false,
    this.authorName = '',
    this.expiresAt,
    this.read = false,
    this.editable = false,
  });

  /// The most characters of a title.
  static const maxTitle = 120;

  /// The most characters of a text.
  static const maxBody = 10000;

  /// The server's id.
  final String id;

  /// The title.
  final String title;

  /// The text in Markdown.
  final String body;

  /// When it was published.
  final DateTime createdAt;

  /// Whether it stays at the top.
  final bool pinned;

  /// Who wrote it.
  final String authorName;

  /// When it leaves the widget, if set.
  final DateTime? expiresAt;

  /// Whether the asking person has read it.
  final bool read;

  /// Whether the asking person may change or delete it.
  final bool editable;

  /// A copy marked as read.
  Announcement markedRead() => Announcement(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    pinned: pinned,
    authorName: authorName,
    expiresAt: expiresAt,
    read: true,
    editable: editable,
  );
}

/// What the form sends to publish or change an announcement.
final class AnnouncementInput {
  /// Creates the input.
  const AnnouncementInput({
    required this.title,
    required this.body,
    this.pinned = false,
    this.expiresAt,
    this.notify = false,
  });

  /// The title.
  final String title;

  /// The text in Markdown.
  final String body;

  /// Whether it stays at the top.
  final bool pinned;

  /// When it leaves the widget; `null` keeps it.
  final DateTime? expiresAt;

  /// Whether the server sends it once to the notification channels.
  final bool notify;
}
