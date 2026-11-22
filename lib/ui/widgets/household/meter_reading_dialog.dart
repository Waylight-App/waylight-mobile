import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/household.dart';
import 'package:waylight_mobile/ui/core/localization.dart';

/// Asks for the value of a meter; pops the number, or nothing when
/// cancelled.
class MeterReadingDialog extends StatefulWidget {
  /// Creates the dialog for [meter].
  const MeterReadingDialog({required this.meter, super.key});

  /// The meter that is read.
  final Meter meter;

  @override
  State<MeterReadingDialog> createState() => _MeterReadingDialogState();
}

class _MeterReadingDialogState extends State<MeterReadingDialog> {
  final _value = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    // A comma is the decimal separator in German.
    final value = double.tryParse(_value.text.trim().replaceAll(',', '.'));
    if (value == null || value < 0) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.meterAddReading(widget.meter.name)),
      content: TextField(
        key: const ValueKey('meterReading.value'),
        controller: _value,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.meterReadingValue,
          suffixText: widget.meter.unit.isEmpty ? null : widget.meter.unit,
          errorText: _invalid ? l10n.meterReadingInvalid : null,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('meterReading.save'),
          onPressed: _save,
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}
