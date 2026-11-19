import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/utils/html_text.dart';

void main() {
  test('turns block elements into paragraphs and drops other tags', () {
    expect(
      htmlParagraphs(
        '<h2>Title</h2><p>One <b>bold</b> line.</p><p>Two&nbsp;&amp; three</p>',
      ),
      ['Title', 'One bold line.', 'Two & three'],
    );
  });

  test('keeps list items and decodes numeric entities', () {
    expect(htmlParagraphs('<ul><li>A</li><li>B &#8211; C</li></ul>'), [
      '• A',
      '• B – C',
    ]);
    expect(htmlParagraphs('&amp;lt;'), ['&lt;']);
    expect(htmlParagraphs(''), isEmpty);
  });
}
