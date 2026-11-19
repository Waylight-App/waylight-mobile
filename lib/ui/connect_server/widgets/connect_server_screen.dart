import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/themes/status_colors.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Asks for the address of the Waylight server (docs/design/README.md).
///
/// Navigation after a successful connection is done by the router, which
/// listens to the server repository.
class ConnectServerScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const ConnectServerScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final ConnectServerViewModel viewModel;

  @override
  State<ConnectServerScreen> createState() => _ConnectServerScreenState();
}

class _ConnectServerScreenState extends State<ConnectServerScreen> {
  final _address = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.viewModel.connect.execute(_address.text).ignore();
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
          Text(l10n.connectTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: Dimens.gapSmall),
          Text(l10n.connectIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Dimens.gapLarge),
          ListenableBuilder(
            listenable: Listenable.merge([viewModel, viewModel.connect]),
            builder: (context, _) {
              final error = switch (viewModel.connect.result) {
                Error(:final error) => error,
                _ => null,
              };
              final banner = error == null ? null : bannerError(l10n, error);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('connect.address'),
                    controller: _address,
                    enabled: !viewModel.connect.running,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onChanged: viewModel.onAddressChanged,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.connectAddressLabel,
                      hintText: l10n.connectAddressHint,
                      errorText: error == null ? null : fieldError(l10n, error),
                      helperText: viewModel.insecure
                          ? l10n.connectInsecureWarning
                          : null,
                      helperStyle: TextStyle(
                        color: StatusColors.of(context).warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimens.gap),
                  CommandButton(
                    key: const ValueKey('connect.submit'),
                    command: viewModel.connect,
                    onPressed: _submit,
                    label: l10n.connectButton,
                  ),
                  if (banner != null) ...[
                    const SizedBox(height: Dimens.gap),
                    MessageBanner(kind: MessageKind.error, message: banner),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: Dimens.gap),
          Text(l10n.connectQrHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Dimens.gapLarge),
          Text(
            l10n.connectPrivacy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The message shown at the address field, for input the app rejects
/// itself; `null` for every other error.
@visibleForTesting
String? fieldError(AppLocalizations l10n, Exception error) => switch (error) {
  InvalidServerAddress(:final reason) => switch (reason) {
    InvalidServerAddressReason.empty => l10n.connectErrorEmpty,
    InvalidServerAddressReason.malformed => l10n.connectErrorInvalid,
    InvalidServerAddressReason.unsupportedScheme => l10n.connectErrorScheme,
    InvalidServerAddressReason.unexpectedParts => l10n.connectErrorParts,
    InvalidServerAddressReason.insecure => l10n.connectErrorInsecure,
  },
  _ => null,
};

/// The message shown in the error banner below the button; `null` for
/// errors shown at the field.
@visibleForTesting
String? bannerError(AppLocalizations l10n, Exception error) => switch (error) {
  InvalidServerAddress() => null,
  // Something answered, but not the Waylight API: a router page, another
  // app behind the same address, a proxy error page.
  ApiException(failure: ApiFailure.server || ApiFailure.notFound) =>
    l10n.connectErrorNotWaylight,
  _ => l10n.errorMessage(error),
};
