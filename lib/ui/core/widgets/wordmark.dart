import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/app_theme.dart';

/// The name "Waylight" set as the wordmark, as on the sign-in card of the
/// web interface.
class Wordmark extends StatelessWidget {
  /// Creates the wordmark, by default in the size of an app bar title.
  const Wordmark({this.large = false, super.key});

  /// Whether to use the large size of a start screen instead of the size of
  /// an app bar title.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final base = large ? textTheme.headlineSmall : textTheme.titleLarge;
    return Text(
      'Waylight',
      semanticsLabel: 'Waylight',
      style: base?.copyWith(
        fontFamily: AppTheme.wordmarkFont,
        fontFamilyFallback: const ['serif'],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
