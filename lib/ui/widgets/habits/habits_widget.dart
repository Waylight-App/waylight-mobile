import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/common/tag_writer.dart';
import 'package:waylight_mobile/ui/widgets/habits/habits_view_model.dart';

/// The native view of the habits widget (#128).
class HabitsWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const HabitsWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#228).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.habitsTitle,
        full: () => HabitsWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => HabitsViewModel(
      serverRepository: context.read(),
      habitsRepository: context.read(),
    ),
    builder: (context, viewModel) => WidgetFrame<void>(
      title: widget.title.isNotEmpty ? widget.title : context.l10n.habitsTitle,
      load: viewModel.load,
      interval: const Duration(minutes: 15),
      builder: (context, _) => ErrorSnackListener(
        listenable: viewModel,
        takeError: viewModel.takeLastError,
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final l10n = context.l10n;
            final habits = viewModel.today;
            // Rows keep to one line in a tile, which fits them by height.
            final lines = WidgetSizeScope.inGrid(context) ? 1 : null;
            final overflow = lines == null ? null : TextOverflow.ellipsis;
            if (habits.isEmpty) return Text(l10n.habitsEmpty);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TileRows(
                  items: habits,
                  rowHeight: TileRows.twoLineRowHeight + 8,
                  rowBuilder: (context, h) => TagWritable(
                    action: HabitTag(h.id),
                    subject: h.name,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: h.doneToday,
                      onChanged: (_) => viewModel.toggle(h),
                      title: Text(
                        h.emoji.isEmpty ? h.name : '${h.emoji} ${h.name}',
                        maxLines: lines,
                        overflow: overflow,
                      ),
                      subtitle: Text(
                        l10n.habitsStreak(h.current, h.best),
                        maxLines: lines,
                        overflow: overflow,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
