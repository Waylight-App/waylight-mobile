import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/ui/core/app_shortcuts.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/text_scaling.dart';
import 'package:waylight_mobile/ui/core/themes/app_theme.dart';

/// The root widget: theme, languages and the [router].
class WaylightApp extends StatelessWidget {
  /// Creates the app around [router].
  const WaylightApp({
    required this.router,
    this.appearance = const Appearance(),
    this.palette,
    this.wallpaperSeed,
    this.accessibility = const Accessibility(),
    this.onShortcut = _ignore,
    super.key,
  });

  static void _ignore(AppShortcut _) {}

  /// Opens the place of a shortcut on the launcher icon (#50).
  final void Function(AppShortcut shortcut) onShortcut;

  /// The router that decides which screen is shown.
  final GoRouter router;

  /// Theme and language chosen in the settings (#14).
  final Appearance appearance;

  /// The colours of the account's web theme, or `null` for Amber (#157).
  final ThemePalette? palette;

  /// The seed of the wallpaper colours when the person chose them (#198);
  /// it replaces [palette].
  final int? wallpaperSeed;

  /// The account's accessibility options (#291): high contrast replaces
  /// the colours of [palette] and [wallpaperSeed]; the text size multiplies
  /// the system's.
  final Accessibility accessibility;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: accessibility.highContrast
          ? AppTheme.highContrast(Brightness.light)
          : wallpaperSeed == null
          ? AppTheme.lightFor(palette)
          : AppTheme.wallpaper(Color(wallpaperSeed!), Brightness.light),
      darkTheme: accessibility.highContrast
          ? AppTheme.highContrast(Brightness.dark)
          : wallpaperSeed == null
          ? AppTheme.darkFor(palette)
          : AppTheme.wallpaper(Color(wallpaperSeed!), Brightness.dark),
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: StepTextScaler(
            MediaQuery.textScalerOf(context),
            accessibility.textSize.factor,
          ),
        ),
        child: AppShortcuts(
          onShortcut: onShortcut,
          child: child ?? const SizedBox(),
        ),
      ),
    );
  }
}
