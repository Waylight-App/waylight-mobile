import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/ui/sign_in/view_models/sign_in_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_server_repository.dart';
import '../../testing/fakes/fake_session_repository.dart';

void main() {
  late FakeServerRepository servers;
  late FakeSessionRepository sessions;

  SignInViewModel create() =>
      SignInViewModel(serverRepository: servers, sessionRepository: sessions);

  setUp(() {
    servers = FakeServerRepository(current: testServer());
    sessions = FakeSessionRepository();
  });

  test('signs in with the entered credentials', () async {
    final viewModel = create();

    await viewModel.signIn.execute((
      username: 'anna',
      password: 'pw',
      code: '',
    ));

    expect(sessions.signedIn, isTrue);
    expect(sessions.signInCalls.single.username, 'anna');
  });

  test('switches to the code step when the server asks', () async {
    sessions.signInResult = const Result.ok(
      CodeRequired(authenticatorApp: true),
    );
    final viewModel = create();
    var notified = false;
    viewModel.addListener(() => notified = true);

    await viewModel.signIn.execute((username: '', password: 'pw', code: ''));

    expect(viewModel.codeRequired?.authenticatorApp, isTrue);
    expect(notified, isTrue);
  });

  test('reports errors through the command', () async {
    sessions.signInResult = const Result.error(
      ApiException(ApiFailure.unauthorized),
    );
    final viewModel = create();

    await viewModel.signIn.execute((username: '', password: 'pw', code: ''));

    expect(viewModel.signIn.error, isTrue);
    expect(viewModel.codeRequired, isNull);
  });

  test('says whether the previous session expired', () {
    sessions.expired = true;

    expect(create().expired, isTrue);
  });

  test('forgets the server on request', () async {
    final viewModel = create();

    await viewModel.useAnotherServer.execute();

    expect(servers.current, isNull);
  });
}
