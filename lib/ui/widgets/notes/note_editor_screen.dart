import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/common/admin_actions.dart';
import 'package:waylight_mobile/ui/widgets/notes/note_editor_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Writes a new note or changes one (#101). Saving checks the version, so
/// a change made in the web interface meanwhile is never overwritten.
class NoteEditorScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const NoteEditorScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final NoteEditorViewModel viewModel;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _pinned = false;
  bool _filled = false;

  NoteEditorViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_fill);
    _fill();
  }

  @override
  void dispose() {
    _vm.removeListener(_fill);
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Puts the loaded note into the fields once.
  void _fill() {
    final note = _vm.note;
    if (_filled || note == null) return;
    _filled = true;
    setState(() {
      _title.text = note.title;
      _body.text = note.body;
      _pinned = note.pinned;
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noteTitleMissing)));
      return;
    }
    await _vm.save.execute(
      NoteDraft(title: title, body: _body.text, pinned: _pinned),
    );
    if (!mounted) return;
    switch (_vm.save.result) {
      case Error(error: ApiException(failure: ApiFailure.conflict)):
        messenger.showSnackBar(SnackBar(content: Text(l10n.noteConflict)));
      case Error(:final error):
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(error))),
        );
      default:
        messenger.showSnackBar(SnackBar(content: Text(l10n.noteSaved)));
        context.pop();
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    if (!await confirmAction(
      context,
      title: l10n.noteDeleteConfirm,
      action: l10n.noteDelete,
    )) {
      return;
    }
    await _vm.delete.execute();
    if (!mounted) return;
    if (_vm.delete.result case Error(:final error)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(error))));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.load, _vm.save]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(_vm.isNew ? l10n.noteNew : l10n.noteEdit),
          actions: [
            IconButton(
              tooltip: _pinned ? l10n.noteUnpin : l10n.notePin,
              icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () => setState(() => _pinned = !_pinned),
            ),
            if (!_vm.isNew)
              IconButton(
                tooltip: l10n.noteDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
              ),
            IconButton(
              tooltip: l10n.calendarSave,
              icon: const Icon(Icons.check),
              onPressed: _vm.save.running ? null : _save,
            ),
          ],
        ),
        body: switch (_vm.load.result) {
          Error(:final error) => Padding(
            padding: const EdgeInsets.all(Dimens.gap),
            child: Text(l10n.errorMessage(error)),
          ),
          _ when _vm.load.running => const Center(
            child: CircularProgressIndicator(),
          ),
          _ => ListView(
            padding: const EdgeInsets.all(Dimens.gap),
            children: [
              TextField(
                controller: _title,
                autofocus: _vm.isNew,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: InputDecoration(hintText: l10n.calendarEventTitle),
              ),
              const SizedBox(height: Dimens.gapSmall),
              TextField(
                controller: _body,
                minLines: 12,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: l10n.noteBodyHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
