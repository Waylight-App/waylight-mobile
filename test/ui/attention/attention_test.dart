import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/attention/view_models/attention_view_model.dart';
import 'package:waylight_mobile/ui/attention/widgets/attention_screen.dart';
import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_attention_repository.dart';
import '../../testing/fakes/fake_link_opener.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  const immich = AttentionItem(
    id: 'module:immich',
    kind: AttentionKind.connection,
    integration: 'immich',
    title: 'immich',
    message: 'The server rejected the login.',
    action: AttentionAction.fix,
  );
  const grafana = AttentionItem(
    id: 'module:grafana',
    kind: AttentionKind.connection,
    integration: 'grafana',
    title: 'grafana',
    message: 'The service does not answer.',
    action: AttentionAction.check,
  );
  const transit = AttentionItem(
    id: 'widget:w1',
    kind: AttentionKind.setup,
    integration: 'transit',
    widgetId: 'w1',
    tabId: 't-home',
    title: 'transit',
    message: 'Please choose a stop in the widget settings.',
    action: AttentionAction.choose,
    field: 'stopId',
  );

  late FakeAttentionRepository attention;
  late FakeLinkOpener opener;

  AttentionViewModel create() => AttentionViewModel(
    serverRepository: FakeServerRepository(current: testServer()),
    attentionRepository: attention,
  );

  Future<void> pump(WidgetTester tester) async {
    opener = FakeLinkOpener();
    await tester.pumpScreen(
      LinkOpenerScope(
        opener: opener,
        child: AttentionScreen(viewModel: create()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    attention = FakeAttentionRepository(items: [immich, grafana, transit]);
  });

  test('splits the list into broken and not set up', () async {
    final viewModel = create();
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.broken, [immich, grafana]);
    expect(viewModel.setup, [transit]);
    expect(
      viewModel.webUrl(immich).toString(),
      '${testServer().resolve('/')}?settings=immich',
    );
    viewModel.dispose();
  });

  testWidgets('shows both groups with one action per entry', (tester) async {
    await pump(tester);

    expect(find.text(l10nEn.attentionBroken), findsOneWidget);
    expect(find.text(l10nEn.attentionSetup), findsOneWidget);
    expect(find.text('Immich'), findsOneWidget);
    expect(find.text('The service does not answer.'), findsOneWidget);
    expect(find.text(l10nEn.attentionFix), findsOneWidget);
    expect(find.text(l10nEn.attentionCheck), findsOneWidget);
    expect(find.text(l10nEn.attentionChoose), findsOneWidget);
  });

  testWidgets('opens the settings of the integration in the browser', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(
      find.byKey(const ValueKey('attention.action.module:immich')),
    );
    await tester.pumpAndSettle();

    expect(opener.opened.single.queryParameters, {'settings': 'immich'});
  });

  testWidgets('checks again: the entry vanishes once fixed', (tester) async {
    await pump(tester);
    attention.result = const Result.ok([immich, grafana]);

    await tester.tap(
      find.byKey(const ValueKey('attention.action.module:grafana')),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.attentionStillBroken), findsOneWidget);

    attention.result = const Result.ok([immich]);
    await tester.tap(
      find.byKey(const ValueKey('attention.action.module:grafana')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Grafana'), findsNothing);
    expect(find.text(l10nEn.attentionSetup), findsNothing);
  });

  testWidgets('says when everything works', (tester) async {
    attention = FakeAttentionRepository();
    await pump(tester);

    expect(find.byKey(const ValueKey('attention.empty')), findsOneWidget);
  });

  testWidgets('offers a retry when the list cannot be read', (tester) async {
    attention = FakeAttentionRepository()
      ..result = const Result.error(ApiException(ApiFailure.unreachable));
    await pump(tester);

    attention.result = const Result.ok([grafana]);
    await tester.tap(find.byKey(const ValueKey('attention.retry')));
    await tester.pumpAndSettle();
    expect(find.text('Grafana'), findsOneWidget);
  });

  testWidgets('opens the tab of a widget that misses a setting', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: Routes.attention,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) =>
              Text('tab ${state.uri.queryParameters['tab']}'),
        ),
        GoRoute(
          path: Routes.attention,
          builder: (context, state) => AttentionScreen(viewModel: create()),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('attention.action.widget:w1')));
    await tester.pumpAndSettle();

    expect(find.text('tab t-home'), findsOneWidget);
  });
}
