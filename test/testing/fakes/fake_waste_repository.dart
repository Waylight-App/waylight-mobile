import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [WasteRepository] without network for tests.
class FakeWasteRepository implements WasteRepository {
  /// What [upcoming] returns; an empty list by default.
  Result<List<WasteCollection>> result = const Result.ok([]);

  /// The arguments of every call.
  final List<String> calls = [];

  @override
  Future<Result<List<WasteCollection>>> upcoming(ServerAddress server) async {
    calls.add(server.toString());
    return result;
  }

  /// What [subscribe] returns.
  Result<void> subscribeResult = const Result.ok(null);

  /// The calendar addresses passed to [subscribe].
  final List<String> subscribed = [];

  @override
  Future<Result<void>> subscribe(ServerAddress server, String url) async {
    subscribed.add(url);
    return subscribeResult;
  }
}
