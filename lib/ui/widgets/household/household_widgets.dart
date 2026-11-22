import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/household/household_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/household.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/items_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';
import 'package:waylight_mobile/ui/widgets/household/meter_reading_dialog.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The native views of the family and household widgets: chores, meal
/// plan, gift ideas, family board, contracts, documents and meters.
///
/// They differ only in what they list and which quick action a row has, so
/// they share one list card ([_HouseholdList]); each kind adds its rows.
/// Small and strip tiles show the server's compact state, as for the other
/// widgets with one.
abstract final class HouseholdWidgets {
  /// The chore plan: whose turn it is, tick off what is due.
  static Widget chores(BuildContext context, WidgetPlacement widget) =>
      _HouseholdList<Chore>(
        placement: widget,
        title: context.l10n.choresTitle,
        empty: context.l10n.choresEmpty,
        fetch: (repo, server) => repo.chores(server),
        id: (c) => c.id,
        row: (context, vm, repo, chore) {
          final l10n = context.l10n;
          final due = chore.due;
          final when = switch (due) {
            _ when chore.overdue => l10n.choreOverdue,
            _ when chore.dueNow => l10n.choreToday,
            final day? => l10n.choreDue(shortDate(context, day)),
            null => '',
          };
          return ListTile(
            key: ValueKey('chores.${chore.id}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(chore.title),
            subtitle: Text(
              [if (chore.assignee.isNotEmpty) chore.assignee, when].join(' · '),
              style: chore.overdue
                  ? TextStyle(color: toneColor(context, Tone.critical))
                  : null,
            ),
            trailing: vm.canEdit && chore.dueNow
                ? IconButton(
                    key: ValueKey('chores.done.${chore.id}'),
                    tooltip: l10n.choreDoneAction(chore.title),
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => _act(
                      vm,
                      chore,
                      (server) => repo.markChoreDone(server, chore.id),
                    ).ignore(),
                  )
                : null,
          );
        },
      );

  /// The meal plan of the coming week.
  static Widget meals(BuildContext context, WidgetPlacement widget) =>
      _HouseholdList<Meal>(
        placement: widget,
        title: context.l10n.mealsTitle,
        empty: context.l10n.mealsEmpty,
        fetch: (repo, server) => repo.meals(server, from: DateTime.now()),
        id: (m) => m.id,
        row: (context, vm, repo, meal) {
          final l10n = context.l10n;
          final kind = switch (meal.meal) {
            'breakfast' => l10n.mealBreakfast,
            'lunch' => l10n.mealLunch,
            'dinner' => l10n.mealDinner,
            _ => '',
          };
          return InfoRow(
            key: ValueKey('meals.${meal.id}'),
            title: meal.dish,
            subtitle: [
              if (meal.date != null) shortDate(context, meal.date!),
              if (kind.isNotEmpty) kind,
            ].join(' · '),
          );
        },
      );

  /// The signed-in account's gift ideas; tick one when it is bought.
  static Widget gifts(BuildContext context, WidgetPlacement widget) =>
      _HouseholdList<GiftIdea>(
        placement: widget,
        title: context.l10n.giftsTitle,
        empty: context.l10n.giftsEmpty,
        fetch: (repo, server) async => switch (await repo.gifts(server)) {
          // By person, as the web shows them; the sort is stable.
          Ok(:final value) => Result.ok(
            [...value]..sort((a, b) => a.person.compareTo(b.person)),
          ),
          Error(:final error) => Result.error(error),
        },
        id: (g) => g.id,
        row: (context, vm, repo, idea) => CheckboxListTile(
          key: ValueKey('gifts.${idea.id}'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: idea.bought,
          onChanged: vm.canEdit
              ? (bought) => vm
                    .change(
                      idea,
                      idea.withBought(bought: bought ?? false),
                      (server) => repo.setGiftBought(
                        server,
                        idea,
                        bought: bought ?? false,
                      ),
                    )
                    .ignore()
              : null,
          title: Text(
            idea.title,
            style: idea.bought
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(idea.person),
        ),
      );

  /// The family board: pinned notes first.
  static Widget board(BuildContext context, WidgetPlacement widget) =>
      _HouseholdList<BoardNote>(
        placement: widget,
        title: context.l10n.boardTitle,
        empty: context.l10n.boardEmpty,
        fetch: (repo, server) => repo.board(server),
        id: (n) => n.id,
        row: (context, vm, repo, note) => ListTile(
          key: ValueKey('board.${note.id}'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: note.pinned
              ? Icon(
                  Icons.push_pin_outlined,
                  semanticLabel: context.l10n.boardPinned,
                )
              : null,
          title: Text(note.text),
          subtitle: note.expiresOn == null
              ? null
              : Text(
                  context.l10n.boardUntil(shortDate(context, note.expiresOn!)),
                ),
        ),
      );

  /// Contracts with their next cancellation deadline.
  static Widget contracts(BuildContext context, WidgetPlacement widget) {
    final currency = switch (widget.config['currency']) {
      final String c when c.isNotEmpty => c,
      _ => 'EUR',
    };
    return _HouseholdList<Contract>(
      placement: widget,
      title: context.l10n.contractsTitle,
      empty: context.l10n.contractsEmpty,
      fetch: (repo, server) => repo.contracts(server),
      id: (c) => c.id,
      row: (context, vm, repo, contract) {
        final l10n = context.l10n;
        final money = NumberFormat.simpleCurrency(
          locale: Localizations.localeOf(context).toLanguageTag(),
          name: currency,
        ).format(contract.monthlyCents / 100);
        final deadline = contract.deadline;
        return InfoRow(
          key: ValueKey('contracts.${contract.id}'),
          title: contract.name,
          subtitle: [
            if (contract.provider.isNotEmpty) contract.provider,
            if (!contract.open)
              l10n.contractEnded
            else if (deadline != null)
              l10n.contractCancelBy(shortDate(context, deadline)),
          ].join(' · '),
          trailing: l10n.contractPerMonth(money),
          trailingTone: contract.soon && contract.open ? Tone.warning : null,
        );
      },
    );
  }

  /// Documents with the state of their warranty.
  static Widget documents(BuildContext context, WidgetPlacement widget) =>
      _HouseholdList<DocumentRecord>(
        placement: widget,
        title: context.l10n.documentsTitle,
        empty: context.l10n.documentsEmpty,
        fetch: (repo, server) => repo.documents(server),
        id: (d) => d.id,
        row: (context, vm, repo, doc) {
          final l10n = context.l10n;
          final end = doc.warrantyEnd;
          final text = switch (doc.status) {
            WarrantyStatus.none => l10n.documentNoWarranty,
            WarrantyStatus.running => l10n.documentWarrantyUntil(
              shortDate(context, end!),
            ),
            WarrantyStatus.ending => l10n.documentWarrantyEnds(
              shortDate(context, end!),
            ),
            WarrantyStatus.ended => l10n.documentWarrantyEnded(
              shortDate(context, end!),
            ),
          };
          return InfoRow(
            key: ValueKey('documents.${doc.id}'),
            title: doc.title,
            subtitle: text,
            trailingTone: switch (doc.status) {
              WarrantyStatus.ending => Tone.warning,
              WarrantyStatus.ended => Tone.neutral,
              _ => null,
            },
          );
        },
      );

  /// Meters with their newest reading; add a reading from the phone.
  static Widget meters(BuildContext context, WidgetPlacement widget) =>
      _HouseholdList<Meter>(
        placement: widget,
        title: context.l10n.metersTitle,
        empty: context.l10n.metersEmpty,
        fetch: (repo, server) => repo.meters(server),
        id: (m) => m.id,
        row: (context, vm, repo, meter) {
          final l10n = context.l10n;
          final value = meter.lastValue;
          final day = meter.lastDay;
          return ListTile(
            key: ValueKey('meters.${meter.id}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(meter.name),
            subtitle: Text(
              value == null || day == null
                  ? l10n.meterNoReading
                  : l10n.meterLast(
                      [
                        NumberFormat.decimalPattern(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).format(value),
                        meter.unit,
                      ].where((s) => s.isNotEmpty).join(' '),
                      shortDate(context, day),
                    ),
            ),
            trailing: vm.canEdit
                ? IconButton(
                    key: ValueKey('meters.add.${meter.id}'),
                    tooltip: l10n.meterAddReading(meter.name),
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        _addReading(context, vm, repo, meter).ignore(),
                  )
                : null,
          );
        },
      );

  static Future<void> _addReading(
    BuildContext context,
    ItemsViewModel<Meter> vm,
    HouseholdRepository repo,
    Meter meter,
  ) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => MeterReadingDialog(meter: meter),
    );
    if (value == null) return;
    await _act(
      vm,
      meter,
      (server) =>
          repo.addReading(server, meter.id, day: DateTime.now(), value: value),
    );
  }

  /// Sends a change and reads the list again: the server decides what the
  /// record looks like afterwards (the next due day, the new reading).
  static Future<void> _act<T>(
    ItemsViewModel<T> vm,
    T item,
    Future<Result<void>> Function(ServerAddress server) send,
  ) async {
    await vm.change(item, item, send);
    await vm.load.execute();
  }
}

/// The card all household widgets share: a list of rows, a note when it is
/// empty, the server's compact state in small tiles.
class _HouseholdList<T> extends StatelessWidget {
  const _HouseholdList({
    required this.placement,
    required this.title,
    required this.empty,
    required this.fetch,
    required this.id,
    required this.row,
  });

  final WidgetPlacement placement;

  /// The title when the person gave the widget none.
  final String title;
  final String empty;
  final Future<Result<List<T>>> Function(
    HouseholdRepository repository,
    ServerAddress server,
  )
  fetch;
  final String Function(T item) id;
  final Widget Function(
    BuildContext context,
    ItemsViewModel<T> viewModel,
    HouseholdRepository repository,
    T item,
  )
  row;

  @override
  Widget build(BuildContext context) {
    final shown = placement.title.isNotEmpty ? placement.title : title;
    return CompactStateWidget.orFull(
      context,
      placement,
      title: shown,
      full: () => ItemsWidget<T>(
        key: ValueKey(placement.id),
        title: shown,
        create: (context) {
          final repository = context.read<HouseholdRepository>();
          return ItemsViewModel<T>(
            serverRepository: context.read(),
            fetch: (server) => fetch(repository, server),
            id: id,
          );
        },
        builder: (context, viewModel) {
          if (viewModel.items.isEmpty) return Text(empty);
          final repository = context.read<HouseholdRepository>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TileRows(
                items: viewModel.items,
                rowHeight: TileRows.twoLineRowHeight + 8,
                rowBuilder: (context, item) =>
                    row(context, viewModel, repository, item),
              ),
              const SizedBox(height: Dimens.gapTiny),
            ],
          );
        },
      ),
    );
  }
}
