import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';

/// The root widget: theme, languages and the [router].
class WaylightApp extends StatelessWidget {
  /// Creates the app around [router].
  const WaylightApp({
    required this.router,
    this.appearance = const Appearance(),
    super.key,
  });

  /// The router that decides which screen is shown.
  final GoRouter router;

  /// Theme and language chosen in the settings (#14).
  final Appearance appearance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (appearance.theme) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
      },
      locale: switch (appearance.language) {
        AppLanguage.system => null,
        AppLanguage.en => const Locale('en'),
        AppLanguage.de => const Locale('de'),
      },
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
