import 'package:waylight_mobile/data/repositories/announcements/announcements_repository.dart';
import 'package:waylight_mobile/domain/models/announcement.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// An [AnnouncementsRepository] in memory.
class FakeAnnouncementsRepository implements AnnouncementsRepository {
  /// What [list] returns.
  Result<List<Announcement>> result = const Result.ok([]);

  /// What [mayWrite] answers.
  bool writer = false;

  /// What the changes return.
  Result<void> changeResult = const Result.ok(null);

  /// The calls, such as `read:a1` or `create`.
  final List<String> calls = [];

  @override
  Future<Result<List<Announcement>>> list(ServerAddress server) async => result;

  @override
  Future<Result<bool>> mayWrite(ServerAddress server) async =>
      Result.ok(writer);

  @override
  Future<Result<void>> markRead(ServerAddress server, String id) async {
    calls.add('read:$id');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> create(
    ServerAddress server,
    AnnouncementInput input,
  ) async {
    calls.add('create:${input.title}');
    return changeResult;
  }

  @override
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    AnnouncementInput input,
  ) async {
    calls.add('update:$id');
    return changeResult;
  }

  @override
  Future<Result<void>> delete(ServerAddress server, String id) async {
    calls.add('delete:$id');
    return changeResult;
  }
}
