import 'package:waylight_mobile/data/repositories/actions/parcels_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Records the calls of the action fakes and fails them with [fail].
mixin _Calls {
  /// The calls, such as `read:<id>`.
  final List<String> calls = [];

  /// The error every change fails with, if any.
  Exception? fail;

  Result<void> _record(String call) {
    calls.add(call);
    if (fail case final e?) return Result.error(e);
    return const Result.ok(null);
  }
}

/// An [RssRepository] in memory.
class FakeRssRepository with _Calls implements RssRepository {
  /// The items.
  List<FeedArticle> articles = [];

  @override
  Future<Result<List<FeedArticle>>> items(
    ServerAddress server, {
    String feedId = '',
    bool unreadOnly = true,
    int limit = 20,
  }) async => Result.ok(articles);

  @override
  Future<Result<void>> setRead(
    ServerAddress server,
    String id, {
    required bool read,
  }) async => _record('${read ? 'read' : 'unread'}:$id');
}

/// A [ParcelsRepository] in memory.
class FakeParcelsRepository with _Calls implements ParcelsRepository {
  /// The parcels.
  List<Parcel> list = [];

  @override
  Future<Result<List<Parcel>>> parcels(ServerAddress server) async =>
      Result.ok(list);

  @override
  Future<Result<Parcel>> add(
    ServerAddress server,
    String trackingNumber, {
    String carrier = '',
    String label = '',
  }) async {
    if (_record('add:$trackingNumber') case Error(:final error)) {
      return Result.error(error);
    }
    return Result.ok(
      Parcel(
        id: 'new',
        trackingNumber: trackingNumber,
        carrier: 'dhl',
        status: ParcelStatus.preTransit,
        label: label,
      ),
    );
  }

  @override
  Future<Result<void>> remove(ServerAddress server, String id) async =>
      _record('remove:$id');
}

/// A [SmartHomeRepository] in memory.
class FakeSmartHomeRepository with _Calls implements SmartHomeRepository {
  /// The entities.
  List<SmartEntity> list = [];

  @override
  Future<Result<List<SmartEntity>>> entities(
    ServerAddress server, {
    List<String> ids = const [],
  }) async => Result.ok(list);

  @override
  Future<Result<void>> act(ServerAddress server, String id) async =>
      _record('act:$id');
}
