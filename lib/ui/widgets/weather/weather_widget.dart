import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_view_model.dart';

/// The native view of the weather widget (#63).
class WeatherWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const WeatherWidget({required this.widget, super.key});

  /// The placement with the weather's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      WeatherWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final config = WeatherConfig.fromJson(widget.config);
    return ViewModelHost(
      create: (context) => WeatherViewModel(
        config: config,
        serverRepository: context.read(),
        weatherRepository: context.read(),
      ),
      builder: (context, viewModel) => WidgetFrame(
        title: widget.title.isNotEmpty
            ? widget.title
            : config.label.isNotEmpty
            ? config.label
            : widget.displayTitle,
        load: viewModel.load,
        errorText: (error) =>
            error is NoPlaceException ? context.l10n.weatherNoPlace : null,
        builder: (context, weather) => _WeatherContent(weather: weather),
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(iconOf(weather.condition), size: Dimens.iconLarge),
            const SizedBox(width: Dimens.gapCard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weatherDegrees(weather.temperature.round()),
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(labelOf(l10n, weather.condition)),
                  Text(
                    l10n.weatherFeelsLike(weather.apparentTemperature.round()),
                    style: muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (weather.days.isNotEmpty) ...[
          const SizedBox(height: Dimens.gapCard),
          for (final day in weather.days)
            Semantics(
              container: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: Dimens.gapTiny / 2,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: Dimens.labelColumn,
                      child: Text(DateFormat.E(locale).format(day.date)),
                    ),
                    Icon(
                      iconOf(day.condition),
                      size: Dimens.iconSmall,
                      semanticLabel: labelOf(l10n, day.condition),
                    ),
                    const SizedBox(width: Dimens.gapSmall),
                    Expanded(
                      child: Text(
                        l10n.weatherPrecipitation(day.precipitationProbability),
                        style: muted,
                      ),
                    ),
                    Text(l10n.weatherRange(day.min.round(), day.max.round())),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The icon for [condition].
@visibleForTesting
IconData iconOf(WeatherCondition condition) => switch (condition) {
  WeatherCondition.clearSky => Icons.wb_sunny_outlined,
  WeatherCondition.mainlyClear ||
  WeatherCondition.partlyCloudy => Icons.wb_cloudy_outlined,
  WeatherCondition.overcast => Icons.cloud_outlined,
  WeatherCondition.fog || WeatherCondition.rimeFog => Icons.foggy,
  WeatherCondition.lightDrizzle ||
  WeatherCondition.drizzle ||
  WeatherCondition.denseDrizzle ||
  WeatherCondition.lightRain ||
  WeatherCondition.rain ||
  WeatherCondition.heavyRain ||
  WeatherCondition.rainShowers => Icons.water_drop_outlined,
  WeatherCondition.freezingDrizzle ||
  WeatherCondition.freezingRain => Icons.ac_unit,
  WeatherCondition.lightSnow ||
  WeatherCondition.snow ||
  WeatherCondition.heavySnow ||
  WeatherCondition.snowGrains ||
  WeatherCondition.snowShowers => Icons.ac_unit,
  WeatherCondition.violentShowers ||
  WeatherCondition.thunderstorm ||
  WeatherCondition.thunderstormWithHail => Icons.thunderstorm_outlined,
  WeatherCondition.unknown => Icons.help_outline,
};

/// The words for [condition], as in the web interface.
@visibleForTesting
String labelOf(AppLocalizations l10n, WeatherCondition condition) =>
    switch (condition) {
      WeatherCondition.clearSky => l10n.weatherClearSky,
      WeatherCondition.mainlyClear => l10n.weatherMainlyClear,
      WeatherCondition.partlyCloudy => l10n.weatherPartlyCloudy,
      WeatherCondition.overcast => l10n.weatherOvercast,
      WeatherCondition.fog => l10n.weatherFog,
      WeatherCondition.rimeFog => l10n.weatherRimeFog,
      WeatherCondition.lightDrizzle => l10n.weatherLightDrizzle,
      WeatherCondition.drizzle => l10n.weatherDrizzle,
      WeatherCondition.denseDrizzle => l10n.weatherDenseDrizzle,
      WeatherCondition.freezingDrizzle => l10n.weatherFreezingDrizzle,
      WeatherCondition.lightRain => l10n.weatherLightRain,
      WeatherCondition.rain => l10n.weatherRain,
      WeatherCondition.heavyRain => l10n.weatherHeavyRain,
      WeatherCondition.freezingRain => l10n.weatherFreezingRain,
      WeatherCondition.lightSnow => l10n.weatherLightSnow,
      WeatherCondition.snow => l10n.weatherSnow,
      WeatherCondition.heavySnow => l10n.weatherHeavySnow,
      WeatherCondition.snowGrains => l10n.weatherSnowGrains,
      WeatherCondition.rainShowers => l10n.weatherRainShowers,
      WeatherCondition.violentShowers => l10n.weatherViolentShowers,
      WeatherCondition.snowShowers => l10n.weatherSnowShowers,
      WeatherCondition.thunderstorm => l10n.weatherThunderstorm,
      WeatherCondition.thunderstormWithHail => l10n.weatherThunderstormWithHail,
      WeatherCondition.unknown => l10n.weatherUnknown,
    };
