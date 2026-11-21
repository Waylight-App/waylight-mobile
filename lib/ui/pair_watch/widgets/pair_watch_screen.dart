import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/watch_link.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/pair_watch/view_models/pair_watch_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Pairs a Wear OS watch (#239): scan its QR code, check the address,
/// hand the server over and show the watch's answer.
class PairWatchScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const PairWatchScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final PairWatchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pairWatchTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Dimens.maxPageWidth),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              viewModel,
              viewModel.scan,
              viewModel.pair,
            ]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(Dimens.gap),
              children: [
                Text(l10n.pairWatchIntro),
                const SizedBox(height: Dimens.gap),
                if (!viewModel.available)
                  MessageBanner(
                    kind: MessageKind.info,
                    message: l10n.pairWatchUnavailable,
                  )
                else
                  ..._steps(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _steps(BuildContext context) {
    final l10n = context.l10n;
    final watch = viewModel.watch;
    return [
      if (viewModel.scan.result case Error(:final error)) ...[
        MessageBanner(
          kind: MessageKind.error,
          message: pairWatchError(l10n, error),
        ),
        const SizedBox(height: Dimens.gap),
      ],
      if (viewModel.pair.result case Ok()) ...[
        MessageBanner(kind: MessageKind.info, message: l10n.pairWatchDone),
        const SizedBox(height: Dimens.gap),
      ],
      if (viewModel.pair.result case Error(:final error)) ...[
        MessageBanner(
          kind: MessageKind.error,
          message: pairWatchError(l10n, error),
        ),
        const SizedBox(height: Dimens.gap),
      ],
      if (watch != null) ...[
        Text(
          l10n.pairWatchFound(watch.address),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Dimens.gapSmall),
        CommandButton(
          key: const ValueKey('pairWatch.pair'),
          command: viewModel.pair,
          onPressed: () => viewModel.pair.execute().ignore(),
          label: l10n.pairWatchSend,
        ),
        const SizedBox(height: Dimens.gapSmall),
      ],
      CommandButton(
        key: const ValueKey('pairWatch.scan'),
        command: viewModel.scan,
        onPressed: () =>
            viewModel.scan.execute(l10n.pairWatchScanPrompt).ignore(),
        label: watch == null ? l10n.pairWatchScan : l10n.pairWatchScanAgain,
        variant: watch == null
            ? CommandButtonVariant.filled
            : CommandButtonVariant.outlined,
      ),
    ];
  }
}

/// The message for a failed scan or handover.
@visibleForTesting
String pairWatchError(AppLocalizations l10n, Exception error) =>
    switch (error) {
      WatchPairingException(:final failure) => switch (failure) {
        WatchPairingFailure.invalidCode => l10n.pairWatchInvalidCode,
        WatchPairingFailure.unsupported => l10n.pairWatchUnavailable,
        WatchPairingFailure.watchUnreachable => l10n.pairWatchUnreachable,
        WatchPairingFailure.notDecryptable => l10n.pairWatchNotDecryptable,
        WatchPairingFailure.rejected => l10n.pairWatchRejected,
        WatchPairingFailure.invalidServer => l10n.pairWatchInvalidServer,
        WatchPairingFailure.serverUnreachable =>
          l10n.pairWatchServerUnreachable,
      },
      _ => l10n.errorMessage(error),
    };
