import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/attention/view_models/attention_view_model.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/utils/result.dart';

/// *Needs your attention* (#229): connections that stopped working and
/// widgets that are not set up yet, each with the one action that
/// resolves it.
class AttentionScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const AttentionScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final AttentionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.attentionTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load]),
        builder: (context, _) {
          final broken = viewModel.broken;
          final setup = viewModel.setup;
          final load = viewModel.load;
          if (broken.isEmpty && setup.isEmpty) {
            return switch (load.result) {
              _ when load.running => const Center(
                child: CircularProgressIndicator(),
              ),
              Error(:final error) => FormPage(
                children: [
                  MessageBanner(
                    kind: MessageKind.error,
                    message: l10n.errorMessage(error),
                    action: TextButton(
                      key: const ValueKey('attention.retry'),
                      onPressed: () => load.execute().ignore(),
                      child: Text(l10n.dashboardRetry),
                    ),
                  ),
                ],
              ),
              _ => FormPage(
                children: [
                  MessageBanner(
                    key: const ValueKey('attention.empty'),
                    kind: MessageKind.info,
                    message: l10n.attentionEmpty,
                  ),
                ],
              ),
            };
          }
          return RefreshIndicator(
            onRefresh: load.execute,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimens.gap),
              children: [
                if (broken.isNotEmpty)
                  _Group(
                    title: l10n.attentionBroken,
                    items: broken,
                    viewModel: viewModel,
                  ),
                if (broken.isNotEmpty && setup.isNotEmpty)
                  const SizedBox(height: Dimens.gap),
                if (setup.isNotEmpty)
                  _Group(
                    title: l10n.attentionSetup,
                    items: setup,
                    viewModel: viewModel,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.items,
    required this.viewModel,
  });

  final String title;
  final List<AttentionItem> items;
  final AttentionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Dimens.gapSmall),
        for (final item in items)
          Card(
            child: _Entry(item: item, viewModel: viewModel),
          ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.item, required this.viewModel});

  final AttentionItem item;
  final AttentionViewModel viewModel;

  String _label(BuildContext context) {
    final l10n = context.l10n;
    return switch (item.action) {
      AttentionAction.signIn => l10n.attentionSignIn,
      AttentionAction.check => l10n.attentionCheck,
      AttentionAction.fix => l10n.attentionFix,
      AttentionAction.choose => l10n.attentionChoose,
      AttentionAction.connect => l10n.attentionConnect,
    };
  }

  Future<void> _run(BuildContext context) async {
    final l10n = context.l10n;
    switch (item.action) {
      case AttentionAction.check:
        final messenger = ScaffoldMessenger.of(context);
        await viewModel.check.execute(item.id);
        final message = switch (viewModel.check.result) {
          Ok(value: true) => l10n.attentionStillBroken,
          Error(:final error) => l10n.errorMessage(error),
          _ => null,
        };
        if (message != null) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
      // A widget's own setting is changed on the widget, which the app
      // shows on its tab.
      case AttentionAction.choose when item.tabId.isNotEmpty:
        context.go(
          Uri(
            path: Routes.home,
            queryParameters: {'tab': item.tabId},
          ).toString(),
        );
      case _:
        if (viewModel.webUrl(item) case final url?) {
          await openLink(context, url, l10n.linkOpenFailed);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Dimens.gap),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WidgetPlacement(id: '', kind: item.title).displayTitle,
                  style: theme.textTheme.titleSmall,
                ),
                if (item.message.isNotEmpty)
                  Text(
                    item.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Dimens.gapSmall),
          ListenableBuilder(
            listenable: viewModel.check,
            builder: (context, _) => FilledButton.tonal(
              key: ValueKey('attention.action.${item.id}'),
              onPressed: viewModel.check.running
                  ? null
                  : () => _run(context).ignore(),
              child: Text(_label(context)),
            ),
          ),
        ],
      ),
    );
  }
}
