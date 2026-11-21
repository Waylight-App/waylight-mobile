import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/presence/presence_view_model.dart';

/// The words for a status, as on the server's widget.
@visibleForTesting
String presenceLabel(AppLocalizations l10n, PresenceStatus s) => switch (s) {
  PresenceStatus.office => l10n.presenceOffice,
  PresenceStatus.home => l10n.presenceHome,
  PresenceStatus.away => l10n.presenceAway,
  PresenceStatus.none => l10n.presenceNone,
};

/// The native view of the presence widget (#200).
class PresenceWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const PresenceWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      PresenceWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => PresenceViewModel(
      serverRepository: context.read(),
      presenceRepository: context.read(),
      group: switch (widget.config['group']) {
        final String g => g,
        _ => '',
      },
    ),
    builder: (context, viewModel) => WidgetFrame<void>(
      title: widget.title.isNotEmpty
          ? widget.title
          : context.l10n.presenceTitle,
      load: viewModel.load,
      // As often as the web widget, which refreshes every 30 seconds.
      interval: const Duration(seconds: 30),
      builder: (context, _) => ErrorSnackListener(
        listenable: viewModel,
        takeError: viewModel.takeLastError,
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => _Board(viewModel: viewModel),
        ),
      ),
    ),
  );
}

class _Board extends StatelessWidget {
  const _Board({required this.viewModel});

  final PresenceViewModel viewModel;

  String _day(BuildContext context, DateTime d) =>
      MaterialLocalizations.of(context).formatShortMonthDay(d);

  Future<void> _away(BuildContext context) async {
    // Choosing Away again clears it; no date is asked then.
    if (viewModel.mine == PresenceStatus.away) {
      return viewModel.choose(PresenceStatus.away);
    }
    final now = DateTime.now();
    final back = await showDatePicker(
      context: context,
      helpText: context.l10n.presenceReturnOn,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    // Cancelling the date still sets Away, without a day of return.
    await viewModel.choose(PresenceStatus.away, returnOn: back);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (viewModel.off) return Text(l10n.presenceOff);
    final board = viewModel.board;
    if (board == null) return const SizedBox.shrink();
    final c = board.counts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (board.mine != null) ...[
          Text(
            l10n.presenceMine,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: Dimens.gapSmall),
          SegmentedButton<PresenceStatus>(
            key: const ValueKey('presence.mine'),
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              for (final s in const [
                PresenceStatus.office,
                PresenceStatus.home,
                PresenceStatus.away,
              ])
                ButtonSegment(value: s, label: Text(presenceLabel(l10n, s))),
            ],
            selected: {
              if (viewModel.mine != PresenceStatus.none) viewModel.mine,
            },
            onSelectionChanged: viewModel.canSet
                ? (selection) {
                    // A tap on the active segment empties the selection.
                    final tapped = selection.isEmpty
                        ? viewModel.mine
                        : selection.single;
                    if (tapped == PresenceStatus.away) {
                      _away(context).ignore();
                    } else {
                      viewModel.choose(tapped).ignore();
                    }
                  }
                : null,
          ),
          const SizedBox(height: Dimens.gap),
        ],
        if (board.people.isEmpty)
          Text(l10n.presenceEmpty)
        else
          for (final p in board.people)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(p.name),
              subtitle: p.fromAbsence ? Text(l10n.presenceFromAbsence) : null,
              trailing: Text(switch ((p.status, p.returnOn)) {
                (PresenceStatus.away, final back?) =>
                  '${presenceLabel(l10n, p.status)} · ${l10n.presenceBack(_day(context, back))}',
                _ => presenceLabel(l10n, p.status),
              }),
            ),
        const SizedBox(height: Dimens.gapSmall),
        Text(
          l10n.presenceCounts(
            c[PresenceStatus.office] ?? 0,
            c[PresenceStatus.home] ?? 0,
            c[PresenceStatus.away] ?? 0,
            c[PresenceStatus.none] ?? 0,
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
