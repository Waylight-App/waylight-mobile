import 'package:waylight_mobile/data/repositories/household/household_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/household.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [HouseholdRepository] with lists to set and the actions it was asked
/// to run.
class FakeHouseholdRepository implements HouseholdRepository {
  /// The chores.
  List<Chore> choreList = const [];

  /// The dishes.
  List<Meal> mealList = const [];

  /// The gift ideas.
  List<GiftIdea> giftList = const [];

  /// The board notes.
  List<BoardNote> boardList = const [];

  /// The contracts.
  List<Contract> contractList = const [];

  /// The documents.
  List<DocumentRecord> documentList = const [];

  /// The meters.
  List<Meter> meterList = const [];

  /// What every action answers.
  Result<void> actionResult = const Result.ok(null);

  /// The chores ticked off.
  final List<String> done = [];

  /// The gift ideas marked, as `id:bought`.
  final List<String> marked = [];

  /// The readings added, as `id:value`.
  final List<String> readings = [];

  @override
  Future<Result<List<Chore>>> chores(ServerAddress server) async =>
      Result.ok(choreList);

  @override
  Future<Result<void>> markChoreDone(ServerAddress server, String id) async {
    done.add(id);
    return actionResult;
  }

  @override
  Future<Result<List<Meal>>> meals(
    ServerAddress server, {
    required DateTime from,
    int days = 7,
  }) async => Result.ok(mealList);

  @override
  Future<Result<List<GiftIdea>>> gifts(ServerAddress server) async =>
      Result.ok(giftList);

  @override
  Future<Result<void>> setGiftBought(
    ServerAddress server,
    GiftIdea idea, {
    required bool bought,
  }) async {
    marked.add('${idea.id}:$bought');
    return actionResult;
  }

  @override
  Future<Result<List<BoardNote>>> board(ServerAddress server) async =>
      Result.ok(boardList);

  @override
  Future<Result<List<Contract>>> contracts(ServerAddress server) async =>
      Result.ok(contractList);

  @override
  Future<Result<List<DocumentRecord>>> documents(ServerAddress server) async =>
      Result.ok(documentList);

  @override
  Future<Result<List<Meter>>> meters(ServerAddress server) async =>
      Result.ok(meterList);

  @override
  Future<Result<void>> addReading(
    ServerAddress server,
    String id, {
    required DateTime day,
    required double value,
  }) async {
    readings.add('$id:$value');
    return actionResult;
  }
}

/// A failed action.
const failedAction = Result<void>.error(ApiException(ApiFailure.server));
