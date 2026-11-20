import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widgets/sized_grid.dart';

import '../../testing/pump_app.dart';

void main() {
  Future<void> pumpGrid(
    WidgetTester tester,
    List<({String id, WidgetSize size})> items,
  ) => tester.pumpScreen(
    SizedBox(
      width: 400,
      child: SizedGrid(
        items: items,
        columns: 4,
        tileBuilder: (context, place, size) =>
            SizedBox.fromSize(size: size, child: Text(place.id)),
      ),
    ),
  );

  testWidgets('places tiles on square cells', (tester) async {
    await pumpGrid(tester, [
      (id: 'a', size: WidgetSize.small),
      (id: 'b', size: WidgetSize.small),
      (id: 'c', size: WidgetSize.medium),
    ]);

    final a = tester.getRect(find.byKey(const ValueKey('grid.a')));
    final b = tester.getRect(find.byKey(const ValueKey('grid.b')));
    final c = tester.getRect(find.byKey(const ValueKey('grid.c')));
    expect(a.width, a.height, reason: 'small is square');
    expect(b.top, a.top);
    expect(b.left, greaterThan(a.right));
    expect(c.top, greaterThan(a.bottom));
    expect(c.width, closeTo(400, 0.01));
    expect(c.height, a.height);
  });

  testWidgets('takes no height without items', (tester) async {
    await pumpGrid(tester, []);
    expect(tester.getSize(find.byType(SizedGrid)).height, 0);
  });

  testWidgets('uses four columns on phones and eight on tablets', (
    tester,
  ) async {
    late int phone;
    late int tablet;
    await tester.pumpScreen(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 800)),
        child: Builder(
          builder: (context) {
            phone = SizedGrid.columnsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpScreen(
      MediaQuery(
        data: const MediaQueryData(size: Size(900, 800)),
        child: Builder(
          builder: (context) {
            tablet = SizedGrid.columnsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect((phone, tablet), (4, 8));
  });
}
