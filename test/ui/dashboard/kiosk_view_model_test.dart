import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/kiosk/kiosk_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/dashboard.dart';
import 'package:waylight_mobile/ui/dashboard/view_models/kiosk_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_dashboard_repository.dart';
import '../../testing/fakes/fake_device_auth.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/fakes/in_memory_key_value_store.dart';

/// Rotation and night dimming of the wall display (#193).
void main() {
  testWidgets('rotates the tabs and dims at night as the options say', (
    tester,
  ) async {
    {
      var now = DateTime(2026, 11, 21, 21, 58);
      final servers = FakeServerRepository();
      final kiosk = KioskRepository(
        servers: servers,
        sessions: FakeSessionRepository(),
        api: ModuleApi(
          ApiClient(
            client: MockClient(
              (_) async => http.Response(
                '{"rotateSeconds":20,"nightFrom":"22:00","nightTo":"06:00"}',
                200,
              ),
            ),
          ),
        ),
        store: InMemoryKeyValueStore(),
        auth: FakeDeviceAuth(),
      );
      await kiosk.enter('https://home.example.org/kiosk#t');
      await tester.pump();
      final dashboard = FakeDashboardRepository()
        ..result = const Result.ok(
          Dashboard(
            tabs: [
              DashboardTab(id: 'a', name: 'A', widgets: []),
              DashboardTab(id: 'b', name: 'B', widgets: []),
            ],
          ),
        );
      final vm = KioskViewModel(
        servers: servers,
        dashboard: dashboard,
        kiosk: kiosk,
        now: () => now,
      );
      await tester.pump();
      expect(vm.tabs, hasLength(2));
      expect(vm.index, 0);
      await tester.pump(const Duration(seconds: 20));
      expect(vm.index, 1);
      await tester.pump(const Duration(seconds: 20));
      expect(vm.index, 0, reason: 'wraps around');

      expect(vm.night, isFalse);
      now = DateTime(2026, 11, 21, 22, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(vm.night, isTrue);
      vm.dispose();
      kiosk.dispose();
    }
  });
}
