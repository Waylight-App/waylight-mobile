import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/ui/pair/view_models/pair_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Shows the pairing from a QR code and what went wrong (#43).
class PairScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const PairScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final PairViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: FormPage(
        children: [
          const Wordmark(large: true),
          const SizedBox(height: Dimens.gapLarge),
          Text(
            l10n.pairTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Dimens.gapLarge),
          ListenableBuilder(
            listenable: viewModel.pair,
            builder: (context, _) => switch (viewModel.pair.result) {
              Error(:final error) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MessageBanner(
                    kind: MessageKind.error,
                    message: pairError(l10n, error),
                  ),
                  const SizedBox(height: Dimens.gap),
                  CommandButton(
                    key: const ValueKey('pair.manual'),
                    command: viewModel.disconnect,
                    // The pairing route opens without a server, so the
                    // connect screen has to be opened explicitly.
                    onPressed: () async {
                      await viewModel.disconnect.execute();
                      if (context.mounted) context.go(Routes.connect);
                    },
                    label: l10n.pairEnterManually,
                    variant: CommandButtonVariant.outlined,
                  ),
                ],
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// The message for a failed pairing.
@visibleForTesting
String pairError(AppLocalizations l10n, Exception error) => switch (error) {
  InvalidPairingLink() || InvalidServerAddress() => l10n.pairInvalidLink,
  ApiException(failure: ApiFailure.unauthorized) => l10n.pairCodeInvalid,
  _ => l10n.errorMessage(error),
};
