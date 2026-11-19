import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/weather.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Official warnings, pollen and UV below the forecast (#154), as the
/// widget's settings ask for them. Failures leave the section out: the
/// forecast stays the main content.
class WeatherExtras extends StatefulWidget {
  /// Creates the section from the widget configuration.
  const WeatherExtras({required this.config, super.key});

  /// The weather widget's configuration.
  final Map<String, Object?> config;

  @override
  State<WeatherExtras> createState() => _WeatherExtrasState();
}

class _WeatherExtrasState extends State<WeatherExtras> {
  Future<(List<WeatherWarning>, WeatherHealth?)>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<(List<WeatherWarning>, WeatherHealth?)> _fetch() async {
    final server = context.read<ServerRepository>().current;
    final data = context.read<WidgetDataRepository>();
    if (server == null) return (const <WeatherWarning>[], null);
    final c = widget.config;
    final (lat, lon) = (c['lat'], c['lon']);
    final warnings = c['warnings'] != false && lat is num && lon is num
        ? switch (await data.read(
            server,
            warningsQuery.withQuery({'lat': '$lat', 'lon': '$lon'}),
          )) {
            Ok(:final value) => value,
            Error() => const <WeatherWarning>[],
          }
        : const <WeatherWarning>[];
    final region = c['pollenRegion'];
    final city = c['uvCity'];
    final types = [
      if (c['pollenTypes'] case final List<Object?> t)
        for (final x in t)
          if (x is String) x,
    ];
    final wantsHealth =
        (region is int && region > 0) || (city is String && city.isNotEmpty);
    final health = wantsHealth
        ? switch (await data.read(
            server,
            healthQuery.withQuery({
              if (region is int && region > 0) 'region': '$region',
              if (city is String && city.isNotEmpty) 'city': city,
              if (types.isNotEmpty) 'types': types.join(','),
            }),
          )) {
            Ok(:final value) => value,
            Error() => null,
          }
        : null;
    return (warnings, health);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _load,
    builder: (context, snapshot) {
      final (warnings, health) =
          snapshot.data ?? (const <WeatherWarning>[], null);
      final l10n = context.l10n;
      final time = DateFormat.Hm(
        Localizations.localeOf(context).toLanguageTag(),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.only(top: Dimens.gapSmall),
              child: InfoRow(
                leading: StatusDot(
                  tone: w.severity == 'minor' ? Tone.warning : Tone.critical,
                  label: l10n.weatherWarning,
                ),
                title: w.headline,
                subtitle: w.expires == null
                    ? null
                    : l10n.weatherWarningUntil(time.format(w.expires!)),
              ),
            ),
          if (health?.uvToday case final uv?)
            InfoRow(title: l10n.weatherUv, trailing: '$uv'),
          for (final (type, burden)
              in health?.pollen ?? const <(String, String)>[])
            InfoRow(title: type, trailing: burden),
        ],
      );
    },
  );
}
