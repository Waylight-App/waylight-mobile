/// A note of the signed-in account (`GET /api/notes`).
final class Note {
  /// Creates the note.
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.pinned = false,
  });

  /// The server's id.
  final String id;

  /// The title of the note.
  final String title;

  /// The text in Markdown.
  final String body;

  /// Whether the note is pinned to the top.
  final bool pinned;

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
