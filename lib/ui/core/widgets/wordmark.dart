import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/app_theme.dart';

/// The lamp and the name "Waylight", as above the sign-in card of the web
/// interface (#176): the lamp in the accent colour, the name in the
/// variable Fraunces at weight 700.
class Wordmark extends StatelessWidget {
  /// Creates the wordmark, by default in the size of an app bar title.
  const Wordmark({this.large = false, super.key});

  /// Whether to use the large size of a start screen instead of the size of
  /// an app bar title.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = large
        ? theme.textTheme.headlineSmall
        : theme.textTheme.titleLarge;
    final size = base?.fontSize ?? 22;
    return Semantics(
      label: 'Waylight',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WaylightMark(size: size * 1.1, color: theme.colorScheme.primary),
          SizedBox(width: size * 0.35),
          Text(
            'Waylight',
            style: base?.copyWith(
              fontFamily: AppTheme.wordmarkFont,
              fontFamilyFallback: const ['serif'],
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
            ),
          ),
        ],
      ),
    );
  }
}

/// The Waylight lamp, drawn from the paths of the web's `WaylightMark`
/// (viewBox 28 × 28, round strokes of 2.2).
class WaylightMark extends StatelessWidget {
  /// Creates the lamp in [color].
  const WaylightMark({required this.size, required this.color, super.key});

  /// Width and height.
  final double size;

  /// The stroke colour.
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LampPainter(color));
}

class _LampPainter extends CustomPainter {
  const _LampPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 28);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // M14 3v4
    canvas.drawLine(const Offset(14, 3), const Offset(14, 7), paint);
    // M8 7h12l2 10H6L8 7z – the shade
    canvas.drawPath(
      Path()
        ..moveTo(8, 7)
        ..lineTo(20, 7)
        ..lineTo(22, 17)
        ..lineTo(6, 17)
        ..close(),
      paint,
    );
    // M11 17v2a3 3 0 0 0 6 0v-2 – the bulb
    canvas.drawPath(
      Path()
        ..moveTo(11, 17)
        ..lineTo(11, 19)
        ..arcToPoint(
          const Offset(17, 19),
          radius: const Radius.circular(3),
          clockwise: false,
        )
        ..lineTo(17, 17),
      paint,
    );
    // M3 24h22 – the line of light
    canvas.drawLine(const Offset(3, 24), const Offset(25, 24), paint);
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.color != color;
}
