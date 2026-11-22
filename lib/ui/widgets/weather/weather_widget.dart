import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/data/repositories/places/places_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/domain/models/weather.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/choice_search_sheet.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_preview.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_example.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_extras.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The native view of the weather widget (#63).
class WeatherWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const WeatherWidget({required this.widget, super.key});

  /// The placement with the weather's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      WeatherWidget(widget: widget, key: ValueKey(widget.id));

  /// The gallery preview from example data (#251); the extras (warnings,
  /// pollen) need a place and stay out.
  static Widget preview(BuildContext context, String title, WidgetSize size) {
    final weather = exampleWeather(DateTime.now());
    return WidgetPreview(
      title: title,
      size: size,
      compact: (context) => _WeatherCompact(weather: weather, size: size),
      full: (context) => _WeatherContent(weather: weather),
    );
  }

  /// Lets the user search a place and stores it on the widget (#230).
  static Future<void> _choosePlace(
    BuildContext context,
    WeatherViewModel viewModel,
  ) async {
    final l10n = context.l10n;
    final place = await ChoiceSearchSheet.show<Place>(
      context,
      title: l10n.setUpPlaceTitle,
      search: viewModel.searchPlaces,
      label: (place) => place.name,
      detail: (place) =>
          [place.region, place.country].where((s) => s.isNotEmpty).join(', '),
      action: viewModel.canUseLocation
          ? ChoiceAction(
              label: l10n.setUpPlaceMyLocation,
              run: () => viewModel.useMyLocation(l10n.setUpPlaceMyLocationName),
              errorText: (error) => switch (error) {
                LocationDenied() => l10n.setUpPlaceLocationDenied,
                LocationUnavailable() => l10n.setUpPlaceLocationUnavailable,
                _ => l10n.errorMessage(error),
              },
            )
          : null,
    );
    if (place == null) return;
    await viewModel.choosePlace.execute(place);
    if (viewModel.choosePlace.result case Error(:final error)
        when context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => WeatherViewModel(
      config: WeatherConfig.fromJson(widget.config),
      serverRepository: context.read(),
      weatherRepository: context.read(),
      dashboardRepository: context.read<DashboardRepository?>(),
      placesRepository: context.read<PlacesRepository?>(),
      widgetId: widget.id,
      widgetConfig: widget.config,
    ),
    builder: (context, viewModel) => ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _frame(context, viewModel),
    ),
  );

  Widget _frame(BuildContext context, WeatherViewModel viewModel) {
    final config = viewModel.config;
    return WidgetFrame(
      title: widget.title.isNotEmpty
          ? widget.title
          : config.label.isNotEmpty
          ? config.label
          : widget.displayTitle,
      load: viewModel.load,
      interval: const Duration(minutes: 15),
      errorText: (error) =>
          error is NoPlaceException ? context.l10n.weatherNoPlace : null,
      setUp: (error) => error is NoPlaceException && viewModel.canChoosePlace
          ? (
              message: context.l10n.weatherNoPlace,
              onSetUp: () => _choosePlace(context, viewModel).ignore(),
            )
          : null,
      compact: (context, weather, size) =>
          _WeatherCompact(weather: weather, size: size),
      builder: (context, weather) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeatherContent(weather: weather),
          WeatherExtras(config: widget.config),
        ],
      ),
    );
  }
}

/// The weather in a small tile or a strip (#211): temperature, sky and the
/// range of today.
class _WeatherCompact extends StatelessWidget {
  const _WeatherCompact({required this.weather, required this.size});

  final Weather weather;
  final WidgetSize size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final degrees = l10n.weatherDegrees(weather.temperature.round());
    final sky = labelOf(l10n, weather.condition);
    if (size == WidgetSize.strip) {
      return Row(
        children: [
          Icon(iconOf(weather.condition), size: Dimens.iconSmall),
          const SizedBox(width: Dimens.gapSmall),
          Flexible(child: Text('$degrees · $sky')),
        ],
      );
    }
    final today = weather.days.isEmpty ? null : weather.days.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(degrees, style: theme.textTheme.headlineMedium),
              ),
            ),
            const SizedBox(width: Dimens.gapSmall),
            Icon(iconOf(weather.condition), semanticLabel: sky),
          ],
        ),
        Text(sky, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (today != null)
          Text(
            l10n.weatherRange(today.min.round(), today.max.round()),
            style: theme.textTheme.bodySmall,
          ),
      ],
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
