import 'dart:ui';

import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';
import 'package:waylight_mobile/ui/home_widgets/home_widget_texts.dart';

/// The background refresh of the home screen widgets (#48): restores the
/// server and the session, refreshes the cards in the chosen language and
/// clears them when signed out or the session has expired. It always
/// reports the end, so the native job can finish.
Future<void> refreshHomeWidgetsInBackground({
  required ServerRepository server,
  required SessionRepository session,
  required PreferencesRepository preferences,
  required HomeWidgetsRepository homeWidgets,
  required Locale systemLocale,
}) async {
  try {
    await server.restore();
    final current = server.current;
    await session.restore(current);
    await preferences.restore();
    if (current == null || !session.signedIn) {
      await homeWidgets.clear();
      return;
    }
    await homeWidgets.refresh(
      current,
      format: HomeWidgetTexts(
        lookupAppLocalizations(
          _locale(preferences.appearance.language, systemLocale),
        ),
      ),
      force: true,
    );
    if (session.expired) await homeWidgets.clear();
  } finally {
    await homeWidgets.finishBackground();
  }
}

Locale _locale(AppLanguage language, Locale system) => switch (language) {
  AppLanguage.en => const Locale('en'),
  AppLanguage.de => const Locale('de'),
  AppLanguage.system =>
    AppLocalizations.supportedLocales.any(
          (l) => l.languageCode == system.languageCode,
        )
        ? Locale(system.languageCode)
        : const Locale('en'),
};
