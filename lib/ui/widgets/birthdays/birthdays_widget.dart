import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/everyday.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/everyday.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the birthdays widget (#115).
class BirthdaysWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const BirthdaysWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// How many birthdays are shown.
  static const shown = 6;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      BirthdaysWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => RemoteWidget<List<Birthday>>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.birthdaysTitle,
    query: birthdaysQuery,
    interval: const Duration(hours: 1),
    compact: (context, birthdays, size) {
      final l10n = context.l10n;
      if (birthdays.isEmpty) return Text(l10n.birthdaysEmpty);
      final next = birthdays.reduce((a, b) => b.inDays < a.inDays ? b : a);
      return CompactLines(
        headline: next.name,
        detail: daysText(context, next.inDays),
        size: size,
      );
    },
    builder: (context, birthdays) {
      final l10n = context.l10n;
      if (birthdays.isEmpty) return Text(l10n.birthdaysEmpty);
      final next = [...birthdays]..sort((a, b) => a.inDays.compareTo(b.inDays));
      return TileRows(
        items: next.take(shown).toList(),
        rowHeight: TileRows.twoLineRowHeight,
        rowBuilder: (context, b) => InfoRow(
          leading: Text(b.inDays == 0 ? '🎉' : '🎂', semanticsLabel: ''),
          title: b.name,
          subtitle: [
            shortDate(context, b.next),
            if (b.age != null) l10n.birthdaysTurns(b.age!),
          ].join(' · '),
          trailing: daysText(context, b.inDays),
          trailingTone: b.inDays <= 1 ? Tone.warning : null,
        ),
      );
    },
  );
}
