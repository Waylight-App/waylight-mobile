import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_card.dart';
import 'package:waylight_mobile/ui/core/widgets/compact_state_view.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Loads the compact state of one widget kind (#228).
class CompactStateViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  CompactStateViewModel({
    required this.kind,
    required this._serverRepository,
    this.config = const {},
    required this._compactRepository,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  /// The widget kind.
  final String kind;

  /// The widget's configuration, which derived states need (#242).
  final Map<String, Object?> config;

  final ServerRepository _serverRepository;
  final CompactStateRepository _compactRepository;

  /// Loads the state; run again to reload.
  late final Command0<CompactState> load;

  Future<Result<CompactState>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _compactRepository.state(server, kind, config: config);
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}

/// A widget in a small or strip tile, shown from the server's compact
/// state (#228) instead of its full view.
class CompactStateWidget extends StatelessWidget {
  /// Creates the tile of [widget] titled [title].
  const CompactStateWidget({
    required this.widget,
    required this.title,
    this.quickAction,
    super.key,
  });

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The title of the tile.
  final String title;

  /// One action right on the tile (#226), e.g. starting the focus timer.
  final Widget? quickAction;

  /// The compact state in small and strip tiles when the server offers one
  /// for the kind of [widget]; [full] everywhere else.
  static Widget orFull(
    BuildContext context,
    WidgetPlacement widget, {
    required String title,
    required Widget Function() full,
    Widget? quickAction,
  }) {
    final compact = context.read<CompactStateRepository?>();
    if (compact == null ||
        !isCompact(WidgetSizeScope.maybeOf(context)) ||
        !compact.supports(widget.kind, config: widget.config)) {
      return full();
    }
    return CompactStateWidget(
      widget: widget,
      title: title,
      quickAction: quickAction,
      key: ValueKey('compact.${widget.id}'),
    );
  }

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => CompactStateViewModel(
      kind: widget.kind,
      config: widget.config,
      serverRepository: context.read(),
      compactRepository: context.read(),
    ),
    builder: (context, viewModel) => WidgetFrame<CompactState>(
      title: title,
      load: viewModel.load,
      builder: (context, state) =>
          CompactStateView(state: state, size: WidgetSize.medium),
      compact: (context, state, size) {
        final view = CompactStateView(state: state, size: size);
        final action = quickAction;
        if (action == null) return view;
        return Row(
          children: [
            Expanded(child: view),
            action,
          ],
        );
      },
    ),
  );
}
