import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';

void main() {
  const grid = [
    (id: 'b', x: 6, y: 0),
    (id: 'a', x: 0, y: 0),
    (id: 'c', x: 0, y: 4),
  ];

  test('follows the phone layout and leaves hidden widgets out', () {
    expect(
      phoneOrder(grid, const [
        (id: 'c', hidden: false),
        (id: 'a', hidden: true),
        (id: 'b', hidden: false),
        (id: 'gone', hidden: false),
      ]),
      ['c', 'b'],
    );
  });

  test('reads the grid row by row without a phone layout', () {
    expect(phoneOrder(grid, const []), ['a', 'b', 'c']);
  });

  test('opens the default tab, else the first', () {
    const tabs = [
      DashboardTab(id: 't1', name: 'One', widgets: []),
      DashboardTab(id: 't2', name: 'Two', widgets: []),
    ];
    expect(const Dashboard(tabs: tabs, defaultTabId: 't2').initialIndex, 1);
    expect(const Dashboard(tabs: tabs, defaultTabId: 'x').initialIndex, 0);
    expect(const Dashboard(tabs: tabs).initialIndex, 0);
  });
}
