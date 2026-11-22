import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/app.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';

/// The accessibility options of the account applied to the app (#291).
void main() {
  Future<BuildContext> pumpApp(
    WidgetTester tester,
    Accessibility accessibility, {
    double systemScale = 1,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = systemScale;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      WaylightApp(
        accessibility: accessibility,
        router: GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => const Text('start'))],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.element(find.text('start'));
  }

  testWidgets('multiplies the system text size by the step', (tester) async {
    final context = await pumpApp(
      tester,
      const Accessibility(textSize: TextSize.larger),
      systemScale: 1.5,
    );
    expect(
      MediaQuery.textScalerOf(context).scale(10),
      closeTo(10 * 1.5 * 1.3, 1e-9),
    );
  });

  testWidgets('leaves the system text size alone by default', (tester) async {
    final context = await pumpApp(tester, const Accessibility());
    expect(MediaQuery.textScalerOf(context).scale(10), 10);
  });

  testWidgets('uses the high-contrast colours instead of Amber', (
    tester,
  ) async {
    final context = await pumpApp(
      tester,
      const Accessibility(highContrast: true),
    );
    expect(
      Theme.of(context).colorScheme.primary,
      AppTheme.highContrast(Brightness.light).colorScheme.primary,
    );
    expect(
      Theme.of(context).colorScheme.primary,
      isNot(AppTheme.accentTextLight),
    );
  });
}
