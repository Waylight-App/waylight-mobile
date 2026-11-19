import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/bookmark.dart';
import 'package:waylight_mobile/ui/core/localization.dart';

/// Asks for title, address and folder of a bookmark (#102); returns the
/// draft, or `null` when cancelled or the address is not http(s).
class BookmarkDialog extends StatefulWidget {
  /// Creates the dialog, filled from [bookmark] when editing one.
  const BookmarkDialog({required this.folders, this.bookmark, super.key});

  /// The folders to choose from.
  final List<BookmarkFolder> folders;

  /// The bookmark being edited, or `null` for a new one.
  final Bookmark? bookmark;

  @override
  State<BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<BookmarkDialog> {
  late final _title = TextEditingController(text: widget.bookmark?.title);
  late final _url = TextEditingController(
    text: widget.bookmark?.url.toString(),
  );
  late String _folder = widget.bookmark?.folderId ?? '';

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    final url = Uri.tryParse(_url.text.trim());
    final title = _title.text.trim();
    final ok =
        url != null &&
        (url.scheme == 'https' || url.scheme == 'http') &&
        url.host.isNotEmpty;
    Navigator.pop(
      context,
      ok
          ? BookmarkDraft(
              title: title.isEmpty ? url.host : title,
              url: url,
              folderId: _folder,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final known = widget.folders.any((f) => f.id == _folder);
    return AlertDialog(
      title: Text(
        widget.bookmark == null ? l10n.bookmarkAdd : l10n.bookmarkEdit,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            autofocus: widget.bookmark == null,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'https://'),
          ),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.calendarEventTitle),
          ),
          if (widget.folders.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: known ? _folder : '',
              decoration: InputDecoration(labelText: l10n.bookmarkFolder),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.bookmarkNoFolder)),
                for (final f in widget.folders)
                  DropdownMenuItem(value: f.id, child: Text(f.name)),
              ],
              onChanged: (v) => setState(() => _folder = v ?? ''),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.parcelsCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.calendarSave)),
      ],
    );
  }
}
