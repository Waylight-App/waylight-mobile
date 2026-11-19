import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/widgets/common/remote_widget.dart';

/// A [RemoteWidget] for a placement: the user's title or [defaultTitle],
/// one query and a content builder. Most read-only widgets are one of
/// these.
class SimpleWidget<T> extends StatelessWidget {
  /// Creates the widget.
  const SimpleWidget({
    required this.placement,
    required this.defaultTitle,
    required this.query,
    required this.builder,
    this.interval = const Duration(minutes: 5),
    this.errorText,
    super.key,
  });

  /// The placement on the dashboard.
  final WidgetPlacement placement;

  /// The title when the user gave none.
  final String defaultTitle;

  /// What to load.
  final WidgetQuery<T> query;

  /// Builds the content.
  final Widget Function(BuildContext context, T data) builder;

  /// How often the data is reloaded.
  final Duration interval;

  /// See [RemoteWidget.errorText].
  final String? Function(Exception error)? errorText;

  @override
  Widget build(BuildContext context) => RemoteWidget<T>(
    title: placement.title.isNotEmpty ? placement.title : defaultTitle,
    query: query,
    builder: builder,
    interval: interval,
    errorText: errorText,
  );
}
