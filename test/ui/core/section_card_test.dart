import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/widgets/section_card.dart';

import '../../testing/pump_app.dart';

void main() {
  testWidgets('shows title, trailing status and content', (tester) async {
    await tester.pumpScreen(
      const SectionCard(
        title: 'To-dos',
        trailing: '3 open',
        child: Text('Buy milk'),
      ),
    );

    expect(find.text('To-dos'), findsOneWidget);
    expect(find.text('3 open'), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);
  });

  testWidgets('announces the title as a header', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpScreen(
      const SectionCard(title: 'Notes', child: SizedBox()),
    );

    expect(
      tester.getSemantics(find.text('Notes')),
      matchesSemantics(label: 'Notes', isHeader: true),
    );
    semantics.dispose();
  });
}
