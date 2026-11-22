import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/announcement.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/markdown_view.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/announcements/announcements_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The native view of the announcements widget (#202).
class AnnouncementsWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const AnnouncementsWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      AnnouncementsWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => AnnouncementsViewModel(
      serverRepository: context.read(),
      repository: context.read(),
    ),
    builder: (context, viewModel) => WidgetFrame<void>(
      title: widget.title.isNotEmpty
          ? widget.title
          : context.l10n.announcementsTitle,
      load: viewModel.load,
      builder: (context, _) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => _List(viewModel: viewModel),
      ),
    ),
  );
}

class _List extends StatelessWidget {
  const _List({required this.viewModel});

  final AnnouncementsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (viewModel.off) return Text(l10n.announcementsOff);
    final theme = Theme.of(context);
    final items = viewModel.items;
    // Rows keep to one line in a tile, which fits them by height.
    final lines = WidgetSizeScope.inGrid(context) ? 1 : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty) Text(l10n.announcementsEmpty),
        TileRows(
          items: items,
          rowHeight: TileRows.twoLineRowHeight + 8,
          rowBuilder: (context, a) => ListTile(
            key: ValueKey('announcement.${a.id}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: a.pinned
                ? Icon(
                    Icons.push_pin_outlined,
                    semanticLabel: l10n.announcementPinned,
                  )
                : null,
            title: Text(
              a.title,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              style: a.read
                  ? null
                  : const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              [
                if (a.authorName.isNotEmpty) a.authorName,
                MaterialLocalizations.of(context)
                    .formatShortMonthDay(a.createdAt),
                if (!a.read) l10n.announcementUnread,
              ].join(' · '),
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: a.read
                ? null
                : Icon(
                    Icons.circle,
                    size: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            onTap: () => showAnnouncement(context, viewModel, a).ignore(),
          ),
        ),
        // Writing is one tap away in the full view.
        if (viewModel.mayWrite && !WidgetSizeScope.inGrid(context))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('announcements.add'),
              icon: const Icon(Icons.add),
              label: Text(l10n.announcementWrite),
              onPressed: () =>
                  showAnnouncementForm(context, viewModel).ignore(),
            ),
          ),
      ],
    );
  }
}

/// Opens [a] in full and marks it as read.
@visibleForTesting
Future<void> showAnnouncement(
  BuildContext context,
  AnnouncementsViewModel viewModel,
  Announcement a,
) {
  viewModel.open(a).ignore();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final l10n = context.l10n;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(Dimens.gap),
          children: [
            Text(a.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Dimens.gapSmall),
            MarkdownView(a.body),
            if (a.editable) ...[
              const SizedBox(height: Dimens.gap),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: const ValueKey('announcement.edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.announcementEdit),
                  onPressed: () {
                    Navigator.pop(context);
                    showAnnouncementForm(context, viewModel, a).ignore();
                  },
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Opens the form to write an announcement, or to change [existing].
@visibleForTesting
Future<void> showAnnouncementForm(
  BuildContext context,
  AnnouncementsViewModel viewModel, [
  Announcement? existing,
]) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _Form(viewModel: viewModel, existing: existing),
);

class _Form extends StatefulWidget {
  const _Form({required this.viewModel, this.existing});

  final AnnouncementsViewModel viewModel;
  final Announcement? existing;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _body = TextEditingController(text: widget.existing?.body);
  late bool _pinned = widget.existing?.pinned ?? false;
  late DateTime? _expires = widget.existing?.expiresAt;
  bool _notify = false;
  String _field = '';
  String? _fieldError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _expires ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (day != null) {
      // Until the end of the chosen day.
      setState(() => _expires = DateTime(day.year, day.month, day.day, 23, 59));
    }
  }

  void _done(Result<void> result) {
    switch (result) {
      case Ok():
        Navigator.pop(context);
      case Error(:final error):
        setState(() {
          _busy = false;
          if (error case ApiException(:final field?, :final message?)) {
            _field = field;
            _fieldError = message;
            _error = null;
          } else {
            _field = '';
            _fieldError = null;
            _error = context.l10n.errorMessage(error);
          }
        });
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    _done(
      await widget.viewModel.save(
        AnnouncementInput(
          title: _title.text,
          body: _body.text,
          pinned: _pinned,
          expiresAt: _expires,
          notify: _notify,
        ),
        existing: widget.existing,
      ),
    );
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    setState(() => _busy = true);
    _done(await widget.viewModel.delete(existing));
  }

  String? _errorFor(String field) => _field == field ? _fieldError : null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = MaterialLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: Dimens.gap,
        right: Dimens.gap,
        top: Dimens.gap,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Dimens.gap,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? l10n.announcementWrite
                  : l10n.announcementEdit,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextField(
              key: const ValueKey('announcement.title'),
              controller: _title,
              maxLength: Announcement.maxTitle,
              decoration: InputDecoration(
                labelText: l10n.announcementTitleField,
                errorText: _errorFor('title'),
              ),
            ),
            TextField(
              key: const ValueKey('announcement.body'),
              controller: _body,
              minLines: 4,
              maxLines: 10,
              maxLength: Announcement.maxBody,
              decoration: InputDecoration(
                labelText: l10n.announcementBodyField,
                helperText: l10n.announcementMarkdownHint,
                errorText: _errorFor('body'),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.announcementPinned),
              value: _pinned,
              onChanged: (v) => setState(() => _pinned = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.announcementExpires),
              subtitle: _errorFor('expiresAt') == null
                  ? null
                  : Text(_errorFor('expiresAt')!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expires == null
                        ? l10n.announcementNoExpiry
                        : m.formatMediumDate(_expires!),
                  ),
                  if (_expires != null)
                    IconButton(
                      tooltip: l10n.announcementNoExpiry,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _expires = null),
                    ),
                ],
              ),
              onTap: () => _pickExpiry().ignore(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.announcementNotify),
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: Dimens.gapSmall),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton(
                    key: const ValueKey('announcement.delete'),
                    onPressed: _busy ? null : () => _delete().ignore(),
                    child: Text(l10n.announcementDelete),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(m.cancelButtonLabel),
                ),
                FilledButton(
                  key: const ValueKey('announcement.save'),
                  onPressed: _busy ? null : () => _save().ignore(),
                  child: Text(
                    widget.existing == null
                        ? l10n.announcementPublish
                        : m.saveButtonLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
