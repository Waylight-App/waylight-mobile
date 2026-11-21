import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/tag/view_models/tag_action_view_model.dart';

/// Runs the action of an NFC tag (#195) and says what happened. The router
/// only shows it once the app is unlocked and signed in.
class TagActionScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const TagActionScreen({required this.viewModel, super.key});

  /// The state of the action.
  final TagActionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagTitle)),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(Dimens.gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (viewModel.state) {
                TagRunState.working => const Center(
                  child: CircularProgressIndicator(),
                ),
                TagRunState.confirm => Text(
                  l10n.tagConfirm(viewModel.subject),
                  key: const ValueKey('tag.confirmText'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TagRunState.done => MessageBanner(
                  kind: MessageKind.info,
                  message: _done(l10n),
                ),
                TagRunState.failed => MessageBanner(
                  kind: MessageKind.error,
                  message: viewModel.action == null
                      ? l10n.tagUnknown
                      : l10n.errorMessage(viewModel.error!),
                ),
              },
              const SizedBox(height: Dimens.gap),
              if (viewModel.state == TagRunState.confirm)
                FilledButton(
                  key: const ValueKey('tag.confirm'),
                  onPressed: () => viewModel.confirm().ignore(),
                  child: Text(l10n.tagConfirmAction),
                ),
              if (viewModel.state != TagRunState.working)
                TextButton(
                  key: const ValueKey('tag.close'),
                  onPressed: () => context.go(Routes.home),
                  child: Text(
                    viewModel.state == TagRunState.confirm
                        ? MaterialLocalizations.of(context).cancelButtonLabel
                        : l10n.tagClose,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _done(AppLocalizations l10n) => switch (viewModel.outcome) {
    TagOutcome.ticked => l10n.tagTicked(viewModel.subject),
    TagOutcome.alreadyDone => l10n.tagAlreadyDone(viewModel.subject),
    TagOutcome.switched => l10n.tagSwitched(viewModel.subject),
    TagOutcome.pressed => l10n.tagPressed(viewModel.subject),
    TagOutcome.added || null => l10n.tagAdded(viewModel.subject),
  };
}
