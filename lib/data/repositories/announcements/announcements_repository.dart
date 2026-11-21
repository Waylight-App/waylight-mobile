import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/announcement.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Announcements on the server (#202, `ee` feature `announcements`).
abstract interface class AnnouncementsRepository {
  /// The current announcements, pinned first, then newest.
  Future<Result<List<Announcement>>> list(ServerAddress server);

  /// Whether the signed-in account may write.
  Future<Result<bool>> mayWrite(ServerAddress server);

  /// Marks [id] as read for the signed-in account.
  Future<Result<void>> markRead(ServerAddress server, String id);

  /// Publishes an announcement.
  Future<Result<void>> create(ServerAddress server, AnnouncementInput input);

  /// Changes the announcement [id].
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    AnnouncementInput input,
  );

  /// Deletes the announcement [id].
  Future<Result<void>> delete(ServerAddress server, String id);
}

/// An [AnnouncementsRepository] on `/api/announcements`.
class AnnouncementsRepositoryRemote implements AnnouncementsRepository {
  /// Creates the repository.
  const AnnouncementsRepositoryRemote({required this._api});

  final ModuleApi _api;

  static String _path(String id) =>
      '/api/announcements/${Uri.encodeComponent(id)}';

  @override
  Future<Result<List<Announcement>>> list(ServerAddress server) async =>
      switch (await _api.read(
        server,
        '/api/announcements',
        parseAnnouncements,
      )) {
        Ok(:final value) => Result.ok(sortAnnouncements(value)),
        Error(:final error) => Result.error(error),
      };

  @override
  Future<Result<bool>> mayWrite(ServerAddress server) => _api.read(
    server,
    '/api/announcements/me',
    (json) => switch (json) {
      {'mayWrite': final bool may} => may,
      _ => null,
    },
  );

  @override
  Future<Result<void>> markRead(ServerAddress server, String id) async =>
      _void(await _api.post(server, '${_path(id)}/read'));

  @override
  Future<Result<void>> create(
    ServerAddress server,
    AnnouncementInput input,
  ) async =>
      _void(await _api.post(server, '/api/announcements', body: _body(input)));

  @override
  Future<Result<void>> update(
    ServerAddress server,
    String id,
    AnnouncementInput input,
  ) async => _void(await _api.put(server, _path(id), body: _body(input)));

  @override
  Future<Result<void>> delete(ServerAddress server, String id) =>
      _api.delete(server, _path(id));

  static Map<String, Object?> _body(AnnouncementInput i) => {
    'title': i.title.trim(),
    'body': i.body,
    'pinned': i.pinned,
    'expiresAt': i.expiresAt?.toUtc().toIso8601String(),
    'notify': i.notify,
  };

  static Result<void> _void(Result<Object?> r) => switch (r) {
    Ok() => const Result.ok(null),
    Error(:final error) => Result.error(error),
  };
}

/// Pinned first, then newest, as the server's widget shows them.
List<Announcement> sortAnnouncements(List<Announcement> list) =>
    [...list]..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

/// Maps `GET /api/announcements`; `null` for an answer of another shape.
List<Announcement>? parseAnnouncements(Object? json) {
  if (json is! List<Object?>) return null;
  final out = <Announcement>[];
  for (final e in json) {
    if (e
        case {
              'id': final String id,
              'title': final String title,
              'body': final String body,
              'createdAt': final String created,
            } &&
            final Map<String, Object?> a) {
      final createdAt = DateTime.tryParse(created);
      if (createdAt == null) return null;
      out.add(
        Announcement(
          id: id,
          title: title,
          body: body,
          createdAt: createdAt.toLocal(),
          pinned: a['pinned'] == true,
          authorName: switch (a['authorName']) {
            final String s => s,
            _ => '',
          },
          expiresAt: switch (a['expiresAt']) {
            final String s => DateTime.tryParse(s)?.toLocal(),
            _ => null,
          },
          read: a['read'] == true,
          editable: a['editable'] == true,
        ),
      );
    } else {
      return null;
    }
  }
  return out;
}
