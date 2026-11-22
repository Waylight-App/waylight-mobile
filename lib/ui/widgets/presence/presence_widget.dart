import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/presence.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_preview.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/presence/presence_example.dart';
import 'package:waylight_mobile/ui/widgets/presence/presence_view_model.dart';

/// The words for a status, as on the server's widget.
@visibleForTesting
String presenceLabel(AppLocalizations l10n, PresenceStatus s) => switch (s) {
  PresenceStatus.office => l10n.presenceOffice,
  PresenceStatus.home => l10n.presenceHome,
  PresenceStatus.away => l10n.presenceAway,
  PresenceStatus.none => l10n.presenceNone,
};

/// Sets the viewer's status, with the day of return for away.
typedef ChooseStatus = Future<void> Function(
  PresenceStatus status, {
  DateTime? returnOn,
});

/// The native view of the presence widget (#200).
class PresenceWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const PresenceWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      PresenceWidget(widget: widget, key: ValueKey(widget.id));

  /// The gallery preview from example data (#251).
  static Widget preview(BuildContext context, String title, WidgetSize size) {
    final board = examplePresence(DateTime.now());
    final mine = board.mine!.status;
    Future<void> choose(PresenceStatus _, {DateTime? returnOn}) async {}
    return WidgetPreview(
      title: title,
      size: size,
      compact: (context) => _QuickStatus(
        board: board,
        mine: mine,
        canSet: true,
        choose: choose,
        size: size,
      ),
      full: (context) =>
          _Board(board: board, mine: mine, canSet: true, choose: choose),
    );
  }

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
      compact: (context, _, size) => ErrorSnackListener(
        listenable: viewModel,
        takeError: viewModel.takeLastError,
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => _QuickStatus(
            board: viewModel.board,
            off: viewModel.off,
            mine: viewModel.mine,
            canSet: viewModel.canSet,
            choose: viewModel.choose,
            size: size,
          ),
        ),
      ),
      builder: (context, _) => ErrorSnackListener(
        listenable: viewModel,
        takeError: viewModel.takeLastError,
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => _Board(
            board: viewModel.board,
            off: viewModel.off,
            mine: viewModel.mine,
            canSet: viewModel.canSet,
            choose: viewModel.choose,
          ),
        ),
      ),
    ),
  );
}

class _Board extends StatelessWidget {
  const _Board({
    required this.board,
    required this.mine,
    required this.canSet,
    required this.choose,
    this.off = false,
  });

  final PresenceBoard? board;
  final bool off;
  final PresenceStatus mine;
  final bool canSet;
  final ChooseStatus choose;

  String _day(BuildContext context, DateTime d) =>
      MaterialLocalizations.of(context).formatShortMonthDay(d);

  Future<void> _away(BuildContext context) async {
    // Choosing Away again clears it; no date is asked then.
    if (mine == PresenceStatus.away) {
      return choose(PresenceStatus.away);
    }
    final now = DateTime.now();
    final back = await showDatePicker(
      context: context,
      helpText: context.l10n.presenceReturnOn,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    // Cancelling the date still sets Away, without a day of return.
    await choose(PresenceStatus.away, returnOn: back);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (off) return Text(l10n.presenceOff);
    final board = this.board;
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
            selected: {if (mine != PresenceStatus.none) mine},
            onSelectionChanged: canSet
                ? (selection) {
                    // A tap on the active segment empties the selection.
                    final tapped = selection.isEmpty ? mine : selection.single;
                    if (tapped == PresenceStatus.away) {
                      _away(context).ignore();
                    } else {
                      choose(tapped).ignore();
                    }
                  }
                : null,
          ),
          const SizedBox(height: Dimens.gap),
        ],
        if (board.people.isEmpty)
          Text(l10n.presenceEmpty)
        else
          TileRows(
            items: board.people,
            rowHeight: TileRows.twoLineRowHeight + 8,
            reserved: (board.mine != null ? 104 : 0) + 28,
            minRows: 0,
            rowBuilder: (context, p) => ListTile(
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

/// My status in a small or strip tile (#226): three buttons that set it
/// with one tap; guests and kiosk displays, who cannot set one, see the
/// counts instead. Away is set without a day of return here; the detail
/// view asks for it.
class _QuickStatus extends StatelessWidget {
  const _QuickStatus({
    required this.board,
    required this.mine,
    required this.canSet,
    required this.choose,
    required this.size,
    this.off = false,
  });

  final PresenceBoard? board;
  final bool off;
  final PresenceStatus mine;
  final bool canSet;
  final ChooseStatus choose;
  final WidgetSize size;

  static const _icons = {
    PresenceStatus.office: Icons.business_outlined,
    PresenceStatus.home: Icons.home_outlined,
    PresenceStatus.away: Icons.flight_takeoff_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (off) return Text(l10n.presenceOff, maxLines: 2);
    final board = this.board;
    if (board == null) return const SizedBox.shrink();
    if (board.mine == null) {
      final c = board.counts;
      return Text(
        l10n.presenceCounts(
          c[PresenceStatus.office] ?? 0,
          c[PresenceStatus.home] ?? 0,
          c[PresenceStatus.away] ?? 0,
          c[PresenceStatus.none] ?? 0,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final MapEntry(key: status, value: icon) in _icons.entries)
          IconButton(
            key: ValueKey('presence.quick.${status.name}'),
            tooltip: presenceLabel(l10n, status),
            isSelected: mine == status,
            icon: Icon(icon),
            selectedIcon: Icon(icon),
            style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: canSet ? () => choose(status).ignore() : null,
          ),
      ],
    );
    final label = Text(
      presenceLabel(l10n, mine),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (size == WidgetSize.strip) {
      return Row(
        children: [
          Expanded(child: label),
          buttons,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        FittedBox(fit: BoxFit.scaleDown, child: buttons),
      ],
    );
  }
}
