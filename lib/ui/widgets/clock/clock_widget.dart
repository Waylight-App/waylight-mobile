import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_card.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_view_model.dart';

/// The native view of the clock widget (#62). It needs no request.
class ClockWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ClockWidget({required this.widget, super.key});

  /// The placement with the clock's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      ClockWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelHost(
      create: (context) => ClockViewModel(
        config: ClockConfig.fromJson(widget.config),
        locale: Localizations.localeOf(context).toLanguageTag(),
      ),
      builder: (context, viewModel) {
        final size = WidgetSizeScope.maybeOf(context);
        if (size != null && isCompact(size)) {
          return CompactCard(
            title: widget.displayTitle,
            size: size,
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => size == WidgetSize.strip
                  ? Text('${viewModel.time} · ${viewModel.date}')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            viewModel.time,
                            style: theme.textTheme.displaySmall,
                          ),
                        ),
                        Text(
                          viewModel.date,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          );
        }
        return SectionCard(
          title: widget.displayTitle,
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(viewModel.time, style: theme.textTheme.displaySmall),
                Text(viewModel.date, style: theme.textTheme.bodyLarge),
                if (viewModel.zone.isNotEmpty)
                  Text(
                    viewModel.zone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
