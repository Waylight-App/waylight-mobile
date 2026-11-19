import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/network.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/network.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the DNS filter widget (#111): queries, blocked share
/// and the most blocked domains. Pausing follows with the actions of #108.
class AdguardWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const AdguardWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      AdguardWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<DnsFilterStats>(
    placement: widget,
    defaultTitle: context.l10n.dnsFilterTitle,
    query: dnsFilterQuery,
    builder: (context, stats) {
      final l10n = context.l10n;
      final number = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(
            leading: StatusDot(
              tone: stats.protectionEnabled ? Tone.ok : Tone.warning,
              label: stats.protectionEnabled
                  ? l10n.dnsFilterOn
                  : l10n.dnsFilterPaused,
            ),
            title: stats.protectionEnabled
                ? l10n.dnsFilterOn
                : l10n.dnsFilterPaused,
            subtitle: l10n.dnsFilterQueries(number.format(stats.queries)),
          ),
          MeterRow(
            label: l10n.dnsFilterBlocked(number.format(stats.blocked)),
            percent: stats.blockedPercent,
          ),
          for (final (domain, count) in stats.topBlocked.take(3))
            InfoRow(title: domain, trailing: number.format(count)),
        ],
      );
    },
  );
}
