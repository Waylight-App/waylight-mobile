import 'package:waylight_mobile/data/repositories/actions/focus_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/parcels_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/calendar/calendar_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/information.dart';
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

/// A [FocusRepository] in memory.
class FakeFocusRepository with _Calls implements FocusRepository {
  @override
  Future<Result<void>> save(
    ServerAddress server, {
    required int minutes,
    required DateTime endedAt,
  }) async => _record('save:$minutes');
}

/// A [HomeServerActionsRepository] in memory.
class FakeHomeServerActions with _Calls implements HomeServerActionsRepository {
  /// The containers that may be restarted.
  DockerActions docker = const DockerActions();

  @override
  Future<Result<void>> wake(ServerAddress server, String serviceId) async =>
      _record('wake:$serviceId');

  @override
  Future<Result<DockerActions>> dockerActions(ServerAddress server) async =>
      Result.ok(docker);

  @override
  Future<Result<void>> restart(ServerAddress server, String container) async =>
      _record('restart:$container');

  @override
  Future<Result<List<String>>> logs(
    ServerAddress server,
    String container,
  ) async => const Result.ok(['line 1', 'line 2']);

  @override
  Future<Result<void>> powerGuest(
    ServerAddress server,
    int guestId,
    String action,
  ) async => _record('$action:$guestId');

  @override
  Future<Result<void>> pauseDnsFilter(
    ServerAddress server,
    int minutes,
  ) async => _record('pause:$minutes');
}

/// A [CalendarRepository] in memory.
class FakeCalendarRepository with _Calls implements CalendarRepository {
  /// The agenda.
  List<CalendarEvent> events = [];

  /// The writable calendars.
  List<WritableCalendar> calendars = const [
    WritableCalendar(id: 'c1', name: 'Family'),
  ];

  /// The events created.
  final List<NewEvent> created = [];

  @override
  Future<Result<List<CalendarEvent>>> agenda(
    ServerAddress server,
    int days,
  ) async => Result.ok(events);

  @override
  Future<Result<List<WritableCalendar>>> writable(ServerAddress server) async =>
      Result.ok(calendars);

  @override
  Future<Result<void>> create(ServerAddress server, NewEvent event) async {
    created.add(event);
    return _record('create:${event.summary}');
  }
}
