import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/network.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/network.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the FRITZ!Box internet widget (#124).
class FritzboxWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const FritzboxWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      FritzboxWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<FritzboxStatus>(
    placement: widget,
    defaultTitle: 'FRITZ!Box',
    query: fritzboxQuery,
    interval: const Duration(minutes: 1),
    builder: (context, box) {
      final l10n = context.l10n;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(
            leading: StatusDot(
              tone: box.connected ? Tone.ok : Tone.critical,
              label: box.connected ? l10n.servicesOnline : l10n.servicesOffline,
            ),
            title: box.model,
            subtitle: [
              if (box.externalIp.isNotEmpty) box.externalIp,
              if (box.uptime != null)
                l10n.systemUptime(box.uptime!.inDays, box.uptime!.inHours % 24),
            ].join(' · '),
          ),
          if (box.downstreamPercent != null)
            MeterRow(
              label: l10n.speedtestDownload,
              percent: box.downstreamPercent!,
            ),
          if (box.upstreamPercent != null)
            MeterRow(
              label: l10n.speedtestUpload,
              percent: box.upstreamPercent!,
            ),
        ],
      );
    },
  );
}

/// The native view of the FRITZ!Box call list (#125); tapping a number
/// offers to call it.
class CallsWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const CallsWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// How many calls are shown.
  static const shown = 8;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CallsWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<List<PhoneCall>>(
    placement: widget,
    defaultTitle: context.l10n.callsTitle,
    query: callsQuery,
    interval: const Duration(minutes: 2),
    builder: (context, calls) {
      final l10n = context.l10n;
      if (calls.isEmpty) return Text(l10n.callsEmpty);
      final locale = Localizations.localeOf(context).toLanguageTag();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in calls.take(shown))
            InfoRow(
              leading: Text(
                switch (c.type) {
                  CallType.incoming => '↙️',
                  CallType.outgoing => '↗️',
                  CallType.missed || CallType.rejected => '❌',
                },
                semanticsLabel: switch (c.type) {
                  CallType.incoming => l10n.callsIncoming,
                  CallType.outgoing => l10n.callsOutgoing,
                  CallType.missed => l10n.callsMissed,
                  CallType.rejected => l10n.callsRejected,
                },
              ),
              title: c.name.isNotEmpty ? c.name : c.number,
              subtitle:
                  '${DateFormat.MMMd(locale).add_Hm().format(c.at.toLocal())}${c.durationMinutes > 0 ? ' · ${c.durationMinutes} min' : ''}',
              trailingTone: Tone.critical,
              trailing: c.type == CallType.missed ? l10n.callsMissed : null,
              onTap: () => LinkOpener.of(context)
                  .open(Uri(scheme: 'tel', path: c.number.replaceAll(' ', ''))),
            ),
        ],
      );
    },
  );
}
