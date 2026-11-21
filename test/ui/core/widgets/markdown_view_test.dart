import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/widgets/markdown_view.dart';

import '../../../testing/fakes/fake_link_opener.dart';
import '../../../testing/pump_app.dart';

/// The Markdown renderer (ADR 0013).
void main() {
  Future<FakeLinkOpener> pump(WidgetTester tester, String source) async {
    final opener = FakeLinkOpener();
    await tester.pumpScreen(
      LinkOpenerScope(opener: opener, child: MarkdownView(source)),
    );
    return opener;
  }

  testWidgets('shows headings, lists, emphasis and code', (tester) async {
    await pump(
      tester,
      '# Title\n\nSome **bold** text.\n\n1. one\n2. two\n\n- a\n- b\n\n```\ncode\n```',
    );
    expect(find.text('Title'), findsOneWidget);
    expect(find.textContaining('bold', findRichText: true), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(2));
    expect(find.text('code'), findsOneWidget);
  });

  testWidgets('opens http links in the browser, ignores others', (
    tester,
  ) async {
    final opener = await pump(
      tester,
      '[ok](https://example.org) and [bad](javascript:alert(1))',
    );
    expect(
      find.byType(InkWell),
      findsOneWidget,
      reason: 'only the http link is tappable',
    );
    await tester.tap(find.byType(InkWell));
    expect(opener.opened.map((u) => u.toString()), ['https://example.org']);
  });

  testWidgets('never loads images and shows HTML as text', (tester) async {
    await pump(tester, '![a cat](https://evil.example/cat.png)\n\n<b>raw</b>');
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('[a cat]', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('<b>raw</b>', findRichText: true),
      findsOneWidget,
    );
  });
}
