import 'package:waylight_mobile/domain/models/compact_derived.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';

/// [text] in the app's language: compact states the app derives (#242)
/// carry keys of its own catalogue; the server's texts are shown as sent.
String compactTextOf(AppLocalizations l10n, CompactText text) {
  String p(String name) => text.params[name] ?? '';
  return switch (text.key) {
    DerivedCompactKey.weather => l10n.compactWeather(p('temp'), p('feels')),
    DerivedCompactKey.weatherToday => l10n.compactWeatherToday(
      p('min'),
      p('max'),
      p('rain'),
    ),
    DerivedCompactKey.departure => l10n.compactDeparture(
      p('line'),
      p('headsign'),
      p('minutes'),
    ),
    DerivedCompactKey.departureCancelled => l10n.compactDepartureCancelled(
      p('line'),
      p('headsign'),
    ),
    DerivedCompactKey.departureDelay => l10n.compactDepartureDelay(p('delay')),
    DerivedCompactKey.noDepartures => l10n.compactNoDepartures,
    DerivedCompactKey.wasteToday => l10n.compactWasteToday(p('label')),
    DerivedCompactKey.wasteTomorrow => l10n.compactWasteTomorrow(p('label')),
    DerivedCompactKey.wasteInDays => l10n.compactWasteInDays(
      p('label'),
      p('days'),
    ),
    DerivedCompactKey.noCollections => l10n.compactNoCollections,
    _ => text.text,
  };
}
