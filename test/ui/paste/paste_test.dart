import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/data/repositories/setup_paste/setup_paste_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/ui/paste/view_models/paste_view_model.dart';
import 'package:waylight_mobile/ui/paste/widgets/paste_screen.dart';

import '../../testing/fakes/fake_barcode_scanner.dart';
import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  const code = 'waylight://paste?server=https://home.example.org&code=abc';

  late FakeBarcodeScanner scanner;
  late List<http.Request> requests;
  late http.Response answer;

  setUp(() {
    scanner = FakeBarcodeScanner(next: code);
    requests = [];
    answer = http.Response('', 204);
  });

  PasteViewModel viewModel({String server = '', String code = ''}) =>
      PasteViewModel(
        server: server,
        code: code,
        serverRepository: FakeServerRepository(current: testServer()),
        pasteRepository: SetupPasteRepository(
          api: ModuleApi(
            ApiClient(
              client: MockClient((request) async {
                requests.add(request);
                return answer;
              }),
            ),
          ),
          scanner: scanner,
        ),
      );

  testWidgets('scans the code, sends the value and reports success', (
    tester,
  ) async {
    await tester.pumpScreen(PasteScreen(viewModel: viewModel()));
    await tester.tap(find.byKey(const ValueKey('paste.scan')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.pasteTarget('home.example.org')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('paste.value')),
      ' s3cret ',
    );
    await tester.tap(find.byKey(const ValueKey('paste.send')));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'PUT');
    expect(
      requests.single.url.toString(),
      'https://home.example.org/api/setup/paste/abc',
    );
    expect(jsonDecode(requests.single.body), {'value': 's3cret'});
    expect(find.text(l10nEn.pasteDone), findsOneWidget);
    expect(find.byKey(const ValueKey('paste.send')), findsNothing);
  });

  testWidgets('opens with the parts of a link', (tester) async {
    await tester.pumpScreen(
      PasteScreen(
        viewModel: viewModel(server: 'https://home.example.org', code: 'abc'),
      ),
    );

    expect(find.byKey(const ValueKey('paste.value')), findsOneWidget);
  });

  testWidgets('explains a link that cannot be used', (tester) async {
    await tester.pumpScreen(
      PasteScreen(
        viewModel: viewModel(server: 'ftp://x.example.org', code: 'a'),
      ),
    );

    expect(find.text(l10nEn.pasteInvalidCode), findsOneWidget);
    expect(find.byKey(const ValueKey('paste.value')), findsNothing);
  });

  testWidgets('does not contact a server the app is not connected to', (
    tester,
  ) async {
    scanner.next = 'waylight://paste?server=https://evil.example.org&code=abc';
    await tester.pumpScreen(PasteScreen(viewModel: viewModel()));
    await tester.tap(find.byKey(const ValueKey('paste.scan')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('paste.value')), 'x');
    await tester.tap(find.byKey(const ValueKey('paste.send')));
    await tester.pumpAndSettle();

    expect(requests, isEmpty);
    expect(find.text(l10nEn.pasteOtherServer), findsOneWidget);
  });

  testWidgets('says when the code has expired and keeps the code', (
    tester,
  ) async {
    answer = http.Response(
      '{"error":{"code":"invalid","message":"The code has expired."}}',
      422,
    );
    await tester.pumpScreen(PasteScreen(viewModel: viewModel()));
    await tester.tap(find.byKey(const ValueKey('paste.scan')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('paste.value')), 'x');
    await tester.tap(find.byKey(const ValueKey('paste.send')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.pasteExpired), findsOneWidget);
  });

  testWidgets('explains a code that is not from the assistant', (tester) async {
    scanner.next = 'https://example.org';
    await tester.pumpScreen(PasteScreen(viewModel: viewModel()));
    await tester.tap(find.byKey(const ValueKey('paste.scan')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.pasteInvalidCode), findsOneWidget);
  });

  testWidgets('says when the phone cannot scan', (tester) async {
    scanner.isAvailable = false;
    await tester.pumpScreen(PasteScreen(viewModel: viewModel()));
    await tester.pump();

    expect(find.text(l10nEn.pasteUnavailable), findsOneWidget);
    expect(find.byKey(const ValueKey('paste.scan')), findsNothing);
  });
}
