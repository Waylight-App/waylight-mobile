import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';

import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/common/error_snack_listener.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';

/// The card of a widget built on [ItemsViewModel]: the shared frame, the
/// failure messages and a rebuild on every change.
class ItemsWidget<T> extends StatelessWidget {
  /// Creates the card.
  const ItemsWidget({
    required this.title,
    required this.create,
    required this.builder,
    this.compact,
    this.interval = const Duration(minutes: 5),
    super.key,
  });

  /// The title of the card.
  final String title;

  /// Creates the view model.
  final ItemsViewModel<T> Function(BuildContext context) create;

  /// Builds the content.
  final Widget Function(BuildContext context, ItemsViewModel<T> viewModel)
  builder;

  /// Builds the compact form for small and strip tiles (#211).
  final Widget Function(
    BuildContext context,
    ItemsViewModel<T> viewModel,
    WidgetSize size,
  )?
  compact;

  /// How often the list is reloaded.
  final Duration interval;

  @override
  Widget build(BuildContext context) => ViewModelHost<ItemsViewModel<T>>(
    create: create,
    builder: (context, viewModel) => WidgetFrame<void>(
      title: title,
      load: viewModel.load,
      interval: interval,
      compact: switch (compact) {
        final compact? => (context, _, size) => ErrorSnackListener(
          listenable: viewModel,
          takeError: viewModel.takeLastError,
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => compact(context, viewModel, size),
          ),
        ),
        null => null,
      },
      builder: (context, _) => ErrorSnackListener(
        listenable: viewModel,
        takeError: viewModel.takeLastError,
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => builder(context, viewModel),
        ),
      ),
    ),
  );
}
