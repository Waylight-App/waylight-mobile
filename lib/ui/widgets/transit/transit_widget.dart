import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/departure.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/transit/transit_view_model.dart';

/// The native view of the departures widget (#49).
class TransitWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const TransitWidget({required this.widget, super.key});

  /// The placement with the widget's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      TransitWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = TransitConfig.fromJson(widget.config);
    return ViewModelHost(
      create: (context) => TransitViewModel(
        config: config,
        serverRepository: context.read(),
        transitRepository: context.read(),
      ),
      builder: (context, viewModel) => WidgetFrame(
        title: widget.title.isNotEmpty
            ? widget.title
            : config.stopName.isNotEmpty
            ? config.stopName
            : l10n.transitTitle,
        load: viewModel.load,
        interval: const Duration(minutes: 1),
        errorText: (error) =>
            error is NoStopException ? l10n.transitNoStop : null,
        compact: (context, departures, size) {
          final next = [
            for (final d in departures)
              if (!d.cancelled) d,
          ];
          if (next.isEmpty) return Text(l10n.transitEmpty);
          final first = next.first;
          final minutes = viewModel.minutesUntil(first);
          final when = minutes == 0
              ? l10n.transitNow
              : l10n.transitInMinutes(minutes);
          final line = '${first.line} ${first.headsign}';
          if (size == WidgetSize.strip) return Text('$line · $when');
          final time = DateFormat.Hm(
            Localizations.localeOf(context).toLanguageTag(),
          );
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
        },
        builder: (context, departures) => departures.isEmpty
            ? Text(l10n.transitEmpty)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final d in departures)
                    _DepartureRow(
                      departure: d,
                      minutes: viewModel.minutesUntil(d),
                    ),
                ],
              ),
      ),
    );
  }
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
