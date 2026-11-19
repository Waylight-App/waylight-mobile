/// A note of the signed-in account (`GET /api/notes`).
final class Note {
  /// Creates the note.
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.pinned = false,
    this.version = 0,
  });

  /// The server's id.
  final String id;

  /// The title of the note.
  final String title;

  /// The text in Markdown.
  final String body;

  /// Whether the note is pinned to the top.
  final bool pinned;

  /// The server's version; a change sent with an older one is refused with
  /// a conflict, so edits made elsewhere are never overwritten.
  final int version;

  /// The first line of text after the title, without Markdown marks, for a
  /// one-line preview.
  String get preview {
    for (final raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      return line
          .replaceAllMapped(
            RegExp(r'\[([^\]]*)\]\([^)]*\)'),
            (m) => m.group(1)!,
          )
          .replaceAll(RegExp(r'[*_`>]+'), '')
          .replaceFirst(RegExp(r'^([-+]|\d+\.)\s+'), '')
          .trim();
    }
    return '';
  }
}

/// The fields of a note the user edits.
final class NoteDraft {
  /// Creates the draft.
  const NoteDraft({
    required this.title,
    required this.body,
    this.pinned = false,
  });

  /// The title.
  final String title;

  /// The text in Markdown.
  final String body;

  /// Whether it is pinned.
  final bool pinned;
}
