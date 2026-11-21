import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/nfc/nfc_repository.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// Offers *Write to NFC tag* for [action] on a long press of [child]
/// (#195). Only Android writes tags; elsewhere [child] stays as it is.
class TagWritable extends StatelessWidget {
  /// Wraps [child], which shows [subject].
  const TagWritable({
    required this.action,
    required this.subject,
    required this.child,
    super.key,
  });

  /// What a tag written from here runs.
  final TagAction action;

  /// The name of the habit, device or item, for the sheet's title.
  final String subject;

  /// The row the action belongs to.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return child;
    return Semantics(
      onLongPressHint: context.l10n.tagWrite,
      child: GestureDetector(
        onLongPress: () =>
            showWriteTagSheet(context, action, subject: subject).ignore(),
        child: child,
      ),
    );
  }
}

/// Writes [action] onto an NFC tag the person holds to the phone.
Future<void> showWriteTagSheet(
  BuildContext context,
  TagAction action, {
  required String subject,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (_) => _WriteTagSheet(
    nfc: context.read<NfcRepository>(),
    action: action,
    subject: subject,
  ),
);

enum _Step { choose, waiting, finished }

class _WriteTagSheet extends StatefulWidget {
  const _WriteTagSheet({
    required this.nfc,
    required this.action,
    required this.subject,
  });

  final NfcRepository nfc;
  final TagAction action;
  final String subject;

  @override
  State<_WriteTagSheet> createState() => _WriteTagSheetState();
}

class _WriteTagSheetState extends State<_WriteTagSheet> {
  _Step _step = _Step.choose;
  NfcState? _nfc;
  TagWriteOutcome? _outcome;
  bool _ask = true;

  @override
  void initState() {
    super.initState();
    widget.nfc.state().then((state) {
      if (mounted) setState(() => _nfc = state);
    }).ignore();
  }

  @override
  void dispose() {
    // Reader mode must not outlive the sheet.
    if (_step == _Step.waiting) widget.nfc.cancel().ignore();
    super.dispose();
  }

  TagAction get _action => switch (widget.action) {
    SmartHomeTag(:final id) => SmartHomeTag(id, ask: _ask),
    final other => other,
  };

  Future<void> _write() async {
    setState(() => _step = _Step.waiting);
    final outcome = await widget.nfc.write(_action);
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _step = _Step.finished;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.tagWrite, style: theme.textTheme.titleMedium),
            Text(widget.subject, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Dimens.gap),
            ...switch ((_nfc, _step)) {
              (null, _) => [const Center(child: CircularProgressIndicator())],
              (NfcState.missing, _) => [Text(l10n.tagNoNfc)],
              (NfcState.off, _) => [Text(l10n.tagNfcOff)],
              (NfcState.ready, _Step.choose) => [
                if (widget.action is SmartHomeTag)
                  SwitchListTile(
                    key: const ValueKey('tag.ask'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.tagAsk),
                    value: _ask,
                    onChanged: (v) => setState(() => _ask = v),
                  ),
                Text(l10n.tagWriteHint, style: theme.textTheme.bodySmall),
                const SizedBox(height: Dimens.gapSmall),
                FilledButton.icon(
                  key: const ValueKey('tag.write'),
                  icon: const Icon(Icons.nfc),
                  label: Text(l10n.tagWriteStart),
                  onPressed: () => _write().ignore(),
                ),
              ],
              (NfcState.ready, _Step.waiting) => [
                Text(l10n.tagHold, key: const ValueKey('tag.hold')),
                const SizedBox(height: Dimens.gap),
                const LinearProgressIndicator(),
              ],
              (NfcState.ready, _Step.finished) => [
                Text(
                  _outcomeText(l10n, _outcome),
                  key: const ValueKey('tag.outcome'),
                ),
                const SizedBox(height: Dimens.gapSmall),
                if (_outcome != TagWriteOutcome.written)
                  OutlinedButton(
                    onPressed: () => _write().ignore(),
                    child: Text(l10n.tagTryAgain),
                  ),
              ],
            },
          ],
        ),
      ),
    );
  }

  static String _outcomeText(AppLocalizations l10n, TagWriteOutcome? o) =>
      switch (o) {
        TagWriteOutcome.written => l10n.tagWritten,
        TagWriteOutcome.locked => l10n.tagLocked,
        TagWriteOutcome.tooSmall => l10n.tagTooSmall,
        TagWriteOutcome.unsupported => l10n.tagUnsupported,
        TagWriteOutcome.lost => l10n.tagLost,
        TagWriteOutcome.unavailable => l10n.tagNfcOff,
        TagWriteOutcome.cancelled ||
        TagWriteOutcome.failed ||
        null => l10n.tagFailed,
      };
}
