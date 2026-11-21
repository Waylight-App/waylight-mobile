import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/network.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/network.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/admin_actions.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the DNS filter widget (#111): queries, blocked share
/// and the most blocked domains; admins pause blocking for a while (#108).
class AdguardWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const AdguardWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#278).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.dnsFilterTitle,
        full: () => AdguardWidget(widget: widget, key: ValueKey(widget.id)),
      );

  /// The configured DNS filter; every request names it, so a widget set to
  /// Pi-hole neither shows nor pauses AdGuard Home (#280).
  String get _provider => dnsFilterProvider(widget.config);

  @override
  Widget build(BuildContext context) => SimpleWidget<DnsFilterStats>(
    placement: widget,
    defaultTitle: context.l10n.dnsFilterTitle,
    query: dnsFilterQuery.withQuery({'provider': _provider}),
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
            onTap: stats.protectionEnabled
                ? () => _pause(context, _provider)
                : null,
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

  static Future<void> _pause(BuildContext context, String provider) async {
    final l10n = context.l10n;
    if (!await isAdmin(context) || !context.mounted) return;
    final repo = context.read<HomeServerActionsRepository>();
    await showActions(context, [
      for (final minutes in const [5, 30, 60])
        (
          icon: Icons.pause_circle_outline,
          label: l10n.dnsFilterPause(minutes),
          onTap: () => runAction(
            context,
            (server) =>
                repo.pauseDnsFilter(server, minutes, provider: provider),
            done: l10n.dnsFilterPaused,
          ),
        ),
    ]);
  }
}
