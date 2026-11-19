import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/ui/lock/view_models/lock_view_model.dart';

/// Covers the app until it is unlocked (#46). It asks at once, and again on
/// the button when the person cancelled.
class LockScreen extends StatefulWidget {
  /// Creates the screen for [viewModel].
  const LockScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final LockViewModel viewModel;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.viewModel.unlock.result == null &&
        !widget.viewModel.unlock.running) {
      final reason = context.l10n.lockReason;
      // After the first frame, so the system prompt has a screen below it.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.viewModel.unlock.execute(reason).ignore(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: FormPage(
        children: [
          const Wordmark(large: true),
          const SizedBox(height: Dimens.gapLarge),
          Text(
            l10n.lockTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Dimens.gapLarge),
          CommandButton(
            key: const ValueKey('lock.unlock'),
            command: widget.viewModel.unlock,
            onPressed: () =>
                widget.viewModel.unlock.execute(l10n.lockReason).ignore(),
            label: l10n.lockUnlock,
          ),
        ],
      ),
    );
  }
}
