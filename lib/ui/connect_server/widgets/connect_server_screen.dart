import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Asks for the address of the Waylight server.
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
    final viewModel = widget.viewModel;
    return Scaffold(
      body: FormPage(
        children: [
          Text(
            l10n.connectTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Dimens.gapSmall),
          Text(l10n.connectIntro),
          const SizedBox(height: Dimens.gapLarge),
          ListenableBuilder(
            listenable: Listenable.merge([viewModel, viewModel.connect]),
            builder: (context, _) {
              final command = viewModel.connect;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('connect.address'),
                    controller: _address,
                    enabled: !command.running,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onChanged: viewModel.onAddressChanged,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.connectAddressLabel,
                      hintText: l10n.connectAddressHint,
                      errorText: switch (command.result) {
                        Error(:final error) => errorText(l10n, error),
                        _ => null,
                      },
                      helperText: viewModel.insecure
                          ? l10n.connectInsecureWarning
                          : null,
                      helperMaxLines: 3,
                      errorMaxLines: 3,
                    ),
                  ),
                  const SizedBox(height: Dimens.gap),
                  FilledButton(
                    key: const ValueKey('connect.submit'),
                    onPressed: command.running ? null : _submit,
                    child: command.running
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.connectButton),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The message for an [error] of the connect command.
@visibleForTesting
String errorText(AppLocalizations l10n, Exception error) => switch (error) {
  InvalidServerAddress(:final reason) => switch (reason) {
    InvalidServerAddressReason.empty => l10n.connectErrorEmpty,
    InvalidServerAddressReason.malformed => l10n.connectErrorInvalid,
    InvalidServerAddressReason.unsupportedScheme => l10n.connectErrorScheme,
    InvalidServerAddressReason.unexpectedParts => l10n.connectErrorParts,
  },
  ApiException(failure: ApiFailure.unreachable) => l10n.connectErrorUnreachable,
  ApiException() => l10n.connectErrorNotWaylight,
  _ => l10n.connectErrorUnknown,
};
