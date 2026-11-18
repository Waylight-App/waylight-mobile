import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Asks for account name, password and, if needed, the second factor
/// (docs/design/screens/sign-in.png and two-factor.png).
class SignInScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const SignInScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final SignInViewModel viewModel;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.signIn.addListener(_clearSecretsOnError);
  }

  @override
  void dispose() {
    widget.viewModel.signIn.removeListener(_clearSecretsOnError);
    _username.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  // A rejected password or code is not kept in the field (#12).
  void _clearSecretsOnError() {
    if (widget.viewModel.signIn.error) {
      _password.clear();
      _code.clear();
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final input = (
      username: _username.text,
      password: _password.text,
      code: _code.text,
    );
    widget.viewModel.signIn.execute(input).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;
    return Scaffold(
      body: FormPage(
        children: [
          const Wordmark(large: true),
          const SizedBox(height: Dimens.gapLarge),
          Text(l10n.signInTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: Dimens.gapSmall),
          Text(
            l10n.signInServer(viewModel.server),
            style: theme.textTheme.bodyLarge,
          ),
          if (viewModel.expired) ...[
            const SizedBox(height: Dimens.gap),
            MessageBanner(kind: MessageKind.info, message: l10n.signInExpired),
          ],
          const SizedBox(height: Dimens.gapLarge),
          ListenableBuilder(
            listenable: Listenable.merge([viewModel, viewModel.signIn]),
            builder: (context, _) {
              final running = viewModel.signIn.running;
              final step = viewModel.codeRequired;
              final error = switch (viewModel.signIn.result) {
                Error(:final error) => signInError(l10n, error, step != null),
                _ => null,
              };
              return AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('signIn.username'),
                      controller: _username,
                      enabled: !running,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.signInUsernameLabel,
                        helperText: l10n.signInUsernameHelper,
                      ),
                    ),
                    const SizedBox(height: Dimens.gap),
                    TextField(
                      key: const ValueKey('signIn.password'),
                      controller: _password,
                      enabled: !running,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: step == null
                          ? TextInputAction.go
                          : TextInputAction.next,
                      onSubmitted: step == null ? (_) => _submit() : null,
                      decoration: InputDecoration(
                        labelText: l10n.signInPasswordLabel,
                      ),
                    ),
                    if (step != null) ...[
                      const SizedBox(height: Dimens.gap),
                      TextField(
                        key: const ValueKey('signIn.code'),
                        controller: _code,
                        enabled: !running,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.signInCodeLabel,
                          helperText: step.authenticatorApp
                              ? l10n.signInCodeHint
                              : l10n.signInCodeHintRecovery,
                        ),
                      ),
                    ],
                    const SizedBox(height: Dimens.gap),
                    CommandButton(
                      key: const ValueKey('signIn.submit'),
                      command: viewModel.signIn,
                      onPressed: _submit,
                      label: l10n.signInButton,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: Dimens.gap),
                      MessageBanner(kind: MessageKind.error, message: error),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Dimens.gapLarge),
          CommandButton(
            key: const ValueKey('signIn.otherServer'),
            command: viewModel.useAnotherServer,
            onPressed: () => viewModel.useAnotherServer.execute().ignore(),
            label: l10n.homeDisconnect,
            variant: CommandButtonVariant.text,
          ),
        ],
      ),
    );
  }
}

/// The message for a failed sign-in; [withCode] is true in the second
/// step, where a 401 can also mean a wrong code.
@visibleForTesting
String signInError(AppLocalizations l10n, Exception error, bool withCode) =>
    switch (error) {
      ApiException(failure: ApiFailure.unauthorized) =>
        withCode ? l10n.signInErrorCode : l10n.signInErrorCredentials,
      // The login answers 403 while the server waits for its first account.
      ApiException(failure: ApiFailure.forbidden) => l10n.homeSetupRequired,
      _ => l10n.errorMessage(error),
    };
