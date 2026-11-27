import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/domain/models/absence.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widget_size_scope.dart';
import 'package:waylight_mobile/ui/core/widgets/tile_rows.dart';
import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';
import 'package:waylight_mobile/ui/core/widgets/widget_frame.dart';
import 'package:waylight_mobile/ui/widgets/absences/absences_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The words for a kind, as on the server's widget.
@visibleForTesting
String absenceKindLabel(AppLocalizations l10n, AbsenceKind k) => switch (k) {
  AbsenceKind.holiday => l10n.absenceHoliday,
  AbsenceKind.sick => l10n.absenceSick,
  AbsenceKind.remote => l10n.absenceRemote,
  AbsenceKind.other || AbsenceKind.away => l10n.absenceAway,
};

/// The native view of the absences widget (#201).
class AbsencesWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const AbsencesWidget({required this.widget, this.now, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The clock that decides what is today; the device's by default. Tests
  /// fix it, so their example absences do not run out.
  final DateTime Function()? now;

  /// The builder for the widget registry.
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      AbsencesWidget(widget: widget, key: ValueKey(widget.id));

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: (context) => AbsencesViewModel(
      serverRepository: context.read(),
      absencesRepository: context.read(),
      now: now,
    ),
    builder: (context, viewModel) => WidgetFrame<void>(
      title: widget.title.isNotEmpty
          ? widget.title
          : context.l10n.absencesTitle,
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

  final AbsencesViewModel viewModel;

  String _period(BuildContext context, Absence a) {
    final m = MaterialLocalizations.of(context);
    final l10n = context.l10n;
    return a.from == a.to
        ? m.formatShortMonthDay(a.from)
        : l10n.absenceRange(
            m.formatShortMonthDay(a.from),
            m.formatShortMonthDay(a.to),
          );
  }

  Widget _row(BuildContext context, Absence a) {
    final l10n = context.l10n;
    // Rows keep to one line in a tile, which fits them by height.
    final lines = WidgetSizeScope.inGrid(context) ? 1 : null;
    final details = [
      absenceKindLabel(l10n, a.kind),
      _period(context, a),
      if (a.private && a.kind != AbsenceKind.away) l10n.absencePrivateBadge,
      if (a.note.isNotEmpty) a.note,
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(a.name, maxLines: lines, overflow: TextOverflow.ellipsis),
      subtitle: Text(details, maxLines: lines, overflow: TextOverflow.ellipsis),
      trailing: a.editable && viewModel.canEnter
          ? IconButton(
              tooltip: l10n.absenceEdit(a.name),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showAbsenceForm(context, viewModel, a).ignore(),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (viewModel.off) return Text(l10n.absencesOff);
    final today = viewModel.today;
    final later = viewModel.laterThisWeek;
    final style = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The headings are rows of the tile too, so it never ends on one.
        TileRows<Widget>(
          items: [
            Text(l10n.absencesToday, style: style),
            if (today.isEmpty)
              Text(l10n.absencesNobodyToday)
            else
              for (final a in today) _row(context, a),
            Padding(
              padding: const EdgeInsets.only(top: Dimens.gapSmall),
              child: Text(l10n.absencesWeek, style: style),
            ),
            if (later.isEmpty)
              Text(l10n.absencesNobodyWeek)
            else
              for (final a in later) _row(context, a),
          ],
          rowHeight: TileRows.twoLineRowHeight,
          rowBuilder: (context, row) => row,
        ),
        // Entering is one tap away in the full view.
        if (viewModel.canEnter && !WidgetSizeScope.inGrid(context))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('absences.add'),
              icon: const Icon(Icons.add),
              label: Text(l10n.absenceAdd),
              onPressed: () => showAbsenceForm(context, viewModel).ignore(),
            ),
          ),
      ],
    );
  }
}

/// Opens the form to enter an absence, or to change or delete [existing].
@visibleForTesting
Future<void> showAbsenceForm(
  BuildContext context,
  AbsencesViewModel viewModel, [
  Absence? existing,
]) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _AbsenceForm(viewModel: viewModel, existing: existing),
);

class _AbsenceForm extends StatefulWidget {
  const _AbsenceForm({required this.viewModel, this.existing});

  final AbsencesViewModel viewModel;
  final Absence? existing;

  @override
  State<_AbsenceForm> createState() => _AbsenceFormState();
}

class _AbsenceFormState extends State<_AbsenceForm> {
  late DateTime _from;
  late DateTime _to;
  late AbsenceKind _kind;
  late bool _private;
  String _accountId = '';
  late final TextEditingController _note;
  String? _fieldError;
  String _field = '';
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _from = e?.from ?? today;
    _to = e?.to ?? today;
    _kind = switch (e?.kind) {
      final k? when AbsenceKind.enterable.contains(k) => k,
      _ => AbsenceKind.holiday,
    };
    _private = e?.private ?? false;
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_to.isBefore(_from)) {
      setState(() {
        _field = 'to';
        _fieldError = l10n.absenceErrorDates;
      });
      return;
    }
    setState(() => _busy = true);
    final result = await widget.viewModel.save(
      AbsenceInput(
        from: _from,
        to: _to,
        kind: _kind,
        note: _note.text,
        private: _private,
        accountId: widget.existing == null ? _accountId : '',
      ),
      existing: widget.existing,
    );
    if (!mounted) return;
    _done(result);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    setState(() => _busy = true);
    _done(await widget.viewModel.delete(existing));
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null
                ? l10n.absenceAdd
                : l10n.absenceEdit(widget.existing!.name),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (widget.existing == null && widget.viewModel.members.isNotEmpty)
            DropdownButtonFormField<String>(
              key: const ValueKey('absence.person'),
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: l10n.absencePerson,
                errorText: _errorFor('accountId'),
              ),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.absenceMe)),
                for (final m in widget.viewModel.members)
                  DropdownMenuItem(value: m.id, child: Text(m.name)),
              ],
              onChanged: (id) => setState(() => _accountId = id ?? ''),
            ),
          ListTile(
            key: const ValueKey('absence.from'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.absenceFrom),
            subtitle: _errorFor('from') == null
                ? null
                : Text(_errorFor('from')!),
            trailing: Text(m.formatMediumDate(_from)),
            onTap: () => _pick(from: true).ignore(),
          ),
          ListTile(
            key: const ValueKey('absence.to'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.absenceTo),
            subtitle: _errorFor('to') == null ? null : Text(_errorFor('to')!),
            trailing: Text(m.formatMediumDate(_to)),
            onTap: () => _pick(from: false).ignore(),
          ),
          DropdownButtonFormField<AbsenceKind>(
            key: const ValueKey('absence.kind'),
            initialValue: _kind,
            decoration: InputDecoration(
              labelText: l10n.absenceKind,
              errorText: _errorFor('kind'),
            ),
            items: [
              for (final k in AbsenceKind.enterable)
                DropdownMenuItem(
                  value: k,
                  child: Text(absenceKindLabel(l10n, k)),
                ),
            ],
            onChanged: (k) => setState(() => _kind = k ?? _kind),
          ),
          const SizedBox(height: Dimens.gapSmall),
          TextField(
            key: const ValueKey('absence.note'),
            controller: _note,
            maxLength: AbsenceInput.maxNote,
            decoration: InputDecoration(
              labelText: l10n.absenceNote,
              errorText: _errorFor('note'),
            ),
          ),
          SwitchListTile(
            key: const ValueKey('absence.private'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.absencePrivate),
            value: _private,
            onChanged: (v) => setState(() => _private = v),
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
                  key: const ValueKey('absence.delete'),
                  onPressed: _busy ? null : () => _delete().ignore(),
                  child: Text(l10n.absenceDelete),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(m.cancelButtonLabel),
              ),
              FilledButton(
                key: const ValueKey('absence.save'),
                onPressed: _busy ? null : () => _save().ignore(),
                child: Text(m.saveButtonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
