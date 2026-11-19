import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/share/view_models/share_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Saves text or a link shared from another app (#21) to a module of the
/// server.
class ShareScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const ShareScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final ShareViewModel viewModel;

  String _label(BuildContext context, ShareTarget t) => switch (t) {
    ShareTarget.todo => context.l10n.shareTodo,
    ShareTarget.note => context.l10n.shareNote,
    ShareTarget.readLater => context.l10n.readLaterTitle,
    ShareTarget.bookmark => context.l10n.bookmarkAdd,
    ShareTarget.drop => context.l10n.dropTitle,
  };

  IconData _icon(ShareTarget t) => switch (t) {
    ShareTarget.todo => Icons.check_box_outlined,
    ShareTarget.note => Icons.notes,
    ShareTarget.readLater => Icons.chrome_reader_mode_outlined,
    ShareTarget.bookmark => Icons.bookmark_add_outlined,
    ShareTarget.drop => Icons.move_to_inbox_outlined,
  };

  Future<void> _save(BuildContext context, ShareTarget target) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await viewModel.save.execute(target);
    if (!context.mounted) return;
    switch (viewModel.save.result) {
      case Error(:final error):
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(error))),
        );
      default:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.shareSaved(_label(context, target)))),
        );
        context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load, viewModel.save]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.shareTitle)),
        body: ListView(
          padding: const EdgeInsets.all(Dimens.gap),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Dimens.gapCard),
                child: Text(
                  viewModel.text,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: Dimens.gap),
            if (viewModel.load.result case Error(:final error))
              Text(l10n.errorMessage(error))
            else if (viewModel.load.running)
              const Center(child: CircularProgressIndicator())
            else
              for (final t in viewModel.targets)
                ListTile(
                  leading: Icon(_icon(t)),
                  title: Text(_label(context, t)),
                  enabled: !viewModel.save.running,
                  onTap: () => _save(context, t),
                ),
          ],
        ),
      ),
    );
  }
}
