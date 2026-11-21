import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/compact/compact_state_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/compact_state.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/compact_texts.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
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
    act = Command1(_act);
  }

  /// The widget kind.
  final String kind;

  /// The widget's configuration, which derived states need (#242).
  final Map<String, Object?> config;

  final ServerRepository _serverRepository;
  final CompactStateRepository _compactRepository;

  /// Loads the state; run again to reload.
  late final Command0<CompactState> load;

  /// Runs the state's action, with one of its choices, and reloads.
  late final Command1<void, (CompactAction, CompactChoice?)> act;

  Future<Result<void>> _act((CompactAction, CompactChoice?) request) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final (action, choice) = request;
    final result = await _compactRepository.run(server, action, choice: choice);
    if (result is Ok) await load.execute();
    return result;
  }

  Future<Result<CompactState>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _compactRepository.state(server, kind, config: config);
  }

  @override
  void dispose() {
    load.dispose();
    act.dispose();
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

  /// One action right on the tile (#226), e.g. starting the focus timer;
  /// without it the tile offers the action of the server's state.
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
        final own = quickAction;
        final server = state.action;
        if (own != null) {
          return Row(
            children: [
              Expanded(child: view),
              own,
            ],
          );
        }
        if (server == null) return view;
        final action = _ServerAction(action: server, viewModel: viewModel);
        // A labelled button next to the text leaves a small tile too little
        // width, so it goes below there; strips have the width but not the
        // height.
        if (size == WidgetSize.strip) {
          return Row(
            children: [
              Expanded(child: view),
              action,
            ],
          );
        }
        // The button says what happens next, which leaves no room for
        // the detail line in a small tile.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: CompactStateView(
                state: state,
                size: size,
                showDetail: false,
              ),
            ),
            action,
          ],
        );
      },
    ),
  );
}

/// The action of the server's compact state (#226): a button, or a menu
/// when the action offers choices, such as the presence states.
class _ServerAction extends StatelessWidget {
  const _ServerAction({required this.action, required this.viewModel});

  final CompactAction action;
  final CompactStateViewModel viewModel;

  Future<void> _run(BuildContext context, CompactChoice? choice) async {
    await viewModel.act.execute((action, choice));
    if (!context.mounted) return;
    if (viewModel.act.result case Error(:final error)) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(context.l10n.errorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = compactTextOf(l10n, action.label);
    return ListenableBuilder(
      listenable: viewModel.act,
      builder: (context, _) {
        final running = viewModel.act.running;
        if (action.choices.isEmpty) {
          return TextButton(
            key: ValueKey('compact.action.${action.id}'),
            onPressed: running ? null : () => _run(context, null),
            child: Text(label, maxLines: 1),
          );
        }
        return PopupMenuButton<CompactChoice>(
          key: ValueKey('compact.action.${action.id}'),
          tooltip: label,
          enabled: !running,
          icon: const Icon(Icons.more_horiz),
          onSelected: (choice) => _run(context, choice),
          itemBuilder: (context) => [
            for (final c in action.choices)
              CheckedPopupMenuItem(
                value: c,
                checked: c.selected,
                child: Text(compactTextOf(l10n, c.label)),
              ),
          ],
        );
      },
    );
  }
}
