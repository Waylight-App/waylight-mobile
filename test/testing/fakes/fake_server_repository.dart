import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/server_status.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [ServerRepository] without network and storage for tests.
class FakeServerRepository extends ServerRepository {
  /// Creates the fake, optionally already connected to [current].
  FakeServerRepository({this._current});

  ServerAddress? _current;

  /// What [connect] and [status] return; a successful status by default.
  Result<ServerStatus> statusResult = const Result.ok(
    ServerStatus(setupRequired: false),
  );

  /// The addresses [connect] was called with.
  final List<ServerAddress> connectCalls = [];

  @override
  ServerAddress? get current => _current;

  @override
  Future<Result<void>> restore() async => const Result.ok(null);

  @override
  Future<Result<ServerStatus>> connect(ServerAddress server) async {
    connectCalls.add(server);
    if (statusResult case Ok()) {
      _current = server;
      notifyListeners();
    }
    return statusResult;
  }

  @override
  Future<Result<ServerStatus>> status() async => statusResult;

  /// What [version] returns.
  Result<String> versionResult = const Result.ok('1.2.3');

  @override
  Future<Result<String>> version() async => versionResult;

  @override
  Future<Result<void>> disconnect() async {
    _current = null;
    notifyListeners();
    return const Result.ok(null);
  }
}

/// A valid address for tests.
ServerAddress testServer([String address = 'https://home.example.org']) =>
    switch (ServerAddress.parse(address)) {
      Ok(:final value) => value,
      Error(:final error) => throw ArgumentError(error),
    };
