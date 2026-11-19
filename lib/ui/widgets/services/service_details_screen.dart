import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// Uptime and outages of one service (#108).
class ServiceDetailsScreen extends StatelessWidget {
  /// Creates the screen for the service [id] named [name].
  const ServiceDetailsScreen({required this.id, required this.name, super.key});

  /// The service's id.
  final String id;

  /// Its name, for the title.
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm();
    String percent(double? v) =>
        v == null ? '–' : '${v.toStringAsFixed(v >= 99.95 ? 0 : 2)} %';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(Dimens.gap),
        children: [
          RemoteWidget<List<ServiceUptime>>(
            title: l10n.serviceUptime,
            query: uptimeQuery,
            builder: (context, all) {
              final u = all.where((x) => x.serviceId == id).firstOrNull;
              if (u == null) return Text(l10n.listEmpty);
              return Column(
                children: [
                  InfoRow(title: l10n.serviceDay, trailing: percent(u.day)),
                  InfoRow(title: l10n.serviceWeek, trailing: percent(u.week)),
                  InfoRow(title: l10n.serviceMonth, trailing: percent(u.month)),
                  InfoRow(
                    title: l10n.serviceQuarter,
                    trailing: percent(u.quarter),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: Dimens.gapCard),
          RemoteWidget<List<Incident>>(
            title: l10n.serviceIncidents,
            query: incidentsQuery,
            builder: (context, all) {
              final mine = all.where((i) => i.serviceId == id).toList();
              if (mine.isEmpty) return Text(l10n.serviceNoIncidents);
              return Column(
                children: [
                  for (final i in mine)
                    InfoRow(
                      leading: StatusDot(
                        tone: i.end == null ? Tone.critical : Tone.neutral,
                        label: i.end == null ? l10n.servicesOffline : '',
                      ),
                      title: i.end == null
                          ? l10n.serviceDownSince(time.format(i.start))
                          : '${time.format(i.start)} – ${time.format(i.end!)}',
                      subtitle: i.cause,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
