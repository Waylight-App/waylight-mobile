import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/ui/core/window_size.dart';

void main() {
  test('classes widths like Material 3', () {
    expect(WindowSize.ofWidth(390), WindowSize.compact);
    expect(WindowSize.ofWidth(600), WindowSize.medium);
    expect(WindowSize.ofWidth(839), WindowSize.medium);
    expect(WindowSize.ofWidth(1280), WindowSize.expanded);
    expect(WindowSize.values.map((w) => w.columns), [1, 2, 3]);
  });
}
