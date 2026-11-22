import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the study progress widget (#150).
class StudyWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const StudyWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      StudyWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => SimpleWidget<StudyProgress>(
    placement: widget,
    defaultTitle: context.l10n.studyTitle,
    query: studyQuery,
    interval: const Duration(hours: 1),
    builder: (context, study) {
      final l10n = context.l10n;
      final number = NumberFormat.decimalPatternDigits(
        locale: Localizations.localeOf(context).toLanguageTag(),
        decimalDigits: 1,
      );
      // Credits are formatted without decimals unless they have some.
      String ects(double v) =>
          v == v.roundToDouble() ? '${v.round()}' : number.format(v);
      return TileRows<Widget>(
        items: [
          MeterRow(
            label: l10n.studyCredits(
              ects(study.passedEcts),
              ects(study.totalEcts),
            ),
            percent: study.percent,
            invert: true,
          ),
          if (study.average != null)
            InfoRow(
              title: l10n.studyAverage,
              trailing: number.format(study.average),
            ),
          for (final m in study.inProgress)
            InfoRow(title: m, subtitle: l10n.studyInProgress),
        ],
        rowHeight: TileRows.twoLineRowHeight,
        rowBuilder: (context, row) => row,
      );
    },
  );
}
