import 'package:material_ui/material_ui.dart';

/// A page transition that fades the new page in, for screens that feel
/// like a mode of the one below rather than a new place, such as the edit
/// mode of the dashboard (#209). Matches the `transitionsBuilder` of
/// go_router's `CustomTransitionPage`.
Widget fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => FadeTransition(opacity: animation, child: child);
