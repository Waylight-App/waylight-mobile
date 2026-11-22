import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the fuel price widget (#126); tapping a station opens
/// it in the maps app.
class FuelWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const FuelWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      FuelWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<FuelOverview>(
    placement: widget,
    defaultTitle: context.l10n.fuelTitle,
    query: fuelQuery,
    interval: const Duration(minutes: 10),
    compact: (context, fuel, size) {
      final l10n = context.l10n;
      final station = fuel.stations.where((s) => s.price != null).firstOrNull;
      if (station == null) return Text(l10n.fuelEmpty);
      final price = NumberFormat.currency(
        locale: Localizations.localeOf(context).toLanguageTag(),
        symbol: '€',
        decimalDigits: 3,
      );
      return CompactLines(
        headline: price.format(station.price),
        detail:
            '${fuel.fuel.toUpperCase()} · '
            '${station.brand.isEmpty ? station.name : station.brand}',
        size: size,
      );
    },
    builder: (context, fuel) {
      final l10n = context.l10n;
      if (fuel.stations.isEmpty) return Text(l10n.fuelEmpty);
      final price = NumberFormat.currency(
        locale: Localizations.localeOf(context).toLanguageTag(),
        symbol: '€',
        decimalDigits: 3,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${fuel.fuel.toUpperCase()} · ${fuel.place}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TileRows(
            items: fuel.stations,
            rowHeight: TileRows.twoLineRowHeight,
            reserved: 20,
            rowBuilder: (context, s) => InfoRow(
              title: s.brand.isEmpty ? s.name : '${s.brand} · ${s.name}',
              subtitle: [
                if (s.distanceKm != null)
                  '${s.distanceKm!.toStringAsFixed(1)} km',
                if (!s.open) l10n.fuelClosed,
              ].join(' · '),
              trailing: s.price == null ? '–' : price.format(s.price),
              trailingTone: s.open ? null : Tone.neutral,
              onTap: s.address.isEmpty
                  ? null
                  : () => LinkOpener.of(context).open(
                      Uri(
                        scheme: 'geo',
                        path: '0,0',
                        queryParameters: {'q': s.address},
                      ),
                    ),
            ),
          ),
        ],
      );
    },
  );
}
