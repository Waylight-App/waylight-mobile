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
import 'package:waylight_mobile/ui/core/widgets/compact_card.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/sized_grid.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/ui/core/window_size.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/arrange_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/arrange_view.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_card.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_detail_sheet.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_full_screen.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_grid.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Writes an NFC tag that opens the tab with the given id and name.
typedef TabTagWriter = Future<void> Function(
  BuildContext context,
  String tabId,
  String name,
);

/// The tabs of the dashboard, one page per tab (docs/design/screens/
/// dashboard.png).
class DashboardScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const DashboardScreen({
    required this.viewModel,
    required this.registry,
    this.writeTabTag,
    super.key,
  });

  /// Writes an NFC tag that opens a tab (#260); `null` where the phone
  /// cannot write tags. Handed in by the router, as the tag writer belongs
  /// to another feature.
  final TabTagWriter? writeTabTag;

  /// The state and actions of this screen.
  final DashboardViewModel viewModel;

  /// The native views by widget kind; other kinds get a [WidgetCard].
  final WidgetRegistry registry;

  /// Switches [tab] into the edit mode (#209), right on the dashboard.
  void _arrange(BuildContext context, DashboardTab tab) {
    Feedback.forLongPress(context).ignore();
    viewModel.arrange(tab);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
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
                TabPage(
                  tab: tab,
                  registry: registry,
                  webUrl: viewModel.webUrl(tab.id),
                  setUpNeedOf: viewModel.setUpNeedOf,
                  hidden: viewModel.isEmptyWidget,
                  onArrange: tab.mine ? () => _arrange(context, tab) : null,
                ),
            ],
          ),
        };
        final arranging = viewModel.arranging;
        // The key makes a reloaded dashboard with other tabs start fresh.
        return DefaultTabController(
          key: ValueKey(tabs.map((t) => t.id).join()),
          length: tabs.length,
          initialIndex: dashboard == null
              ? 0
              : viewModel.initialIndexIn(dashboard),
          child: arranging != null
              ? _ArrangeScaffold(
                  viewModel: viewModel,
                  arranging: arranging,
                  registry: registry,
                  writeTabTag: writeTabTag,
                )
              : Scaffold(
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
                                  onPressed: () => viewModel.arrange(tab),
                                );
                              },
                            );
                          },
                        ),
                      if (viewModel.attentionCount case final count
                          when count > 0)
                        IconButton(
                          key: const ValueKey('dashboard.attention'),
                          tooltip: l10n.attentionBadge(count),
                          icon: Badge.count(
                            count: count,
                            child: const Icon(Icons.error_outline),
                          ),
                          onPressed: () => context.push(Routes.attention),
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
                                  Localizations.localeOf(context)
                                      .toLanguageTag(),
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

/// The widgets of one tab, as on the dashboard; with [readOnly] (the wall
/// display, #193) tapping a widget opens nothing.
class TabPage extends StatelessWidget {
  /// Creates the page of [tab].
  const TabPage({
    required this.tab,
    required this.registry,
    this.webUrl,
    this.onArrange,
    this.setUpNeedOf,
    this.hidden,
    this.readOnly = false,
    super.key,
  });

  /// Widgets with nothing to show (#288); left out here and listed in the
  /// edit mode only.
  final bool Function(WidgetPlacement widget)? hidden;

  /// The widgets that show.
  List<WidgetPlacement> get _shown => [
    for (final w in tab.widgets)
      if (!(hidden?.call(w) ?? false)) w,
  ];

  /// What a widget misses before it can show anything (#230), or `null`
  /// when it is set up; such widgets show *Set up*.
  final String? Function(WidgetPlacement widget)? setUpNeedOf;

  /// Shows widgets without opening them in full.
  final bool readOnly;

  /// The tab to show.
  final DashboardTab tab;

  /// Builds the native views of the widgets.
  final WidgetRegistry registry;

  /// The tab in the web interface, for widgets without a native view.
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
    if (setUpNeedOf?.call(widget) case final message?) {
      return SetUpCard(widget: widget, message: message, webUrl: webUrl);
    }
    final builder = registry.builderFor(widget.kind);
    return builder == null
        ? WidgetCard(widget: widget, webUrl: webUrl)
        : builder(context, widget);
  }

  /// Small and strip tiles open the widget in a sheet over the dashboard
  /// (#226); larger tiles open it full screen.
  void _openTile(BuildContext context, WidgetPlacement widget) {
    if (readOnly) return;
    if (isCompact(tab.sizes[widget.id])) {
      WidgetDetailSheet.show(
        context,
        placement: widget,
        child: _card(context, widget),
      ).ignore();
    } else {
      _open(context, widget);
    }
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
    for (final widget in _shown) {
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
    if (_shown.isEmpty) return _Hint(context.l10n.dashboardNothingToShow);
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
            onOpen: (widget) => _openTile(context, widget),
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

/// The dashboard in its edit mode (docs/design: *Edit mode*): *Add widget*
/// on the left, the tab's name, *Done* on the right. Back leaves the edit
/// mode, after asking when there are changes.
class _ArrangeScaffold extends StatelessWidget {
  const _ArrangeScaffold({
    required this.viewModel,
    required this.arranging,
    required this.registry,
    this.writeTabTag,
  });

  final DashboardViewModel viewModel;
  final ArrangeViewModel arranging;
  final WidgetRegistry registry;
  final TabTagWriter? writeTabTag;

  /// Runs [command], then leaves the edit mode and shows the new layout;
  /// on an error the edit mode stays, with the message.
  Future<void> _finish(BuildContext context, Command0<void> command) async {
    await command.execute();
    if (!context.mounted) return;
    switch (command.result) {
      case Ok():
        viewModel.stopArranging(reload: true);
      case Error(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorMessage(error))),
        );
      case null:
        break;
    }
  }

  void _done(BuildContext context) {
    if (arranging.changed) {
      _finish(context, arranging.save).ignore();
    } else {
      viewModel.stopArranging();
    }
  }

  Future<void> _leave(BuildContext context) async {
    if (!arranging.changed) {
      viewModel.stopArranging();
      return;
    }
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editTabDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.editTabKeep),
          ),
          TextButton(
            key: const ValueKey('editTab.discard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.editTabDiscard),
          ),
        ],
      ),
    );
    // Widgets added from the gallery are on the server already, so the
    // dashboard reloads.
    if (discard ?? false) viewModel.stopArranging(reload: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([arranging.save, arranging.reset]),
      builder: (context, _) {
        final busy = arranging.save.running || arranging.reset.running;
        return PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave(context).ignore();
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leadingWidth: 160,
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: Dimens.gapSmall,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('editTab.add'),
                    icon: const Icon(Icons.add),
                    label: Text(
                      l10n.galleryOpen,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: busy
                        ? null
                        : () => WidgetGallerySheet.show(
                            context,
                            viewModel: arranging,
                            registry: registry,
                          ).ignore(),
                  ),
                ),
              ),
              centerTitle: true,
              title: Text(
                arranging.name.isEmpty ? l10n.editTabTitle : arranging.name,
              ),
              actions: [
                PopupMenuButton<void>(
                  key: const ValueKey('editTab.more'),
                  tooltip: l10n.editTabMore,
                  enabled: !busy,
                  itemBuilder: (context) => [
                    PopupMenuItem<void>(
                      key: const ValueKey('editTab.reset'),
                      onTap: () => _finish(context, arranging.reset).ignore(),
                      child: Text(l10n.editTabReset),
                    ),
                    if (writeTabTag case final write?)
                      PopupMenuItem<void>(
                        key: const ValueKey('editTab.tag'),
                        onTap: () => write(
                          context,
                          arranging.tabId,
                          arranging.name,
                        ).ignore(),
                        child: Text(l10n.tagWrite),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: Dimens.gapSmall,
                  ),
                  child: FilledButton(
                    key: const ValueKey('editTab.save'),
                    onPressed: busy ? null : () => _done(context),
                    child: Text(l10n.editTabDone),
                  ),
                ),
              ],
            ),
            body: ArrangeView(viewModel: arranging, registry: registry),
          ),
        );
      },
    );
  }
}
