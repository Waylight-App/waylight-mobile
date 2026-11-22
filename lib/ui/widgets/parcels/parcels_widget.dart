import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:waylight_mobile/data/repositories/actions/parcels_repository.dart';
import 'package:waylight_mobile/data/repositories/scanner/scanner_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/widgets/common/compact_state_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/items_view_model.dart';
import 'package:waylight_mobile/ui/widgets/common/items_widget.dart';
import 'package:waylight_mobile/ui/widgets/common/widget_rows.dart';

/// The native view of the parcels widget (#135): parcels on their way;
/// add one by tracking number, delete delivered ones.
class ParcelsWidget extends StatelessWidget {
  /// Creates the view for [widget].
  const ParcelsWidget({required this.widget, super.key});

  /// The placement of the widget.
  final WidgetPlacement widget;

  /// The builder for the widget registry.
  /// Small and strip tiles show the server's compact state (#274).
  static Widget forPlacement(BuildContext context, WidgetPlacement widget) =>
      CompactStateWidget.orFull(
        context,
        widget,
        title: widget.title.isNotEmpty
            ? widget.title
            : context.l10n.parcelsTitle,
        full: () => ParcelsWidget(widget: widget, key: ValueKey(widget.id)),
      );

  @override
  Widget build(BuildContext context) => ItemsWidget<Parcel>(
    title: widget.title.isNotEmpty ? widget.title : context.l10n.parcelsTitle,
    interval: const Duration(minutes: 15),
    create: (context) {
      final parcels = context.read<ParcelsRepository>();
      return ItemsViewModel(
        serverRepository: context.read(),
        fetch: parcels.parcels,
        id: (p) => p.id,
      );
    },
    builder: (context, vm) {
      final l10n = context.l10n;
      final parcels = context.read<ParcelsRepository>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.items.isEmpty) Text(l10n.parcelsEmpty),
          for (final p in vm.items)
            InfoRow(
              leading: StatusDot(
                tone: switch (p.status) {
                  ParcelStatus.delivered => Tone.ok,
                  _ => Tone.neutral,
                },
                label: _status(context, p.status),
              ),
              title: p.label.isNotEmpty ? p.label : p.trackingNumber,
              subtitle: [
                p.carrier.toUpperCase(),
                if (p.description.isNotEmpty) p.description,
                if (p.estimatedDelivery case final at?
                    when p.status != ParcelStatus.delivered)
                  l10n.parcelsExpected(shortDate(context, at)),
              ].join(' · '),
              trailing: p.status == ParcelStatus.delivered
                  ? _status(context, p.status)
                  : null,
              trailingTone: Tone.ok,
              onTap: vm.canEdit
                  ? () => _details(context, vm, parcels, p)
                  : null,
            ),
          if (vm.canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.parcelsAdd),
                onPressed: () => _add(context, vm, parcels),
              ),
            ),
        ],
      );
    },
  );

  static String _status(BuildContext context, ParcelStatus s) => switch (s) {
    ParcelStatus.preTransit => context.l10n.parcelsAnnounced,
    ParcelStatus.transit => context.l10n.parcelsOnTheWay,
    ParcelStatus.delivered => context.l10n.parcelsDelivered,
    ParcelStatus.other => context.l10n.parcelsCheck,
  };

  static Future<void> _details(
    BuildContext context,
    ItemsViewModel<Parcel> vm,
    ParcelsRepository parcels,
    Parcel p,
  ) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.trackingUrl != null)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l10n.parcelsTrack),
                onTap: () => Navigator.pop(context, 'track'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.parcelsDelete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'track':
        await LinkOpener.of(context).open(p.trackingUrl!);
      case 'delete':
        await vm.remove(p, (server) => parcels.remove(server, p.id));
    }
  }

  static Future<void> _add(
    BuildContext context,
    ItemsViewModel<Parcel> vm,
    ParcelsRepository parcels,
  ) async {
    // Read here, where the providers are; the dialog sits above them.
    ScannerRepository? scanner;
    try {
      scanner = context.read<ScannerRepository>();
    } on ProviderNotFoundException {
      scanner = null;
    }
    final entry = await showDialog<(String, String)>(
      context: context,
      builder: (context) => _AddParcelDialog(scanner: scanner),
    );
    if (entry == null) return;
    final (number, label) = entry;
    await vm.add((server) => parcels.add(server, number, label: label));
  }
}

/// Asks for a tracking number and an optional description; returns both,
/// or `null` when cancelled or empty.
class _AddParcelDialog extends StatefulWidget {
  const _AddParcelDialog({this.scanner});

  /// Scans the label (#196); `null` hides the button.
  final ScannerRepository? scanner;

  @override
  State<_AddParcelDialog> createState() => _AddParcelDialogState();
}

class _AddParcelDialogState extends State<_AddParcelDialog> {
  final _number = TextEditingController();
  final _label = TextEditingController();
  bool _canScan = false;
  String? _scanHint;

  ScannerRepository? get _scanner => widget.scanner;

  @override
  void initState() {
    super.initState();
    _scanner?.available().then((ok) {
      if (mounted) setState(() => _canScan = ok);
    }).ignore();
  }

  Future<void> _scan() async {
    final l10n = context.l10n;
    String? read;
    final number = await _scanner?.scanTrackingNumber(
      prompt: l10n.parcelsScanPrompt,
      raw: (text) => read = text,
    );
    if (!mounted) return;
    setState(() {
      if (number != null) {
        // Filled in, but the person still confirms or corrects it.
        _number.text = number;
        _scanHint = null;
      } else if (read != null) {
        _scanHint = l10n.parcelsScanNoNumber;
      }
    });
  }

  @override
  void dispose() {
    _number.dispose();
    _label.dispose();
    super.dispose();
  }

  void _submit() {
    final number = _number.text.trim();
    Navigator.pop(
      context,
      number.isEmpty ? null : (number, _label.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.parcelsAdd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('parcels.number'),
            controller: _number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.parcelsNumber,
              helperText: _scanHint,
              suffixIcon: _canScan
                  ? IconButton(
                      key: const ValueKey('parcels.scan'),
                      tooltip: l10n.parcelsScan,
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _scan().ignore(),
                    )
                  : null,
            ),
          ),
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: l10n.parcelsLabel),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.parcelsCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.parcelsAdd)),
      ],
    );
  }
}
