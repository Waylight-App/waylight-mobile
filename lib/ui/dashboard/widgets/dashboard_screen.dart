import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
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
              for (final tab in tabs) _TabPage(tab: tab, registry: registry),
            ],
          ),
        };
        // The key makes a reloaded dashboard with other tabs start fresh.
        return DefaultTabController(
          key: ValueKey(tabs.map((t) => t.id).join()),
          length: tabs.length,
          initialIndex: dashboard?.initialIndex ?? 0,
          child: Scaffold(
            appBar: AppBar(
              title: const Wordmark(),
              actions: [_AccountMenu(viewModel: viewModel)],
              bottom: tabs.length < 2
                  ? null
                  : TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [for (final tab in tabs) Tab(text: tab.name)],
                    ),
            ),
            body: body,
          ),
        );
      },
    );
  }
}

class _TabPage extends StatelessWidget {
  const _TabPage({required this.tab, required this.registry});

  final DashboardTab tab;
  final WidgetRegistry registry;

  @override
  Widget build(BuildContext context) {
    if (tab.widgets.isEmpty) return _Hint(context.l10n.dashboardEmptyTab);
    return ListView.separated(
      // Each tab keeps its own scroll position when swiping between tabs.
      key: PageStorageKey(tab.id),
      padding: const EdgeInsets.all(Dimens.gap),
      itemCount: tab.widgets.length,
      separatorBuilder: (_, _) => const SizedBox(height: Dimens.gap),
      // Built lazily: a widget's view model, and with it its request, only
      // starts when the widget scrolls into view.
      itemBuilder: (context, i) {
        final widget = tab.widgets[i];
        final builder = registry.builderFor(widget.kind);
        return builder == null
            ? WidgetCard(widget: widget)
            : builder(context, widget);
      },
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

enum _AccountAction { signOut, disconnect }

/// Sign out and server change, until the settings screen (#14) takes them.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_AccountAction>(
      key: const ValueKey('dashboard.menu'),
      tooltip: l10n.dashboardMenu,
      onSelected: (action) => switch (action) {
        _AccountAction.signOut => viewModel.signOut.execute().ignore(),
        _AccountAction.disconnect => viewModel.disconnect.execute().ignore(),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const ValueKey('dashboard.signOut'),
          value: _AccountAction.signOut,
          child: Text(l10n.homeSignOut),
        ),
        PopupMenuItem(
          key: const ValueKey('dashboard.disconnect'),
          value: _AccountAction.disconnect,
          child: Text(l10n.homeDisconnect),
        ),
      ],
    );
  }
}
