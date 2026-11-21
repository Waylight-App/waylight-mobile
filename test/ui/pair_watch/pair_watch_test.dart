import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/watch/watch_pairing_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/data/services/watch/watch_handover.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/watch_link.dart';
import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/pair_watch/view_models/pair_watch_view_model.dart';
import 'package:waylight_mobile/ui/pair_watch/widgets/pair_watch_screen.dart';

import '../../testing/fakes/fake_barcode_scanner.dart';
import '../../testing/fakes/fake_handover_sealer.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  const code =
      'waylight://watch?addr=192.168.1.23:41234&key=AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8';

  late FakeBarcodeScanner scanner;
  late int watchStatus;

  setUp(() {
    scanner = FakeBarcodeScanner(next: code);
    watchStatus = 204;
  });

  PairWatchViewModel viewModel() => PairWatchViewModel(
    serverRepository: FakeServerRepository(current: testServer()),
    watchRepository: WatchPairingRepository(
      api: ModuleApi(
        ApiClient(
          client: MockClient(
            (_) async => http.Response('{"code":"c0de"}', 201),
          ),
        ),
      ),
      scanner: scanner,
      sealer: FakeHandoverSealer(),
      watch: WatchClient(
        MockClient((_) async => http.Response('', watchStatus)),
      ),
    ),
  );

  testWidgets('scans the watch, asks to pair and reports success', (
    tester,
  ) async {
    await tester.pumpScreen(PairWatchScreen(viewModel: viewModel()));

    expect(find.text(l10nEn.pairWatchIntro), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pairWatch.scan')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.pairWatchFound('192.168.1.23:41234')), findsOne);

    await tester.tap(find.byKey(const ValueKey('pairWatch.pair')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.pairWatchDone), findsOneWidget);
    expect(find.byKey(const ValueKey('pairWatch.pair')), findsNothing);
  });

  testWidgets("shows the watch's refusal and keeps the watch", (tester) async {
    watchStatus = 401;
    await tester.pumpScreen(PairWatchScreen(viewModel: viewModel()));
    await tester.tap(find.byKey(const ValueKey('pairWatch.scan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pairWatch.pair')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.pairWatchRejected), findsOneWidget);
    expect(find.byKey(const ValueKey('pairWatch.pair')), findsOneWidget);
  });

  testWidgets('explains a code that is not from a watch', (tester) async {
    scanner.next = 'https://example.org';
    await tester.pumpScreen(PairWatchScreen(viewModel: viewModel()));
    await tester.tap(find.byKey(const ValueKey('pairWatch.scan')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.pairWatchInvalidCode), findsOneWidget);
  });

  testWidgets('says when the phone cannot scan', (tester) async {
    scanner.isAvailable = false;
    await tester.pumpScreen(PairWatchScreen(viewModel: viewModel()));
    await tester.pump();

    expect(find.text(l10nEn.pairWatchUnavailable), findsOneWidget);
    expect(find.byKey(const ValueKey('pairWatch.scan')), findsNothing);
  });

  test('every failure has its own message', () {
    final messages = {
      for (final failure in WatchPairingFailure.values)
        pairWatchError(l10nEn, WatchPairingException(failure)),
    };
    expect(messages, hasLength(WatchPairingFailure.values.length));
    expect(
      pairWatchError(l10nEn, const ApiException(ApiFailure.unreachable)),
      l10nEn.errorMessage(const ApiException(ApiFailure.unreachable)),
    );
  });
}
