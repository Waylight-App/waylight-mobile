import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Loads the data of one [WidgetQuery] for a widget card.
class RemoteWidgetViewModel<T> extends ChangeNotifier {
  /// Creates the view model and starts loading.
  RemoteWidgetViewModel({
    required this._server,
    required this._data,
    required this._query,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  final ServerRepository _server;
  final WidgetDataRepository _data;
  final WidgetQuery<T> _query;

  /// Loads the data; run again to reload.
  late final Command0<T> load;

  Future<Result<T>> _load() async {
    final server = _server.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _data.read(server, _query);
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}

/// The card of a read-only widget: one query, shown by [builder] in the
/// shared [WidgetFrame] (#99). Widgets with actions build their own view
/// model instead.
class RemoteWidget<T> extends StatelessWidget {
  /// Creates the card.
  const RemoteWidget({
    required this.title,
    required this.query,
    required this.builder,
    this.errorText,
    this.compact,
    this.interval = const Duration(minutes: 5),
    super.key,
  });

  /// The title of the card.
  final String title;

  /// What to load.
  final WidgetQuery<T> query;

  /// Builds the content from the data.
  final Widget Function(BuildContext context, T data) builder;

  /// See [WidgetFrame.errorText].
  final String? Function(Exception error)? errorText;

  /// See [WidgetFrame.compact].
  final Widget Function(BuildContext context, T data, WidgetSize size)? compact;

  /// How often the data is reloaded while shown.
  final Duration interval;

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => RemoteWidgetViewModel<T>(
      server: context.read(),
      data: context.read(),
      query: query,
    ),
    builder: (context, viewModel) => WidgetFrame<T>(
      title: title,
      load: viewModel.load,
      builder: builder,
      errorText: errorText,
      compact: compact,
      interval: interval,
    ),
  );
}
