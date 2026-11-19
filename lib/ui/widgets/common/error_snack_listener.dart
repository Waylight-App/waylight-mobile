import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';

/// Shows a refused change of a widget as a snack bar.
///
/// Widget view models keep the last failure until it is taken; this listens
/// to the view model and takes it, so every widget reports failures the
/// same way.
class ErrorSnackListener extends StatefulWidget {
  /// Creates the listener.
  const ErrorSnackListener({
    required this.listenable,
    required this.takeError,
    required this.child,
    super.key,
  });

  /// The view model.
  final Listenable listenable;

  /// Returns the failure once, then `null`.
  final Exception? Function() takeError;

  /// The widget's content.
  final Widget child;

  @override
  State<ErrorSnackListener> createState() => _ErrorSnackListenerState();
}

class _ErrorSnackListenerState extends State<ErrorSnackListener> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_show);
  }

  @override
  void didUpdateWidget(ErrorSnackListener old) {
    super.didUpdateWidget(old);
    if (old.listenable != widget.listenable) {
      old.listenable.removeListener(_show);
      widget.listenable.addListener(_show);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_show);
    super.dispose();
  }

  void _show() {
    final error = widget.takeError();
    if (error == null || !mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(error))));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
