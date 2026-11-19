import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/widgets/calendar/calendar_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The agenda of the next weeks with a button for a new event (#100).
class CalendarScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const CalendarScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.calendarTitle)),
        floatingActionButton: viewModel.writable.isEmpty
            ? null
            : FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: Text(l10n.calendarNewEvent),
                onPressed: () => _newEvent(context),
              ),
        body: RefreshIndicator(
          onRefresh: viewModel.load.execute,
          child: _Agenda(viewModel: viewModel),
        ),
      ),
    );
  }

  Future<void> _newEvent(BuildContext context) async {
    final event = await showModalBottomSheet<NewEvent>(
      context: context,
      isScrollControlled: true,
      builder: (context) => NewEventSheet(calendars: viewModel.writable),
    );
    if (event == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await viewModel.create.execute(event);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (viewModel.create.result) {
          Error(:final error) => l10n.errorMessage(error),
          _ => l10n.calendarEventAdded(event.summary),
        }),
      ),
    );
  }
}

class _Agenda extends StatelessWidget {
  const _Agenda({required this.viewModel});

  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final load = viewModel.load;
    if (load.running && viewModel.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (load.result case Error(:final error) when viewModel.events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(Dimens.gap),
        children: [Text(l10n.errorMessage(error))],
      );
    }
    if (viewModel.events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(Dimens.gap),
        children: [Text(l10n.calendarEmpty)],
      );
    }
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final day = DateFormat.MMMMEEEEd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final rows = <Widget>[];
    DateTime? last;
    for (final e in viewModel.events) {
      final d = DateTime(e.start.year, e.start.month, e.start.day);
      if (d != last) {
        last = d;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(
              top: Dimens.gap,
              bottom: Dimens.gapTiny,
            ),
            child: Text(
              day.format(d),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        );
      }
      rows.add(
        InfoRow(
          title: e.summary,
          subtitle: [
            if (e.location.isNotEmpty) e.location,
            if (e.calendar.isNotEmpty) e.calendar,
          ].join(' · '),
          trailing: e.allDay
              ? l10n.calendarAllDay
              : '${time.format(e.start)}–${time.format(e.end)}',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(Dimens.gap, 0, Dimens.gap, 88),
      children: rows,
    );
  }
}

/// The form of a new event; pops with the [NewEvent] or nothing.
class NewEventSheet extends StatefulWidget {
  /// Creates the form for [calendars].
  const NewEventSheet({
    required this.calendars,
    this.now = DateTime.now,
    super.key,
  });

  /// The calendars to choose from; not empty.
  final List<WritableCalendar> calendars;

  /// The clock for the default time; tests pass their own.
  final DateTime Function() now;

  @override
  State<NewEventSheet> createState() => _NewEventSheetState();
}

class _NewEventSheetState extends State<NewEventSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  late String _calendar = widget.calendars.first.id;
  late DateTime _day;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _allDay = false;

  @override
  void initState() {
    super.initState();
    final now = widget.now();
    _day = DateTime(now.year, now.month, now.day);
    // The next full hour, like most calendar apps.
    _start = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    _end = TimeOfDay(hour: (now.hour + 2) % 24, minute: 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) =>
      DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);

  void _save() {
    final summary = _title.text.trim();
    if (summary.isEmpty) return;
    var end = _allDay ? _day : _at(_end);
    if (!_allDay && !end.isAfter(_at(_start))) {
      end = _at(_start).add(const Duration(hours: 1));
    }
    Navigator.pop(
      context,
      NewEvent(
        calendarId: _calendar,
        summary: summary,
        location: _location.text.trim(),
        allDay: _allDay,
        start: _allDay ? _day : _at(_start),
        end: end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimens.gap,
        Dimens.gap,
        Dimens.gap,
        MediaQuery.viewInsetsOf(context).bottom + Dimens.gap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.calendarNewEvent,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.calendarEventTitle),
          ),
          TextField(
            controller: _location,
            decoration: InputDecoration(labelText: l10n.calendarEventLocation),
          ),
          if (widget.calendars.length > 1)
            DropdownButtonFormField<String>(
              initialValue: _calendar,
              decoration: InputDecoration(labelText: l10n.calendarTitle),
              items: [
                for (final c in widget.calendars)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _calendar = v ?? _calendar),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarAllDay),
            value: _allDay,
            onChanged: (v) => setState(() => _allDay = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(DateFormat.yMMMEd(locale).format(_day)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _day,
                firstDate: _day.subtract(const Duration(days: 365)),
                lastDate: _day.add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setState(() => _day = picked);
            },
          ),
          if (!_allDay)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _start,
                      );
                      if (t != null) setState(() => _start = t);
                    },
                    child: Text(_start.format(context)),
                  ),
                ),
                const Text('–'),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _end,
                      );
                      if (t != null) setState(() => _end = t);
                    },
                    child: Text(_end.format(context)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: Dimens.gapSmall),
          FilledButton(onPressed: _save, child: Text(l10n.calendarSave)),
        ],
      ),
    );
  }
}
