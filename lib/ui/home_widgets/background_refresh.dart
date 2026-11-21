import 'dart:ui';

import 'package:waylight_mobile/data/repositories/device_controls/device_controls_repository.dart';
import 'package:waylight_mobile/data/repositories/home_widgets/home_widgets_repository.dart';
import 'package:waylight_mobile/data/repositories/preferences/preferences_repository.dart';
import 'package:waylight_mobile/data/repositories/quick_tiles/quick_tiles_repository.dart';
import 'package:waylight_mobile/data/repositories/reminders/reminder_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/domain/models/device_control.dart';
import 'package:waylight_mobile/domain/models/quick_tile.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';
import 'package:waylight_mobile/ui/core/reminder_texts.dart';
import 'package:waylight_mobile/ui/home_widgets/device_control_texts.dart';
import 'package:waylight_mobile/ui/home_widgets/home_widget_texts.dart';
import 'package:waylight_mobile/ui/home_widgets/quick_tile_texts.dart';

/// The background refresh of the home screen widgets (#48): restores the
/// server and the session, refreshes the cards in the chosen language and
/// clears them when signed out or the session has expired. It always
/// reports the end, so the native job can finish.
Future<void> refreshHomeWidgetsInBackground({
  required ServerRepository server,
  required SessionRepository session,
  required PreferencesRepository preferences,
  required HomeWidgetsRepository homeWidgets,
  ReminderRepository? reminders,
  QuickTilesRepository? quickTiles,
  required Locale systemLocale,
}) async {
  try {
    await server.restore();
    final current = server.current;
    await session.restore(current);
    await preferences.restore();
    if (current == null || !session.signedIn) {
      await homeWidgets.clear();
      await quickTiles?.clear();
      return;
    }
    final l10n = lookupAppLocalizations(
      _locale(preferences.appearance.language, systemLocale),
    );
    await homeWidgets.refresh(
      current,
      format: HomeWidgetTexts(l10n),
      force: true,
    );
    // Reminders follow the same data, so changes made elsewhere reach the
    // phone's schedule while the app stays closed (#190).
    if (reminders != null) {
      await reminders.restore();
      await reminders.reschedule(current, ReminderTexts(l10n), force: true);
    }
    // The Quick Settings tiles show a state that others may have changed
    // in the meantime (#192).
    await quickTiles?.refresh(current, format: QuickTileTexts(l10n));
    if (session.expired) {
      await homeWidgets.clear();
      await quickTiles?.clear();
    }
  } finally {
    await homeWidgets.finishBackground();
  }
}

/// The action of a Quick Settings tile (#192), run in a headless engine
/// the tile starts while the app may be closed: restores the server and the
/// session and runs the action through the same repositories as the app.
/// [tile] is the name of a [QuickTileKind]. Signed out, it clears the tiles, which then lead into the app. It always
/// reports the end, so the tile can stop the engine.
Future<void> runQuickTileInBackground({
  required ServerRepository server,
  required SessionRepository session,
  required PreferencesRepository preferences,
  required QuickTilesRepository quickTiles,
  required String? tile,
  required Locale systemLocale,
}) async {
  try {
    await server.restore();
    final current = server.current;
    await session.restore(current);
    await preferences.restore();
    if (current == null || !session.signedIn) {
      await quickTiles.clear();
      return;
    }
    final kind = QuickTileKind.parse(tile);
    if (kind == null) return;
    final l10n = lookupAppLocalizations(
      _locale(preferences.appearance.language, systemLocale),
    );
    await quickTiles.run(current, kind, format: QuickTileTexts(l10n));
    if (session.expired) await quickTiles.clear();
  } finally {
    await quickTiles.finish();
  }
}

/// A run of Android's device controls (#194) in a headless engine the
/// controls start while the app may be closed: `refresh` reads every state,
/// `act` with an entity id switches or presses it first. Signed out, the
/// controls show as unavailable and lead into the app. It always reports
/// the end, so the native side can stop the engine.
Future<void> runDeviceControlsInBackground({
  required ServerRepository server,
  required SessionRepository session,
  required PreferencesRepository preferences,
  required DeviceControlsRepository deviceControls,
  required List<String> args,
  required Locale systemLocale,
}) async {
  try {
    await server.restore();
    final current = server.current;
    await session.restore(current);
    await preferences.restore();
    final format = DeviceControlTexts(
      lookupAppLocalizations(
        _locale(preferences.appearance.language, systemLocale),
      ),
    );
    if (current == null || !session.signedIn || session.expired) {
      await deviceControls.unavailable(
        DeviceControlsProblem.signedOut,
        format: format,
      );
      return;
    }
    switch (args) {
      case ['act', final id]:
        await deviceControls.act(current, id, format: format);
      default:
        await deviceControls.refresh(current, format: format);
    }
    if (session.expired) {
      await deviceControls.unavailable(
        DeviceControlsProblem.signedOut,
        format: format,
      );
    }
  } finally {
    await deviceControls.finish();
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
