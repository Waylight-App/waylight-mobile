import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/command_button.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/core/widgets/message_banner.dart';
import 'package:waylight_mobile/ui/core/widgets/section_card.dart';
import 'package:waylight_mobile/ui/core/widgets/wordmark.dart';
import 'package:waylight_mobile/ui/home/view_models/home_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The start screen after a server is connected; replaced by the dashboard
/// in #16.
class HomeScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const HomeScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: const Wordmark()),
      body: FormPage(
        children: [
          SectionCard(
            title: l10n.homeServerTitle,
            child: ListenableBuilder(
              listenable: viewModel.load,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.homeConnectedTo(viewModel.server)),
                  const SizedBox(height: Dimens.gapCard),
                  switch (viewModel.load.result) {
                    Ok(:final value) when value.setupRequired => MessageBanner(
                      kind: MessageKind.warning,
                      message: l10n.homeSetupRequired,
                    ),
                    Error(:final error) => MessageBanner(
                      kind: MessageKind.error,
                      message: l10n.errorMessage(error),
                    ),
                    _ => Text(l10n.homeComingSoon),
                  },
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimens.gapLarge),
          CommandButton(
            key: const ValueKey('home.signOut'),
            command: viewModel.signOut,
            onPressed: () => viewModel.signOut.execute().ignore(),
            label: l10n.homeSignOut,
            variant: CommandButtonVariant.outlined,
          ),
          const SizedBox(height: Dimens.gap),
          CommandButton(
            key: const ValueKey('home.disconnect'),
            command: viewModel.disconnect,
            onPressed: () => viewModel.disconnect.execute().ignore(),
            label: l10n.homeDisconnect,
            variant: CommandButtonVariant.text,
          ),
        ],
      ),
    );
  }
}
