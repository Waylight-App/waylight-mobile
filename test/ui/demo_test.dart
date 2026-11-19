import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/ui/connect_server/widgets/connect_server_screen.dart';
import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:waylight_mobile/ui/dashboard/widgets/dashboard_screen.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/ui/sign_in/widgets/sign_in_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../testing/fakes/fake_dashboard_repository.dart';
import '../testing/fakes/fake_server_repository.dart';
import '../testing/fakes/fake_session_repository.dart';
import '../testing/pump_app.dart';

void main() {
  const demoStatus = Result<ServerStatus>.ok(
    ServerStatus(
      setupRequired: false,
      demo: true,
      demoPassword: 'waylight-demo',
    ),
  );

  test('connects the public demo', () async {
    final servers = FakeServerRepository();
    final viewModel = ConnectServerViewModel(serverRepository: servers);

    await viewModel.tryDemo();

    expect(servers.current.toString(), ConnectServerViewModel.demoAddress);
    viewModel.dispose();
  });

  testWidgets('fills in the public password of the demo', (tester) async {
    final servers = FakeServerRepository(current: testServer())
      ..statusResult = demoStatus;
    await tester.pumpScreen(
      SignInScreen(
        viewModel: SignInViewModel(
          serverRepository: servers,
          sessionRepository: FakeSessionRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('waylight-demo'), findsOneWidget);
  });

  testWidgets('leaves the password empty elsewhere', (tester) async {
    await tester.pumpScreen(
      SignInScreen(
        viewModel: SignInViewModel(
          serverRepository: FakeServerRepository(current: testServer()),
          sessionRepository: FakeSessionRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('waylight-demo'), findsNothing);
  });

  testWidgets('says on the dashboard that it is the demo', (tester) async {
    final servers = FakeServerRepository(current: testServer())
      ..statusResult = demoStatus;
    final dashboards = FakeDashboardRepository()
      ..result = const Result.ok(
        Dashboard(
          tabs: [DashboardTab(id: 't', name: 'Home', widgets: [])],
        ),
      );
    await tester.pumpScreen(
      DashboardScreen(
        viewModel: DashboardViewModel(
          serverRepository: servers,
          dashboardRepository: dashboards,
        ),
        registry: const WidgetRegistry({}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.dashboardDemo), findsOneWidget);
  });

  testWidgets('offers the demo on the connect screen', (tester) async {
    final servers = FakeServerRepository();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpScreen(
      ConnectServerScreen(
        viewModel: ConnectServerViewModel(serverRepository: servers),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('connect.demo')));
    await tester.pumpAndSettle();

    expect(
      servers.connectCalls.single.toString(),
      ConnectServerViewModel.demoAddress,
    );
  });
}
