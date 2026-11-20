import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';

void main() {
  List<(String, int, int)> places(List<WidgetSize> sizes, {int columns = 4}) =>
      [
        for (final t in packGrid([
          for (final (i, size) in sizes.indexed) (id: '$i', size: size),
        ], columns: columns))
          (t.id, t.column, t.row),
      ];

  test('puts two small widgets side by side', () {
    expect(places([WidgetSize.small, WidgetSize.small]), [
      ('0', 0, 0),
      ('1', 2, 0),
    ]);
  });

  test('keeps the order row by row', () {
    expect(places([WidgetSize.medium, WidgetSize.small, WidgetSize.strip]), [
      ('0', 0, 0),
      ('1', 0, 2),
      ('2', 0, 4),
    ]);
  });

  test('fills a gap with a later widget that fits', () {
    // small | (gap) — medium does not fit next to it, the next small does.
    expect(places([WidgetSize.small, WidgetSize.medium, WidgetSize.small]), [
      ('0', 0, 0),
      ('1', 0, 2),
      ('2', 2, 0),
    ]);
  });

  test('gives every size its span', () {
    final tiles = packGrid([
      for (final size in WidgetSize.values) (id: size.name, size: size),
    ], columns: 4);
    expect(
      [for (final t in tiles) (t.id, t.columns, t.rows)],
      [('small', 2, 2), ('medium', 4, 2), ('large', 4, 4), ('strip', 4, 1)],
    );
  });

  test('uses the width of a tablet grid', () {
    expect(
      places([
        WidgetSize.medium,
        WidgetSize.medium,
        WidgetSize.small,
        WidgetSize.small,
        WidgetSize.small,
      ], columns: 8),
      [('0', 0, 0), ('1', 4, 0), ('2', 0, 2), ('3', 2, 2), ('4', 4, 2)],
    );
  });

  test('narrows widgets wider than the grid', () {
    final tile = packGrid([
      (id: 'a', size: WidgetSize.large),
    ], columns: 2).single;
    expect((tile.columns, tile.rows), (2, 4));
  });

  test('parses sizes and nothing else', () {
    expect(WidgetSize.parse('medium'), WidgetSize.medium);
    expect(WidgetSize.parse(''), isNull);
    expect(WidgetSize.parse('huge'), isNull);
    expect(WidgetSize.parse(null), isNull);
  });

  test('withSizes sets the sizes in the layout too', () {
    const clock = WidgetPlacement(id: 'a', kind: 'clock');
    const tab = DashboardTab(
      id: 't',
      name: 'Home',
      widgets: [clock],
      layout: [PhoneLayoutItem(widget: clock)],
    );

    final sized = tab.withSizes({'a': WidgetSize.small});

    expect(sized.sizes, {'a': WidgetSize.small});
    expect(sized.layout.single.size, WidgetSize.small);
  });
}
