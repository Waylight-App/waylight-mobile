import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/data/repositories/widget_data/queries/home_server.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/home_server.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the timeline widget (#152): the newest events.
class TimelineWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const TimelineWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// How many events are shown.
  static const shown = 8;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      TimelineWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<List<TimelineEntry>>(
    placement: widget,
    defaultTitle: context.l10n.timelineTitle,
    query: timelineQuery,
    interval: const Duration(minutes: 2),
    builder: (context, entries) {
      if (entries.isEmpty) return Text(context.l10n.timelineEmpty);
      final locale = Localizations.localeOf(context).toLanguageTag();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in entries.take(shown))
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
              subtitle:
                  '${DateFormat.MMMd(locale).add_Hm().format(e.at.toLocal())} · ${e.subject}',
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(Routes.timeline),
              child: Text(context.l10n.timelineOpen),
            ),
          ),
        ],
      );
    },
  );
}
