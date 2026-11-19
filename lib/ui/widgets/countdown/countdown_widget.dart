import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/everyday.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the countdown widget (#118); dates within a week are
/// highlighted like in the web interface.
class CountdownWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const CountdownWidget({required this.widget, this.now, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The current time; tests pass a fixed one.
  final DateTime Function()? now;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CountdownWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => RemoteWidget<List<Countdown>>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.countdownTitle,
    query: countdownsQuery,
    interval: const Duration(hours: 1),
    builder: (context, countdowns) {
      final today = (now ?? DateTime.now)();
      final ahead = countdowns.where((c) => c.daysFrom(today) >= 0).toList();
      if (ahead.isEmpty) return Text(context.l10n.countdownEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in ahead)
            InfoRow(
              leading: c.emoji.isEmpty
                  ? null
                  : Text(c.emoji, semanticsLabel: ''),
              title: c.title,
              subtitle: [
                shortDate(context, c.date),
                if (c.time != null) c.time!,
              ].join(' · '),
              trailing: daysText(context, c.daysFrom(today)),
              trailingTone: c.daysFrom(today) <= 7 ? Tone.warning : null,
            ),
        ],
      );
    },
  );
}
