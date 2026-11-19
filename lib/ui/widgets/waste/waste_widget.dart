import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/waste/waste_view_model.dart';

/// The native view of the waste collection widget (#49).
class WasteWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const WasteWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      WasteWidget(widget: widget, key: ValueKey(widget.id));

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
        // The server answers 404 while no waste calendar is set up.
        errorText: (error) =>
            error is ApiException && error.failure == ApiFailure.notFound
            ? l10n.wasteNotConfigured
            : null,
        builder: (context, collections) => collections.isEmpty
            ? Text(l10n.wasteEmpty)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in collections) _CollectionRow(collection: c),
                ],
              ),
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
          Expanded(child: Text(collection.label)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                when,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: collection.daysUntil <= 1
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
              if (next != null)
                Text(
                  DateFormat.MMMEd(locale).format(next),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
