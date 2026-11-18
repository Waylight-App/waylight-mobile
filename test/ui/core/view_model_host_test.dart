import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/widgets/view_model_host.dart';

class _CountingViewModel extends ChangeNotifier {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

void main() {
  testWidgets('creates the view model once and disposes it with the screen', (
    tester,
  ) async {
    final created = <_CountingViewModel>[];
    Widget host() => ViewModelHost<_CountingViewModel>(
      create: (_) {
        final viewModel = _CountingViewModel();
        created.add(viewModel);
        return viewModel;
      },
      builder: (_, viewModel) => const SizedBox(),
    );

    await tester.pumpWidget(host());
    await tester.pumpWidget(host());

    expect(created, hasLength(1), reason: 'a rebuild keeps the view model');

    await tester.pumpWidget(const SizedBox());

    expect(created.single.disposed, isTrue);
  });
}
