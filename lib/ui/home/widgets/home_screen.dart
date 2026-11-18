import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/ui/core/widgets/form_page.dart';
import 'package:waylight_mobile/ui/home/view_models/home_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The start screen after a server is connected.
class HomeScreen extends StatelessWidget {
  /// Creates the screen for [viewModel].
  const HomeScreen({required this.viewModel, super.key});

  /// The state and actions of this screen.
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: FormPage(
        children: [
          Text(l10n.homeConnectedTo(viewModel.server)),
          const SizedBox(height: Dimens.gap),
          ListenableBuilder(
            listenable: viewModel.load,
            builder: (context, _) => switch (viewModel.load.result) {
              Ok(:final value) when value.setupRequired => Text(
                l10n.homeSetupRequired,
              ),
              _ => Text(l10n.homeComingSoon),
            },
          ),
          const SizedBox(height: Dimens.gapLarge),
          OutlinedButton(
            key: const ValueKey('home.disconnect'),
            onPressed: () => viewModel.disconnect.execute().ignore(),
            child: Text(l10n.homeDisconnect),
          ),
        ],
      ),
    );
  }
}
