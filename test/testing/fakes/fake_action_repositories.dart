import 'package:waylight_mobile/data/repositories/account/account_security_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/drop_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/focus_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/parcels_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/read_later_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/rss_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/actions/summary_repository.dart';
import 'package:waylight_mobile/data/repositories/calendar/calendar_repository.dart';
import 'package:waylight_mobile/data/repositories/push/push_repository.dart';
import 'package:waylight_mobile/domain/models/account_security.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/information.dart';
import 'package:waylight_mobile/domain/models/media.dart';
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

  /// The feeds.
  List<RssFeed> feedList = [];

  @override
  Future<Result<List<RssFeed>>> feeds(ServerAddress server) async =>
      Result.ok(feedList);

  @override
  Future<Result<void>> markAllRead(
    ServerAddress server, {
    String feedId = '',
  }) async => _record('all:$feedId');

  @override
  Future<Result<void>> refresh(ServerAddress server) async =>
      _record('refresh');
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

  /// The error reading the entities fails with, if any.
  Exception? readFail;

  @override
  Future<Result<List<SmartEntity>>> entities(
    ServerAddress server, {
    List<String> ids = const [],
  }) async => switch (readFail) {
    final e? => Result.error(e),
    null => Result.ok(list),
  };

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

/// A [ReadLaterRepository] in memory.
class FakeReadLaterRepository with _Calls implements ReadLaterRepository {
  /// The articles.
  List<Article> list = [];

  @override
  Future<Result<List<Article>>> articles(ServerAddress server) async =>
      Result.ok(list);

  @override
  Future<Result<Article>> article(ServerAddress server, String id) async =>
      Result.ok(list.firstWhere((a) => a.id == id));

  @override
  Future<Result<void>> setStatus(
    ServerAddress server,
    String id,
    ArticleStatus status,
  ) async => _record('${status.name}:$id');

  @override
  Future<Result<Article>> save(ServerAddress server, Uri url) async {
    if (_record('save:$url') case Error(:final error)) {
      return Result.error(error);
    }
    return Result.ok(Article(id: 'new', url: url, title: '$url'));
  }

  @override
  Future<Result<void>> remove(ServerAddress server, String id) async =>
      _record('remove:$id');
}

/// A [DropRepository] in memory.
class FakeDropRepository with _Calls implements DropRepository {
  /// The items.
  List<Drop> list = [];

  @override
  Future<Result<List<Drop>>> drops(ServerAddress server) async =>
      Result.ok(list);

  @override
  Future<Result<Drop>> sendText(
    ServerAddress server,
    String text, {
    int hours = 24,
  }) async {
    if (_record('send:$text') case Error(:final error)) {
      return Result.error(error);
    }
    return Result.ok(Drop(id: 'new', isFile: false, text: text));
  }

  @override
  Future<Result<void>> remove(ServerAddress server, String id) async =>
      _record('remove:$id');
}

/// An [AccountSecurityRepository] in memory.
class FakeAccountSecurity with _Calls implements AccountSecurityRepository {
  /// The sessions.
  List<AccountSession> list = [];

  /// Whether two-factor sign-in is on.
  bool totp = false;

  @override
  Future<Result<List<AccountSession>>> sessions(ServerAddress server) async =>
      Result.ok(list);

  @override
  Future<Result<void>> revoke(ServerAddress server, String id) async =>
      _record('revoke:$id');

  @override
  Future<Result<void>> revokeOthers(ServerAddress server) async =>
      _record('revokeOthers');

  @override
  Future<Result<void>> changePassword(
    ServerAddress server, {
    required String current,
    required String next,
  }) async => _record('password:$next');

  @override
  Future<Result<bool>> totpEnabled(ServerAddress server) async =>
      Result.ok(totp);

  @override
  Future<Result<TotpSetup>> startTotp(ServerAddress server) async => Result.ok(
    TotpSetup(
      secret: 'JBSWY3DPEHPK3PXP',
      uri: Uri.parse('otpauth://totp/Waylight?secret=JBSWY3DPEHPK3PXP'),
    ),
  );

  @override
  Future<Result<List<String>>> confirmTotp(
    ServerAddress server,
    String code,
  ) async {
    if (_record('confirm:$code') case Error(:final error)) {
      return Result.error(error);
    }
    totp = true;
    return const Result.ok(['aaaa-bbbb', 'cccc-dddd']);
  }

  @override
  Future<Result<void>> disableTotp(
    ServerAddress server, {
    required String password,
    required String code,
  }) async => _record('disable:$code');
}

/// A [PushRepository] in memory.
class FakePushRepository with _Calls implements PushRepository {
  /// Whether the build has push.
  bool isAvailable = true;

  bool _on = false;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<bool> isOn() async => _on;

  @override
  Future<Result<void>> enable(ServerAddress server) async {
    final r = _record('enable');
    if (r is Ok<void>) _on = true;
    return r;
  }

  @override
  Future<Result<void>> disable(ServerAddress server) async {
    _on = false;
    return _record('disable');
  }

  @override
  Future<void> refresh(ServerAddress server) async => _record('refresh');

  /// Whether the battery restrictions are lifted.
  bool unrestricted = true;

  @override
  Future<bool> batteryUnrestricted() async => unrestricted;

  @override
  Future<void> requestBatteryUnrestricted() async {
    _record('battery');
    unrestricted = true;
  }
}

/// A [SummaryRepository] in memory.
class FakeSummaryRepository with _Calls implements SummaryRepository {
  /// Whether the server has summaries.
  bool configured = false;

  @override
  Future<bool> available(ServerAddress server) async => configured;

  @override
  Future<Result<String>> summarise(
    ServerAddress server, {
    required String language,
    String text = '',
    Uri? url,
  }) async {
    if (_record('summarise:${url ?? text}') case Error(:final error)) {
      return Result.error(error);
    }
    return const Result.ok('In short: keep three copies.');
  }

  @override
  Future<Result<String>> ask(
    ServerAddress server, {
    required String question,
    required String context,
    required String language,
  }) async {
    if (_record('ask:$question') case Error(:final error)) {
      return Result.error(error);
    }
    return const Result.ok('Once a week.');
  }
}
