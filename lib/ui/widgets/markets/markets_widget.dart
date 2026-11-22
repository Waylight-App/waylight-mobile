import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the markets widget (#132): the watchlist with its
/// daily change.
class MarketsWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const MarketsWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      MarketsWidget(widget: widget, key: ValueKey(widget.id));

  /// The symbols of the widget's settings, like the web interface.
  static List<String> symbolsOf(Map<String, Object?> config) {
    final list = [
      if (config['symbols'] case final List<Object?> s)
        for (final x in s)
          if (x is String && x.isNotEmpty) x,
    ];
    return list.isEmpty ? defaultMarketSymbols : list.take(12).toList();
  }

  /// "stooq:^dax" → "DAX", "fx:USD" → "EUR/USD".
  static String label(String symbol) {
    final (source, code) = switch (symbol.split(':')) {
      [final s, final c] => (s, c),
      _ => ('', symbol),
    };
    if (source == 'fx') return 'EUR/$code';
    return code.replaceAll('^', '').toUpperCase();
  }

  @override
  Widget build(BuildContext context) => SimpleWidget<List<MarketQuote>>(
    placement: widget,
    defaultTitle: context.l10n.marketsTitle,
    query: marketsQuery.withQuery({
      'symbols': symbolsOf(widget.config).join(','),
    }),
    interval: const Duration(minutes: 15),
    compact: (context, quotes, size) {
      final first = quotes.firstOrNull;
      if (first == null) return const Text('–');
      final number = NumberFormat.decimalPatternDigits(
        locale: Localizations.localeOf(context).toLanguageTag(),
        decimalDigits: 2,
      );
      final change = first.changePercent;
      return CompactLines(
        headline: label(first.symbol),
        detail: [
          if (first.value != null) number.format(first.value),
          if (change != null)
            '${change >= 0 ? '+' : ''}${number.format(change)} %',
        ].join(' · '),
        size: size,
      );
    },
    builder: (context, quotes) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final number = NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: 2,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileRows(
            items: quotes,
            rowHeight: TileRows.twoLineRowHeight,
            rowBuilder: (context, q) => InfoRow(
              title: label(q.symbol),
              subtitle: q.value == null ? null : number.format(q.value),
              trailing: q.changePercent == null
                  ? '–'
                  : '${q.changePercent! >= 0 ? '+' : ''}${number.format(q.changePercent)} %',
              trailingTone: q.changePercent == null
                  ? null
                  : q.changePercent! >= 0
                  ? Tone.ok
                  : Tone.critical,
            ),
          ),
        ],
      );
    },
  );
}
