import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_lines.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The native view of the waste collection widget (#49).
class WasteWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const WasteWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      WasteWidget(widget: widget, key: ValueKey(widget.id));

  static bool _notConfigured(Exception error) =>
      error is ApiException && error.failure == ApiFailure.notFound;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ViewModelHost(
      create: (context) => WasteViewModel(
        serverRepository: context.read(),
        wasteRepository: context.read(),
      ),
      builder: (context, viewModel) => WidgetFrame(
        title: widget.title.isNotEmpty ? widget.title : l10n.wasteTitle,
        load: viewModel.load,
        interval: const Duration(hours: 6),
        // The server answers 404 while no waste calendar is set up.
        errorText: (error) =>
            _notConfigured(error) ? l10n.wasteNotConfigured : null,
        setUp: (error) => _notConfigured(error)
            ? (
                message: l10n.wasteNotConfigured,
                onSetUp: () => showDialog<void>(
                  context: context,
                  builder: (context) => _SubscribeDialog(viewModel: viewModel),
                ).ignore(),
              )
            : null,
        compact: (context, collections, size) {
          if (collections.isEmpty) return Text(l10n.wasteEmpty);
          final next = collections.reduce(
            (a, b) => b.daysUntil < a.daysUntil ? b : a,
          );
          return CompactLines(
            headline: '${next.icon} ${next.label}'.trim(),
            detail: daysText(context, next.daysUntil),
            size: size,
          );
        },
        builder: (context, collections) => collections.isEmpty
            ? Text(l10n.wasteEmpty)
            : TileRows(
                items: collections,
                rowHeight: TileRows.twoLineRowHeight,
                rowBuilder: (context, c) => _CollectionRow(collection: c),
              ),
      ),
    );
  }
}

/// Asks for the address of a waste calendar and subscribes to it (#230);
/// the server loads it first, so a wrong address is reported here.
class _SubscribeDialog extends StatefulWidget {
  const _SubscribeDialog({required this.viewModel});

  final WasteViewModel viewModel;

  @override
  State<_SubscribeDialog> createState() => _SubscribeDialogState();
}

class _SubscribeDialogState extends State<_SubscribeDialog> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final subscribe = widget.viewModel.subscribe;
    await subscribe.execute(_url.text);
    if (!mounted) return;
    if (subscribe.result is Ok<void>) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subscribe = widget.viewModel.subscribe;
    return ListenableBuilder(
      listenable: subscribe,
      builder: (context, _) => AlertDialog(
        title: Text(l10n.setUpWasteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.setUpWasteHint),
            const SizedBox(height: Dimens.gap),
            TextField(
              key: const ValueKey('waste.url'),
              controller: _url,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.setUpWasteLabel,
                errorText: switch (subscribe.result) {
                  Error(:final error) => l10n.errorMessage(error),
                  _ => null,
                },
                errorMaxLines: 3,
              ),
              onSubmitted: (_) => _save().ignore(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.setUpCancel),
          ),
          FilledButton(
            key: const ValueKey('waste.save'),
            onPressed: subscribe.running ? null : () => _save().ignore(),
            child: Text(l10n.setUpSave),
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.collection});

  final WasteCollection collection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final next = collection.dates.isEmpty ? null : collection.dates.first;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = switch (collection.daysUntil) {
      0 => l10n.todosToday,
      1 => l10n.todosTomorrow,
      final days => l10n.wasteInDays(days),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
      child: Row(
        children: [
          SizedBox(
            width: Dimens.iconLarge,
            child: Text(
              collection.icon,
              style: theme.textTheme.titleLarge,
              semanticsLabel: '',
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              collection.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: collection.daysUntil <= 1
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
                if (next != null)
                  Text(
                    DateFormat.MMMEd(locale).format(next),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
