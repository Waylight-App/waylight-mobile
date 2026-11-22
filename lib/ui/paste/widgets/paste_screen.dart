import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/paste_link.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/paste/view_models/paste_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The most characters the server accepts for a pasted value.
const _maxValueLength = 4096;

/// Sends a value to the setup assistant (#303): scan its QR code, enter the
/// value, send it.
class PasteScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const PasteScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final PasteViewModel viewModel;

  @override
  State<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends State<PasteScreen> {
  final _value = TextEditingController();
  bool _hidden = true;

  PasteViewModel get _viewModel => widget.viewModel;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pasteTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Dimens.maxPageWidth),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _viewModel,
              _viewModel.scan,
              _viewModel.send,
            ]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(Dimens.gap),
              children: [
                Text(l10n.pasteIntro),
                const SizedBox(height: Dimens.gap),
                ..._messages(l10n),
                if (_viewModel.link case final link?)
                  ..._form(context, link)
                else if (!_viewModel.available)
                  MessageBanner(
                    kind: MessageKind.info,
                    message: l10n.pasteUnavailable,
                  ),
                if (_viewModel.available || _viewModel.link != null)
                  ..._scanButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _messages(AppLocalizations l10n) {
    final errors = [
      ?_viewModel.linkError,
      if (_viewModel.scan.result case Error(:final error)) error,
      if (_viewModel.send.result case Error(:final error)) error,
    ];
    return [
      if (_viewModel.send.result case Ok())
        MessageBanner(kind: MessageKind.info, message: l10n.pasteDone),
      for (final error in errors)
        MessageBanner(
          kind: MessageKind.error,
          message: pasteError(l10n, error),
        ),
      if (_viewModel.send.result != null || errors.isNotEmpty)
        const SizedBox(height: Dimens.gap),
    ];
  }

  List<Widget> _form(BuildContext context, PasteLink link) {
    final l10n = context.l10n;
    return [
      Text(
        l10n.pasteTarget(link.server.uri.authority),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: Dimens.gapSmall),
      TextField(
        key: const ValueKey('paste.value'),
        controller: _value,
        enabled: !_viewModel.send.running,
        obscureText: _hidden,
        autocorrect: false,
        enableSuggestions: false,
        maxLength: _maxValueLength,
        decoration: InputDecoration(
          labelText: l10n.pasteValueLabel,
          suffixIcon: IconButton(
            key: const ValueKey('paste.reveal'),
            tooltip: _hidden ? l10n.pasteShow : l10n.pasteHide,
            icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _hidden = !_hidden),
          ),
        ),
      ),
      const SizedBox(height: Dimens.gapSmall),
      CommandButton(
        key: const ValueKey('paste.send'),
        command: _viewModel.send,
        onPressed: () => _viewModel.send.execute(_value.text).ignore(),
        label: l10n.pasteSend,
      ),
      const SizedBox(height: Dimens.gapSmall),
    ];
  }

  List<Widget> _scanButton(AppLocalizations l10n) => [
    CommandButton(
      key: const ValueKey('paste.scan'),
      command: _viewModel.scan,
      onPressed: () => _viewModel.scan.execute(l10n.pasteScanPrompt).ignore(),
      label: _viewModel.link == null ? l10n.pasteScan : l10n.pasteScanAgain,
      variant: _viewModel.link == null
          ? CommandButtonVariant.filled
          : CommandButtonVariant.outlined,
    ),
  ];
}

/// The message for an unusable code or a failed send.
@visibleForTesting
String pasteError(AppLocalizations l10n, Exception error) => switch (error) {
  InvalidPasteLink() => l10n.pasteInvalidCode,
  InvalidServerAddress() => l10n.pasteInvalidCode,
  PasteOtherServer() => l10n.pasteOtherServer,
  // The server answers 422 for an expired code and for a bad value.
  ApiException(failure: ApiFailure.invalid, :final field) =>
    field == 'value' ? l10n.pasteValueInvalid : l10n.pasteExpired,
  _ => l10n.errorMessage(error),
};
