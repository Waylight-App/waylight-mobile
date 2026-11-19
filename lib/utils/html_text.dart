/// Turns the simple HTML of a reader copy into paragraphs of plain text:
/// block elements end a paragraph, other tags are dropped and the common
/// entities are decoded. Enough for the cleaned-up article the server
/// stores; not a general HTML parser.
List<String> htmlParagraphs(String html) {
  final blocks = html.replaceAll(
    RegExp(
      r'<\s*(br|/p|/h[1-6]|/li|/blockquote|/pre|/div)\s*/?>',
      caseSensitive: false,
    ),
    '\n\n',
  );
  final text = blocks
      .replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]*>'), '');
  return [
    for (final p in _decode(text).split(RegExp(r'\n\s*\n')))
      if (p.trim().isNotEmpty) p.replaceAll(RegExp(r'\s+'), ' ').trim(),
  ];
}

String _decode(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAllMapped(
      RegExp('&#(x?)([0-9a-fA-F]+);'),
      (m) =>
          String.fromCharCode(int.parse(m[2]!, radix: m[1]!.isEmpty ? 10 : 16)),
    )
    // &amp; last, so "&amp;lt;" stays "&lt;".
    .replaceAll('&amp;', '&');
