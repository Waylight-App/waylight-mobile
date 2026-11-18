import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// A scrollable, centred column with a limited width for simple forms.
class FormPage extends StatelessWidget {
  /// Creates the page with [children] from top to bottom.
  const FormPage({required this.children, super.key});

  /// The content of the form.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimens.gap),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimens.maxFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
