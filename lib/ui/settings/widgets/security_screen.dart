import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/account_security.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/settings/view_models/security_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Password, two-factor sign-in and sessions of the account (#110).
class SecurityScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const SecurityScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final SecurityViewModel viewModel;

  void _report(BuildContext context, Result<Object?> result, String done) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Ok() => done,
          Error(:final error) => context.l10n.errorMessage(error),
        }),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final l10n = context.l10n;
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => _FieldsDialog(
        title: l10n.securityChangePassword,
        fields: [l10n.securityCurrentPassword, l10n.securityNewPassword],
        hidden: const [true, true],
      ),
    );
    if (values == null || !context.mounted) return;
    final result = await viewModel.changePassword(values[0], values[1]);
    if (context.mounted) _report(context, result, l10n.securityPasswordChanged);
  }

  Future<void> _setUpTotp(BuildContext context) async {
    final l10n = context.l10n;
    final setup = await viewModel.startTotp();
    if (!context.mounted) return;
    if (setup case Error()) return _report(context, setup, '');
    final s = (setup as Ok<TotpSetup>).value;
    final code = await showDialog<String>(
      context: context,
      builder: (_) => _TotpDialog(setup: s, opener: LinkOpener.of(context)),
    );
    if (code == null || !context.mounted) return;
    final result = await viewModel.confirmTotp(code);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.securityRecoveryCodes),
            content: SelectableText(value.join('\n')),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.securityCodesSaved),
              ),
            ],
          ),
        );
      case Error():
        _report(context, result, '');
    }
  }

  Future<void> _disableTotp(BuildContext context) async {
    final l10n = context.l10n;
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => _FieldsDialog(
        title: l10n.securityTotpOff,
        fields: [l10n.securityCurrentPassword, l10n.securityCode],
        hidden: const [true, false],
      ),
    );
    if (values == null || !context.mounted) return;
    final result = await viewModel.disableTotp(values[0], values[1]);
    if (context.mounted) _report(context, result, l10n.securityTotpIsOff);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm();
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.securityTitle)),
        body: ListView(
          padding: const EdgeInsets.all(Dimens.gap),
          children: [
            SectionCard(
              title: l10n.securityPassword,
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => _changePassword(context),
                  child: Text(l10n.securityChangePassword),
                ),
              ),
            ),
            const SizedBox(height: Dimens.gap),
            SectionCard(
              title: l10n.securityTotp,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.totpEnabled
                        ? l10n.securityTotpOn
                        : l10n.securityTotpIsOff,
                  ),
                  const SizedBox(height: Dimens.gapSmall),
                  OutlinedButton(
                    onPressed: () => viewModel.totpEnabled
                        ? _disableTotp(context)
                        : _setUpTotp(context),
                    child: Text(
                      viewModel.totpEnabled
                          ? l10n.securityTotpOff
                          : l10n.securityTotpSetUp,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimens.gap),
            SectionCard(
              title: l10n.securitySessions,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (viewModel.load.result case Error(:final error))
                    Text(l10n.errorMessage(error)),
                  for (final s in viewModel.sessions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.device.isNotEmpty ? s.device : s.userAgent),
                      subtitle: Text(
                        s.current
                            ? l10n.securityThisDevice
                            : '${s.clientIp} · ${time.format(s.lastSeenAt)}',
                      ),
                      trailing: s.current
                          ? null
                          : IconButton(
                              tooltip: l10n.securitySignOutSession,
                              icon: const Icon(Icons.logout),
                              onPressed: () async {
                                final result = await viewModel.revoke(s);
                                if (context.mounted) {
                                  _report(
                                    context,
                                    result,
                                    l10n.securitySessionEnded,
                                  );
                                }
                              },
                            ),
                    ),
                  if (viewModel.sessions.length > 1)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          final result = await viewModel.revokeOthers();
                          if (context.mounted) {
                            _report(context, result, l10n.securitySessionEnded);
                          }
                        },
                        child: Text(l10n.securitySignOutOthers),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for a few texts; returns them, or `null` when cancelled or one is
/// empty.
class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog({
    required this.title,
    required this.fields,
    required this.hidden,
  });

  final String title;
  final List<String> fields;

  /// Per field whether it is typed hidden, like a password.
  final List<bool> hidden;

  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  late final _controllers = [
    for (final _ in widget.fields) TextEditingController(),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final values = [for (final c in _controllers) c.text];
    Navigator.pop(context, values.any((v) => v.isEmpty) ? null : values);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.fields.length; i++)
          TextField(
            controller: _controllers[i],
            autofocus: i == 0,
            obscureText: widget.hidden[i],
            decoration: InputDecoration(labelText: widget.fields[i]),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.parcelsCancel),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.title)),
    ],
  );
}

/// Shows the secret, opens the authenticator app and asks for its code.
class _TotpDialog extends StatefulWidget {
  const _TotpDialog({required this.setup, required this.opener});

  final TotpSetup setup;

  // Taken from the screen: the dialog lives in the navigator's overlay.
  final LinkOpener opener;

  @override
  State<_TotpDialog> createState() => _TotpDialogState();
}

class _TotpDialogState extends State<_TotpDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.securityTotpSetUp),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.securityTotpHint),
          const SizedBox(height: Dimens.gapSmall),
          SelectableText(widget.setup.secret),
          TextButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.securityOpenAuthenticator),
            onPressed: () => widget.opener.open(widget.setup.uri),
          ),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.securityCode),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.parcelsCancel),
        ),
        FilledButton(
          onPressed: () {
            final code = _code.text.trim();
            Navigator.pop(context, code.isEmpty ? null : code);
          },
          child: Text(l10n.securityConfirm),
        ),
      ],
    );
  }
}
