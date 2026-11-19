import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/routing/router.dart';
import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/pair/view_models/pair_view_model.dart';
import 'package:waylight_mobile/ui/pair/widgets/pair_screen.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';
import '../../testing/pump_app.dart';

void main() {
  late FakeServerRepository servers;
  late FakeSessionRepository sessions;

  setUp(() {
    servers = FakeServerRepository();
    sessions = FakeSessionRepository();
  });

  Future<PairViewModel> pair(String server, String code) async {
    final viewModel = PairViewModel(
      server: server,
      code: code,
      serverRepository: servers,
      sessionRepository: sessions,
    );
    // The view model starts pairing itself; wait until that run is done.
    while (viewModel.pair.result == null) {
      await Future<void>.delayed(Duration.zero);
    }
    return viewModel;
  }

  test('connects the server of the link and redeems the code', () async {
    final viewModel = await pair('https://home.example.org', 'c0de');

    expect(viewModel.pair.result, isA<Ok<void>>());
    expect(servers.current, testServer());
    expect(sessions.pairCalls, ['c0de']);
    expect(sessions.signedIn, isTrue);
  });

  test('keeps an already connected server', () async {
    servers = FakeServerRepository(current: testServer());
    await pair('https://home.example.org', 'c0de');

    expect(servers.connectCalls, isEmpty);
  });

  test('rejects incomplete links and public plain HTTP', () async {
    for (final (server, code) in [
      ('', 'c0de'),
      ('https://home.example.org', ''),
      ('http://home.example.org', 'c0de'),
    ]) {
      final viewModel = await pair(server, code);
      expect(
        pairError(l10nEn, (viewModel.pair.result! as Error<void>).error),
        l10nEn.pairInvalidLink,
        reason: '$server $code',
      );
    }
    expect(sessions.pairCalls, isEmpty);
  });

  test('explains a used or expired code', () {
    expect(
      pairError(l10nEn, const ApiException(ApiFailure.unauthorized)),
      l10nEn.pairCodeInvalid,
    );
    expect(
      pairError(
        l10nEn,
        const InvalidServerAddress(InvalidServerAddressReason.malformed),
      ),
      l10nEn.pairInvalidLink,
    );
  });

  test('pairing links open without server or session', () {
    String? at(String link, {bool connected = false, bool signedIn = false}) =>
        redirectFor(
          uri: Uri.parse(link),
          connected: connected,
          signedIn: signedIn,
        );

    expect(
      at('waylight://pair?server=https%3A%2F%2Fh.example.org&code=x'),
      '/pair?server=https%3A%2F%2Fh.example.org&code=x',
    );
    expect(at('/pair?code=x'), isNull);
    expect(at('/pair?code=x', connected: true, signedIn: true), Routes.home);
  });

  testWidgets('shows the error and offers manual entry', (tester) async {
    sessions.pairResult = const Result.error(
      ApiException(ApiFailure.unauthorized),
    );
    final viewModel = PairViewModel(
      server: 'https://home.example.org',
      code: 'c0de',
      serverRepository: servers,
      sessionRepository: sessions,
    );
    await tester.pumpScreen(PairScreen(viewModel: viewModel));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.pairCodeInvalid), findsOneWidget);
    expect(find.text(l10nEn.pairEnterManually), findsOneWidget);
  });
}
