import 'package:material_ui/material_ui.dart';

/// Colours for states the Material colour scheme has no role for: warnings
/// (plain HTTP, offline, stale data) and success (a service is up).
///
/// A [ThemeExtension], so the colours switch with light and dark mode like
/// the scheme itself. Read them with `StatusColors.of(context)`.
@immutable
final class StatusColors extends ThemeExtension<StatusColors> {
  /// Creates the colours.
  const StatusColors({
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
  });

  /// The colours in light mode; contrast ≥ 4.5:1 on the surface.
  static const light = StatusColors(
    warning: Color(0xFF7A4F00),
    warningContainer: Color(0xFFFFDEA6),
    onWarningContainer: Color(0xFF271900),
    success: Color(0xFF2E6B30),
  );

  /// The colours in dark mode; contrast ≥ 4.5:1 on the surface.
  static const dark = StatusColors(
    warning: Color(0xFFFFBA3B),
    warningContainer: Color(0xFF5C4300),
    onWarningContainer: Color(0xFFFFDEA6),
    success: Color(0xFF8BD88E),
  );

  /// Text and icons that warn, on the surface.
  final Color warning;

  /// Background of a warning banner.
  final Color warningContainer;

  /// Text and icons on [warningContainer].
  final Color onWarningContainer;

  /// Text and icons that report success, on the surface.
  final Color success;

  /// The status colours of the current theme.
  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith({
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
  }) => StatusColors(
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    success: success ?? this.success,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
