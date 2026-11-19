import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The widget kind that shows the source of a timeline entry, if any.
String? widgetOfSource(String source) => switch (source) {
  'container' => 'docker',
  'service' || 'tls' => 'services',
  'backup' => 'backup-status',
  'disk' => 'system',
  'diskhealth' => 'diskhealth',
  'parcel' => 'parcels',
  'sports' => 'sports',
  _ => null,
};

/// The timeline of the instance (#109) with a filter by importance; an
/// entry opens the widget of its source.
class TimelineScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const TimelineScreen({required this.viewModel, super.key});

  /// Loads the timeline.
  final RemoteWidgetViewModel<List<TimelineEntry>> viewModel;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _severity = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final load = widget.viewModel.load;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.MMMd(locale).add_Hm();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.timelineTitle)),
      body: ListenableBuilder(
        listenable: load,
        builder: (context, _) {
          final entries = switch (load.result) {
            Ok(:final value) => value,
            _ => const <TimelineEntry>[],
          };
          final shown = _severity.isEmpty
              ? entries
              : entries.where((e) => e.severity == _severity).toList();
          return RefreshIndicator(
            onRefresh: load.execute,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.gap),
              children: [
                Wrap(
                  spacing: Dimens.gapSmall,
                  children: [
                    for (final (value, label) in [
                      ('', l10n.timelineAll),
                      ('warning', l10n.diskHealthWarning),
                      ('critical', l10n.timelineCritical),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _severity == value,
                        onSelected: (_) => setState(() => _severity = value),
                      ),
                  ],
                ),
                if (load.result case Error(:final error))
                  Text(l10n.errorMessage(error))
                else if (load.running && entries.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (shown.isEmpty)
                  Text(l10n.timelineEmpty),
                for (final e in shown)
                  InfoRow(
                    leading: StatusDot(
                      tone: switch (e.severity) {
                        'critical' => Tone.critical,
                        'warning' => Tone.warning,
                        _ => Tone.neutral,
                      },
                      label: e.severity,
                    ),
                    title: e.message,
                    subtitle: '${time.format(e.at.toLocal())} · ${e.subject}',
                    onTap: switch (widgetOfSource(e.source)) {
                      final kind? => () => context.go(
                        Uri(
                          path: Routes.home,
                          queryParameters: {'widget': kind},
                        ).toString(),
                      ),
                      null => null,
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
