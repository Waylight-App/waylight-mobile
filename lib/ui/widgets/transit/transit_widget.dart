import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/dashboard/dashboard_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/domain/models/place.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';
import 'package:waylight_mobile/ui/core/widgets/choice_search_sheet.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_preview.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_example.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The native view of the departures widget (#49).
class TransitWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const TransitWidget({required this.widget, super.key});

  /// The placement with the widget's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      TransitWidget(widget: widget, key: ValueKey(widget.id));

  /// The gallery preview from example data (#251).
  static Widget preview(BuildContext context, String title, WidgetSize size) {
    final now = DateTime.now();
    final departures = exampleDepartures(now);
    int minutesUntil(Departure d) => d.expected.difference(now).inMinutes;
    return WidgetPreview(
      title: title,
      size: size,
      compact: (context) => _TransitCompact(
        departures: departures,
        size: size,
        minutesUntil: minutesUntil,
      ),
      full: (context) =>
          _DepartureList(departures: departures, minutesUntil: minutesUntil),
    );
  }

  /// Lets the user search a stop and stores it on the widget (#230).
  static Future<void> _chooseStop(
    BuildContext context,
    TransitViewModel viewModel,
  ) async {
    final l10n = context.l10n;
    final stop = await ChoiceSearchSheet.show<Stop>(
      context,
      title: l10n.setUpStopTitle,
      search: viewModel.searchStops,
      label: (stop) => stop.name,
    );
    if (stop == null) return;
    await viewModel.chooseStop.execute(stop);
    if (viewModel.chooseStop.result case Error(:final error)
        when context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => TransitViewModel(
        config: TransitConfig.fromJson(widget.config),
        serverRepository: context.read(),
        transitRepository: context.read(),
        dashboardRepository: context.read<DashboardRepository?>(),
        widgetId: widget.id,
        widgetConfig: widget.config,
      ),
      builder: (context, viewModel) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => _frame(context, viewModel),
      ),
    );
  }

  Widget _frame(BuildContext context, TransitViewModel viewModel) {
    final l10n = context.l10n;
    final config = viewModel.config;
    return WidgetFrame(
      title: widget.title.isNotEmpty
          ? widget.title
          : config.stopName.isNotEmpty
          ? config.stopName
          : l10n.transitTitle,
      load: viewModel.load,
      interval: const Duration(minutes: 1),
      errorText: (error) =>
          error is NoStopException ? l10n.transitNoStop : null,
      setUp: (error) => error is NoStopException && viewModel.canChooseStop
          ? (
              message: l10n.transitNoStop,
              onSetUp: () => _chooseStop(context, viewModel).ignore(),
            )
          : null,
      compact: (context, departures, size) => _TransitCompact(
        departures: departures,
        size: size,
        minutesUntil: viewModel.minutesUntil,
      ),
      builder: (context, departures) => _DepartureList(
        departures: departures,
        minutesUntil: viewModel.minutesUntil,
      ),
    );
  }
}

/// The next departure in a small or strip tile, with the two after it.
class _TransitCompact extends StatelessWidget {
  const _TransitCompact({
    required this.departures,
    required this.size,
    required this.minutesUntil,
  });

  final List<Departure> departures;
  final WidgetSize size;
  final int Function(Departure departure) minutesUntil;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final next = [
      for (final d in departures)
        if (!d.cancelled) d,
    ];
    if (next.isEmpty) return Text(l10n.transitEmpty);
    final first = next.first;
    final minutes = minutesUntil(first);
    final when = minutes == 0
        ? l10n.transitNow
        : l10n.transitInMinutes(minutes);
    final line = '${first.line} ${first.headsign}';
    if (size == WidgetSize.strip) return Text('$line · $when');
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final later = [
      for (final d in next.skip(1).take(2)) time.format(d.expected),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(when, style: Theme.of(context).textTheme.headlineSmall),
        Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (later.isNotEmpty)
          Text(
            l10n.transitThen(later.join(', ')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// Every departure, one row each.
class _DepartureList extends StatelessWidget {
  const _DepartureList({required this.departures, required this.minutesUntil});

  final List<Departure> departures;
  final int Function(Departure departure) minutesUntil;

  @override
  Widget build(BuildContext context) => departures.isEmpty
      ? Text(context.l10n.transitEmpty)
      : TileRows(
          items: departures,
          rowHeight: TileRows.twoLineRowHeight,
          rowBuilder: (context, d) =>
              _DepartureRow(departure: d, minutes: minutesUntil(d)),
        );
}

class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.departure, required this.minutes});

  final Departure departure;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.Hm(locale).format(departure.planned);
    final cancelled = departure.cancelled;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
      child: Row(
        children: [
          Icon(
            iconOf(departure.mode),
            size: Dimens.iconSmall,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Dimens.gapSmall),
          SizedBox(
            width: Dimens.labelColumn * 1.5,
            child: Text(departure.line, style: theme.textTheme.titleSmall),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  departure.headsign,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cancelled
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                Text(
                  departure.track.isEmpty
                      ? time
                      : l10n.transitTimeTrack(time, departure.track),
                  style: muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimens.gapSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cancelled
                    ? l10n.transitCancelled
                    : minutes == 0
                    ? l10n.transitNow
                    : l10n.transitInMinutes(minutes),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cancelled ? theme.colorScheme.error : null,
                ),
              ),
              if (!cancelled && departure.delayMinutes > 0)
                Text(
                  l10n.transitDelay(departure.delayMinutes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: StatusColors.of(context).warning,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The icon for [mode].
@visibleForTesting
IconData iconOf(TransitMode mode) => switch (mode) {
  TransitMode.bus => Icons.directions_bus_outlined,
  TransitMode.tram => Icons.tram_outlined,
  TransitMode.subway => Icons.subway_outlined,
  TransitMode.suburban ||
  TransitMode.regionalRail ||
  TransitMode.highspeedRail => Icons.train_outlined,
  TransitMode.ferry => Icons.directions_boat_outlined,
  TransitMode.other => Icons.commute,
};
