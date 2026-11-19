import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/auth_callback/view_models/auth_callback_view_model.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Shows the end of a sign-in in the browser and what went wrong (#45).
class AuthCallbackScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const AuthCallbackScreen({required this.viewModel, super.key});

  /// The state of this screen.
  final AuthCallbackViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: FormPage(
        children: [
          const Wordmark(large: true),
          const SizedBox(height: Dimens.gapLarge),
          Text(
            l10n.authCallbackTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Dimens.gapLarge),
          ListenableBuilder(
            listenable: viewModel.finish,
            builder: (context, _) => switch (viewModel.finish.result) {
              Error(:final error) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MessageBanner(
                    kind: error is SignInCancelled
                        ? MessageKind.info
                        : MessageKind.error,
                    message: callbackError(l10n, error),
                  ),
                  const SizedBox(height: Dimens.gap),
                  OutlinedButton(
                    key: const ValueKey('auth.back'),
                    onPressed: () => context.go(Routes.signIn),
                    child: Text(l10n.authCallbackBack),
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

/// The message for a failed browser sign-in.
@visibleForTesting
String callbackError(AppLocalizations l10n, Exception error) => switch (error) {
  SignInCancelled() => l10n.authCallbackCancelled,
  UnexpectedSignIn() => l10n.authCallbackUnexpected,
  _ => l10n.errorMessage(error),
};
