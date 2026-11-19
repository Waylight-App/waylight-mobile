import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/actions/summary_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/ui/widgets/common/summary_button.dart';

import '../../../testing/fakes/fake_action_repositories.dart';
import '../../../testing/fakes/fake_server_repository.dart';
import '../../../testing/pump_app.dart';

void main() {
  Future<FakeSummaryRepository> pump(
    WidgetTester tester, {
    required bool configured,
  }) async {
    final summary = FakeSummaryRepository()..configured = configured;
    await tester.pumpScreen(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerRepository>.value(
            value: FakeServerRepository(current: testServer()),
          ),
          Provider<SummaryRepository>.value(value: summary),
        ],
        child: SummaryButton(url: Uri.parse('https://example.org/a')),
      ),
    );
    await tester.pumpAndSettle();
    return summary;
  }

  testWidgets('summarises the page when the server has summaries', (
    tester,
  ) async {
    final summary = await pump(tester, configured: true);
    await tester.tap(find.byTooltip(l10nEn.summaryAction));
    await tester.pumpAndSettle();
    expect(summary.calls, ['summarise:https://example.org/a']);
    expect(find.text('In short: keep three copies.'), findsOneWidget);
    expect(find.text(l10nEn.summaryByAi), findsOneWidget);
  });

  testWidgets('is hidden without summaries', (tester) async {
    await pump(tester, configured: false);
    expect(find.byTooltip(l10nEn.summaryAction), findsNothing);
  });
}
