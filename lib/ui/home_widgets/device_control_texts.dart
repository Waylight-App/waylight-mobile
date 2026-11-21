import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/device_control.dart';
import 'package:waylight_mobile/l10n/generated/app_localizations.dart';

/// Formats Android's device controls in the app's language (#194).
class DeviceControlTexts implements DeviceControlFormatter {
  /// Creates the formatter for [l10n].
  const DeviceControlTexts(this.l10n);

  /// The texts in the app's language.
  final AppLocalizations l10n;

  @override
  String state(SmartEntity entity) => switch ((entity.action, entity.state)) {
    (EntityAction.press, _) => l10n.smartHomeRun,
    (_, 'on') => l10n.quickTileOn,
    (_, 'off') => l10n.quickTileOff,
    (_, 'unavailable' || 'unknown') => l10n.deviceControlNoState,
    (_, final s) => entity.unit.isEmpty ? s : '$s ${entity.unit}',
  };

  @override
  String problem(DeviceControlsProblem problem) => switch (problem) {
    DeviceControlsProblem.signedOut => l10n.deviceControlSignIn,
    DeviceControlsProblem.unreachable => l10n.quickTileUnreachable,
  };
}
