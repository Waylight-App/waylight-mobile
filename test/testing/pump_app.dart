import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';

/// Helpers to show single screens in widget tests.
extension PumpApp on WidgetTester {
  /// Shows [screen] with the app's theme and the texts of [locale].
  Future<void> pumpScreen(
    Widget screen, {
    Locale locale = const Locale('en'),
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    );
    await pump();
  }
}

/// The English texts, to find widgets by what the user reads.
final AppLocalizations l10nEn = lookupAppLocalizations(const Locale('en'));
