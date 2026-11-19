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
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/ui/core/window_size.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/widget_card.dart';
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
  const _TabPage({required this.tab, required this.registry, this.webUrl});

  final DashboardTab tab;
  final WidgetRegistry registry;
  final Uri? webUrl;

  Widget _card(BuildContext context, WidgetPlacement widget) {
    final builder = registry.builderFor(widget.kind);
    return builder == null
        ? WidgetCard(widget: widget, webUrl: webUrl)
        : builder(context, widget);
  }

  @override
  Widget build(BuildContext context) {
    if (tab.widgets.isEmpty) return _Hint(context.l10n.dashboardEmptyTab);
    final columns = WindowSize.of(context).columns;
    return RefreshIndicator(
      // Reloads the widgets of this tab that are on screen (#19).
      onRefresh: () =>
          RefreshHost.maybeOf(context)?.refresh() ?? Future.value(),
      child: columns == 1
          ? ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              // Each tab keeps its own scroll position when swiping.
              key: PageStorageKey(tab.id),
              padding: const EdgeInsets.all(Dimens.gap),
              itemCount: tab.widgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: Dimens.gap),
              // Built lazily: a widget's view model, and with it its
              // request, only starts when the widget scrolls into view.
              itemBuilder: (context, i) => _card(context, tab.widgets[i]),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              key: PageStorageKey(tab.id),
              padding: const EdgeInsets.all(Dimens.gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: Dimens.gap),
                    Expanded(
                      // The phone order runs left to right, then down, so
                      // the first widgets stay at the top.
                      child: Column(
                        children: [
                          for (var i = c; i < tab.widgets.length; i += columns)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Dimens.gap,
                              ),
                              child: _card(context, tab.widgets[i]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
