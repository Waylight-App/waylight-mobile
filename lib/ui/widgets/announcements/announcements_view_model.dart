import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/announcements/announcements_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/domain/models/announcement.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of the announcements widget (#202).
class AnnouncementsViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  AnnouncementsViewModel({
    required this._serverRepository,
    required this._repository,
  }) {
    load = Command0(_load)..execute().ignore();
  }

  final ServerRepository _serverRepository;
  final AnnouncementsRepository _repository;

  List<Announcement> _items = const [];
  bool _off = false;
  bool _mayWrite = false;
  bool _canMark = false;

  /// Loads the announcements; run again to reload.
  late final Command0<void> load;

  /// The announcements, pinned first, then newest.
  List<Announcement> get items => _items;

  /// How many are unread.
  int get unread => _items.where((a) => !a.read).length;

  /// Whether the feature is off or not licensed (HTTP 404).
  bool get off => _off;

  /// Whether the account may write, as the server says.
  bool get mayWrite => _mayWrite;

  Future<Result<void>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    switch (await _repository.list(server)) {
      case Ok(:final value):
        _items = value;
        _off = false;
      case Error(error: ApiException(failure: ApiFailure.notFound)):
        _items = const [];
        _off = true;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
    _mayWrite = switch (await _repository.mayWrite(server)) {
      Ok(:final value) => value,
      Error() => false,
    };
    // Guests and kiosk displays read without read marks (#202).
    if (await _serverRepository.status() case Ok(:final value)) {
      _canMark = value.role != 'guest' && value.role != 'kiosk';
    }
    notifyListeners();
    return const Result.ok(null);
  }

  /// Marks [a] as read when it is opened; read marks are per person.
  Future<void> open(Announcement a) async {
    final server = _serverRepository.current;
    if (server == null || a.read || !_canMark) return;
    _items = [for (final x in _items) x.id == a.id ? x.markedRead() : x];
    notifyListeners();
    await _repository.markRead(server, a.id);
  }

  /// Publishes, or changes [existing]; the error is returned for the form.
  Future<Result<void>> save(
    AnnouncementInput input, {
    Announcement? existing,
  }) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = existing == null
        ? await _repository.create(server, input)
        : await _repository.update(server, existing.id, input);
    if (result case Ok()) await load.execute();
    return result;
  }

  /// Deletes [a].
  Future<Result<void>> delete(Announcement a) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _repository.delete(server, a.id);
    if (result case Ok()) await load.execute();
    return result;
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
