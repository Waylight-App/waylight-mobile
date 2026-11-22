import 'package:material_ui/material_ui.dart';

/// The system's text scaling with a step of the account on top (#291).
///
/// Wraps the system's [TextScaler] instead of replacing it, so a phone with
/// a large system font and a larger step gets both, also where the system
/// scales non-linearly.
@immutable
final class StepTextScaler extends TextScaler {
  /// Multiplies what [system] scales by [factor].
  const StepTextScaler(this.system, this.factor);

  /// The scaling the system asks for.
  final TextScaler system;

  /// The step of the account; 1 changes nothing.
  final double factor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;

  @override
  // Needed by the interface; the linear equivalent at one point size.
  // ignore: deprecated_member_use
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is StepTextScaler &&
      other.system == system &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(system, factor);
}
