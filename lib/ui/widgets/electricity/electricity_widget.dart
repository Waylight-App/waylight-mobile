import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/everyday.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the electricity price widget (#122): the current
/// price and a bar per hour for today and tomorrow, cheapest hours marked.
class ElectricityWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ElectricityWidget({required this.widget, this.now, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The current time; tests pass a fixed one.
  final DateTime Function()? now;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      ElectricityWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final zone = widget.config['zone'];
    return RemoteWidget<ElectricityPrices>(
      title: widget.title.isNotEmpty
          ? widget.title
          : context.l10n.electricityTitle,
      query: zone is String && zone.isNotEmpty
          ? electricityQuery.withQuery({'zone': zone})
          : electricityQuery,
      interval: const Duration(minutes: 15),
      builder: (context, prices) {
        final l10n = context.l10n;
        final at = (now ?? DateTime.now)();
        final current = prices.at(at);
        final today = DateTime(at.year, at.month, at.day);
        final days = <DateTime, List<PriceHour>>{};
        for (final h in prices.hours) {
          final day = DateTime(h.start.year, h.start.month, h.start.day);
          if (day.isBefore(today)) continue;
          days.putIfAbsent(day, () => []).add(h);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (current != null)
              Text(
                l10n.electricityNow(_cent(context, current.centPerKWh)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            for (final entry in days.entries) ...[
              const SizedBox(height: Dimens.gapSmall),
              // Labelled by date, not position: hours of another day never
              // read as today or tomorrow.
              Text(
                entry.key == today
                    ? l10n.todosToday
                    : entry.key == today.add(const Duration(days: 1))
                    ? l10n.todosTomorrow
                    : shortDate(context, entry.key),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              _Bars(hours: entry.value, current: current),
            ],
            if (days.length == 1) ...[
              const SizedBox(height: Dimens.gapTiny),
              Text(
                l10n.electricityTomorrowLater,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}

String _cent(BuildContext context, double cent) =>
    '${NumberFormat.decimalPatternDigits(locale: Localizations.localeOf(context).toLanguageTag(), decimalDigits: 1).format(cent)} ct/kWh';

class _Bars extends StatelessWidget {
  const _Bars({required this.hours, required this.current});

  final List<PriceHour> hours;
  final PriceHour? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = hours.fold<double>(
      0,
      (m, h) => h.centPerKWh > m ? h.centPerKWh : m,
    );
    final min = hours.fold<double>(
      0,
      (m, h) => h.centPerKWh < m ? h.centPerKWh : m,
    );
    final span = (max - min) == 0 ? 1 : max - min;
    final cheapest = hours.where((h) => h.cheapest).toList();
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    return Semantics(
      label: cheapest.isEmpty
          ? null
          : context.l10n.electricityCheapest(
              cheapest.map((h) => time.format(h.start)).join(', '),
            ),
      excludeSemantics: true,
      child: SizedBox(
        height: Dimens.iconLarge * 1.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in hours)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FractionallySizedBox(
                    heightFactor: ((h.centPerKWh - min) / span).clamp(0.05, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: identical(h, current)
                            ? theme.colorScheme.onSurface
                            : h.cheapest
                            ? toneColor(context, Tone.ok)
                            : theme.colorScheme.outlineVariant,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(Dimens.gapTiny / 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
