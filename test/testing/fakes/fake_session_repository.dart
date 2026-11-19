import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/sign_in_result.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [SessionRepository] without network and storage for tests.
class FakeSessionRepository extends SessionRepository {
  /// Creates the fake, optionally already [signedIn].
  FakeSessionRepository({this.signedIn = false, this.expired = false});

  @override
  bool signedIn;

  @override
  bool expired;

  /// What [signIn] returns; signed in by default.
  Result<SignInResult> signInResult = const Result.ok(SignedIn());

  /// The arguments of every [signIn] call.
  final List<({String username, String password, String code})> signInCalls =
      [];

  /// How often [signOut] was called.
  int signOutCalls = 0;

  @override
  Future<Result<void>> restore(ServerAddress? server) async =>
      const Result.ok(null);

  @override
  Future<Result<SignInResult>> signIn(
    ServerAddress server, {
    String username = '',
    required String password,
    String code = '',
  }) async {
    signInCalls.add((username: username, password: password, code: code));
    if (signInResult case Ok(value: SignedIn())) {
      signedIn = true;
      notifyListeners();
    }
    return signInResult;
  }

  /// What [pair] returns; signed in by default.
  Result<void> pairResult = const Result.ok(null);

  /// The codes [pair] was called with.
  final List<String> pairCalls = [];

  @override
  Future<Result<void>> pair(ServerAddress server, String code) async {
    pairCalls.add(code);
    if (pairResult case Ok()) {
      signedIn = true;
      notifyListeners();
    }
    return pairResult;
  }

  @override
  Future<Result<void>> signOut() async {
    signOutCalls++;
    signedIn = false;
    notifyListeners();
    return const Result.ok(null);
  }
}
