// End-to-end tests on a device or emulator against a real Waylight server
// (docs/testing.md#integration-tests). The server address comes from
// --dart-define=WAYLIGHT_URL=…; `make integration` passes the public demo.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/main.dart' as app;

const serverUrl = String.fromEnvironment('WAYLIGHT_URL');

/// The password of the server's owner account; the public demo's by
/// default (`make integration`).
const password = String.fromEnvironment('WAYLIGHT_PASSWORD');

/// How long a step may wait for the server. Network requests do not
/// schedule frames, so `pumpAndSettle` alone returns before they finish.
const _serverTimeout = Duration(seconds: 30);

final _address = find.byKey(const ValueKey('connect.address'));
final _submit = find.byKey(const ValueKey('connect.submit'));
final _disconnect = find.byKey(const ValueKey('home.disconnect'));
final _otherServer = find.byKey(const ValueKey('signIn.otherServer'));
final _password = find.byKey(const ValueKey('signIn.password'));
final _signIn = find.byKey(const ValueKey('signIn.submit'));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('connects to the server, signs in and shows the home screen', (
    tester,
  ) async {
    expect(
      serverUrl,
      isNotEmpty,
      reason: 'Pass the server with --dart-define=WAYLIGHT_URL=https://…',
    );
    await app.main();
    await tester.pumpAndSettle();

    // A server and session kept from an earlier run skip the first screens.
    for (final leave in [_disconnect, _otherServer]) {
      if (leave.evaluate().isNotEmpty) {
        await tester.tap(leave);
        await _pumpUntilFound(tester, _address);
      }
    }

    await tester.enterText(_address, serverUrl);
    await tester.tap(_submit);
    await _pumpUntilFound(tester, _password);

    await tester.enterText(_password, password);
    await tester.tap(_signIn);
    await _pumpUntilFound(tester, _disconnect);

    expect(_disconnect, findsOneWidget);
  });
}

/// Pumps frames until [finder] matches or [_serverTimeout] has passed.
Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(_serverTimeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
