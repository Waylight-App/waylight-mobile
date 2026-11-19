import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/notes/notes_view_model.dart';

/// The native view of the notes widget (#65): title and a one-line preview
/// per note. Reading a whole note follows with the notes screen.
class NotesWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const NotesWidget({required this.widget, super.key});

  /// The placement with the widget's configuration.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      NotesWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) {
    final scope = NotesScope.fromJson(widget.config);
    return ViewModelHost(
      create: (context) => NotesViewModel(
        scope: scope,
        serverRepository: context.read(),
        notesRepository: context.read(),
      ),
      builder: (context, viewModel) => WidgetFrame(
        title: widget.title.isNotEmpty ? widget.title : context.l10n.notesTitle,
        load: viewModel.load,
        interval: const Duration(minutes: 10),
        builder: (context, notes) => notes.isEmpty
            ? Text(
                scope == NotesScope.pinned
                    ? context.l10n.notesNonePinned
                    : context.l10n.notesNone,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final note in notes) _NoteRow(note: note)],
              ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.preview;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.gapTiny),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            note.pinned ? Icons.push_pin_outlined : Icons.notes,
            size: Dimens.iconSmall,
            color: theme.colorScheme.onSurfaceVariant,
            semanticLabel: note.pinned ? context.l10n.notesPinned : null,
          ),
          const SizedBox(width: Dimens.gapSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: theme.textTheme.titleSmall),
                if (preview.isNotEmpty)
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
