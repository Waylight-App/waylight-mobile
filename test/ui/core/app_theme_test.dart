import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/app_theme.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';

void main() {
  test('the accent text of the Amber theme is primary', () {
    expect(AppTheme.light.colorScheme.primary, AppTheme.accentTextLight);
    expect(AppTheme.dark.colorScheme.primary, AppTheme.accentTextDark);
  });

  test('filled buttons are Amber with dark text in both modes', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final style = theme.filledButtonTheme.style!;
      expect(style.backgroundColor!.resolve({}), AppTheme.seed);
      expect(style.foregroundColor!.resolve({}), AppTheme.onSeed);
    }
  });

  test('accent colours meet WCAG AA contrast (4.5:1)', () {
    expect(_contrast(AppTheme.onSeed, AppTheme.seed), greaterThan(4.5));
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final colors = theme.colorScheme;
      expect(_contrast(colors.primary, colors.surface), greaterThan(4.5));
      expect(_contrast(colors.onPrimary, colors.primary), greaterThan(4.5));
    }
  });

  test('both themes carry their status colours', () {
    expect(AppTheme.light.extension<StatusColors>(), StatusColors.light);
    expect(AppTheme.dark.extension<StatusColors>(), StatusColors.dark);
  });

  test('buttons are at least one tap target high', () {
    final style = AppTheme.light.filledButtonTheme.style!;
    expect(style.minimumSize!.resolve({})!.height, Dimens.tapTarget);
  });

  test('status colours interpolate between the themes', () {
    final halfway = StatusColors.light.lerp(StatusColors.dark, 0.5);
    expect(halfway.warning, isNot(StatusColors.light.warning));
    expect(StatusColors.light.lerp(null, 0.5), StatusColors.light);
    expect(
      StatusColors.light.copyWith(success: StatusColors.dark.success).success,
      StatusColors.dark.success,
    );
  });
}

/// The WCAG contrast ratio of two colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}
