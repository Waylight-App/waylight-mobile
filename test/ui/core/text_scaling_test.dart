import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/ui/core/text_scaling.dart';

void main() {
  test('multiplies what the system scales', () {
    const system = TextScaler.linear(1.5);
    final scaler = StepTextScaler(system, 1.3);
    expect(scaler.scale(10), closeTo(19.5, 1e-9));
    expect(StepTextScaler(system, 1).scale(10), 15);
  });

  test('keeps a non-linear system scaling', () {
    // 14 grows by 10 %, other sizes by 40 %.
    final system = _Stepped();
    final scaler = StepTextScaler(system, 1.15);
    expect(scaler.scale(14), closeTo(14 * 1.1 * 1.15, 1e-9));
    expect(scaler.scale(20), closeTo(20 * 1.4 * 1.15, 1e-9));
  });

  test('compares by value', () {
    expect(
      StepTextScaler(TextScaler.noScaling, 1.15),
      StepTextScaler(TextScaler.noScaling, 1.15),
    );
    expect(
      StepTextScaler(TextScaler.noScaling, 1.15),
      isNot(StepTextScaler(TextScaler.noScaling, 1.3)),
    );
  });
}

class _Stepped extends TextScaler {
  @override
  double scale(double fontSize) => fontSize * (fontSize <= 14 ? 1.1 : 1.4);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1.1;
}
