import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/refresh.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/sized_grid.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/ui/core/window_size.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_card.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_full_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_grid.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The tabs of the dashboard, one page per tab (docs/design/screens/
/// dashboard.png).
class DashboardScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const DashboardScreen({
    required this.viewModel,
    required this.registry,
    super.key,
  });

  /// The state and actions of this screen.
  final DashboardViewModel viewModel;

  /// The native views by widget kind; other kinds get a [WidgetCard].
  final WidgetRegistry registry;

  /// Opens the edit mode of [tab] (#209) and reloads after saving.
  Future<void> _arrange(BuildContext context, DashboardTab tab) async {
    final saved = await context.push<bool>(
      Uri(path: Routes.editTab, queryParameters: {'tab': tab.id}).toString(),
    );
    if (saved ?? false) viewModel.load.execute().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: viewModel.load,
      builder: (context, _) {
        final dashboard = switch (viewModel.load.result) {
          Ok(:final value) => value,
          _ => null,
        };
        final tabs = dashboard?.tabs ?? const <DashboardTab>[];
        final body = switch (viewModel.load.result) {
          _ when viewModel.load.running && dashboard == null => const Center(
            child: CircularProgressIndicator(),
          ),
          Error(:final error) => FormPage(
            children: [
              MessageBanner(
                kind: MessageKind.error,
                message: l10n.errorMessage(error),
                action: TextButton(
                  key: const ValueKey('dashboard.retry'),
                  onPressed: () => viewModel.load.execute().ignore(),
                  child: Text(l10n.dashboardRetry),
                ),
              ),
            ],
          ),
          _ when tabs.isEmpty => _Hint(l10n.dashboardNoTabs),
          _ => TabBarView(
            children: [
              for (final tab in tabs)
                _TabPage(
                  tab: tab,
                  registry: registry,
                  webUrl: viewModel.webUrl(tab.id),
                  onArrange: tab.mine ? () => _arrange(context, tab) : null,
                ),
            ],
          ),
        };
        // The key makes a reloaded dashboard with other tabs start fresh.
        return DefaultTabController(
          key: ValueKey(tabs.map((t) => t.id).join()),
          length: tabs.length,
          initialIndex: dashboard == null
              ? 0
              : viewModel.initialIndexIn(dashboard),
          child: Scaffold(
            appBar: AppBar(
              title: const Wordmark(),
              actions: [
                if (tabs.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final controller = DefaultTabController.of(context);
                      return ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) {
                          final tab = tabs[controller.index];
                          if (!tab.mine) return const SizedBox.shrink();
                          return IconButton(
                            key: const ValueKey('dashboard.edit'),
                            tooltip: l10n.editTabTitle,
                            icon: const Icon(
                              Icons.dashboard_customize_outlined,
                            ),
                            onPressed: () => _arrange(context, tab),
                          );
                        },
                      );
                    },
                  ),
                IconButton(
                  key: const ValueKey('dashboard.search'),
                  tooltip: l10n.searchHint,
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push(Routes.search),
                ),
                IconButton(
                  key: const ValueKey('dashboard.settings'),
                  tooltip: l10n.settingsTitle,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(Routes.settings),
                ),
              ],
              bottom: tabs.length < 2
                  ? null
                  : TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [for (final tab in tabs) Tab(text: tab.name)],
                    ),
            ),
            body: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => Column(
                children: [
                  if (viewModel.offlineSince case final since?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimens.gap,
                        Dimens.gapSmall,
                        Dimens.gap,
                        0,
                      ),
                      child: MessageBanner(
                        key: const ValueKey('dashboard.offline'),
                        kind: MessageKind.warning,
                        message: l10n.dashboardOffline(
                          DateFormat.Hm(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(since.toLocal()),
                        ),
                      ),
                    ),
                  if (viewModel.demo)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimens.gap,
                        Dimens.gapSmall,
                        Dimens.gap,
                        0,
                      ),
                      child: MessageBanner(
                        key: const ValueKey('dashboard.demo'),
                        kind: MessageKind.info,
                        message: l10n.dashboardDemo,
                      ),
                    ),
                  Expanded(child: RefreshHost(child: body)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabPage extends StatelessWidget {
  const _TabPage({
    required this.tab,
    required this.registry,
    this.webUrl,
    this.onArrange,
  });

  final DashboardTab tab;
  final WidgetRegistry registry;
  final Uri? webUrl;

  /// Opens the edit mode; `null` for tabs the account may not change.
  final VoidCallback? onArrange;

  /// A widget without a size: its view, held to open the edit mode.
  Widget _unsized(BuildContext context, WidgetPlacement widget) =>
      GestureDetector(
        onLongPress: onArrange,
        excludeFromSemantics: true,
        child: _card(context, widget),
      );

  Widget _card(BuildContext context, WidgetPlacement widget) {
    final builder = registry.builderFor(widget.kind);
    return builder == null
        ? WidgetCard(widget: widget, webUrl: webUrl)
        : builder(context, widget);
  }

  void _open(BuildContext context, WidgetPlacement widget) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => WidgetFullScreen(
              placement: widget,
              child: _card(context, widget),
            ),
          ),
        )
        .ignore();
  }

  /// The tab's widgets as runs: widgets with a size go into one grid,
  /// widgets without one stay full width at their natural height (#208).
  List<List<WidgetPlacement>> _runs() {
    final runs = <List<WidgetPlacement>>[];
    bool? sized;
    for (final widget in tab.widgets) {
      final isSized = tab.sizes.containsKey(widget.id);
      if (isSized != sized) runs.add([]);
      runs.last.add(widget);
      sized = isSized;
    }
    return runs;
  }

  @override
  Widget build(BuildContext context) {
    if (tab.widgets.isEmpty) return _Hint(context.l10n.dashboardEmptyTab);
    final window = WindowSize.of(context);
    final columns = window.columns;
    final gridColumns = SizedGrid.columnsOf(context);
    final blocks = <Widget>[];
    for (final run in _runs()) {
      if (tab.sizes.containsKey(run.first.id)) {
        blocks.add(
          WidgetGrid(
            items: [
              for (final widget in run)
                (widget: widget, size: tab.sizes[widget.id]!),
            ],
            columns: gridColumns,
            builder: _card,
            onOpen: (widget) => _open(context, widget),
            onArrange: onArrange,
          ),
        );
      } else if (columns == 1) {
        // One block per widget keeps the list lazy: a widget's view model,
        // and with it its request, only starts when it scrolls into view.
        blocks.addAll([for (final widget in run) _unsized(context, widget)]);
      } else {
        blocks.add(_Columns(widgets: run, columns: columns, card: _unsized));
      }
    }
    return RefreshIndicator(
      // Reloads the widgets of this tab that are on screen (#19).
      onRefresh: () =>
          RefreshHost.maybeOf(context)?.refresh() ?? Future.value(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // Each tab keeps its own scroll position when swiping.
        key: PageStorageKey(tab.id),
        padding: const EdgeInsets.all(Dimens.gap),
        itemCount: blocks.length,
        separatorBuilder: (_, _) => const SizedBox(height: Dimens.gap),
        itemBuilder: (context, i) => blocks[i],
      ),
    );
  }
}

/// Widgets without a size on tablets: side by side in [columns] columns.
class _Columns extends StatelessWidget {
  const _Columns({
    required this.widgets,
    required this.columns,
    required this.card,
  });

  final List<WidgetPlacement> widgets;
  final int columns;
  final PlacementBuilder card;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) const SizedBox(width: Dimens.gap),
          Expanded(
            // The phone order runs left to right, then down, so the first
            // widgets stay at the top.
            child: Column(
              children: [
                for (var i = c; i < widgets.length; i += columns)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i + columns < widgets.length ? Dimens.gap : 0,
                    ),
                    child: card(context, widgets[i]),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => FormPage(
    children: [MessageBanner(kind: MessageKind.info, message: text)],
  );
}
