import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/queries/information.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/simple_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the sports widget (#149): the top of the table of the
/// configured league.
class SportsWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const SportsWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      SportsWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final league = widget.config['league'];
    final team = widget.config['team'];
    return SimpleWidget<LeagueTable>(
      placement: widget,
      defaultTitle: context.l10n.sportsTitle,
      query: sportsQuery.withQuery({
        'league': league is String && league.isNotEmpty ? league : 'bl1',
        if (team is int && team > 0) 'team': '$team',
      }),
      interval: const Duration(minutes: 30),
      builder: (context, table) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(table.league, style: Theme.of(context).textTheme.labelLarge),
          TileRows(
            items: table.rows.take(6).toList(),
            rowHeight: TileRows.twoLineRowHeight,
            reserved: 24,
            rowBuilder: (context, r) => InfoRow(
              leading: Text('${r.position}.'),
              title: r.team,
              subtitle: context.l10n.sportsPlayed(r.played),
              trailing: context.l10n.sportsPoints(r.points),
            ),
          ),
        ],
      ),
    );
  }
}
