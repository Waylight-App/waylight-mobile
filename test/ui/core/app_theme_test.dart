import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/ui/core/themes/app_theme.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';

void main() {
  test('the primary colour is the Waylight blue in light mode', () {
    expect(AppTheme.light.colorScheme.primary, AppTheme.seed);
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
