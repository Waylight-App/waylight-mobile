import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/actions/smarthome_repository.dart';
import 'package:waylight_mobile/data/repositories/habits/habits_repository.dart';
import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/shopping/shopping_repository.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Where running a tag's action stands.
enum TagRunState {
  /// Talking to the server.
  working,

  /// Waiting for the person to confirm a change of another system.
  confirm,

  /// Finished; [TagActionViewModel.outcome] says how.
  done,

  /// Failed; [TagActionViewModel.error] says why.
  failed,
}

/// What a finished action did.
enum TagOutcome {
  /// The habit is ticked off for today.
  ticked,

  /// The habit was already ticked off; nothing changed.
  alreadyDone,

  /// The device was switched.
  switched,

  /// The scene or button was pressed.
  pressed,

  /// The item is on the shopping list.
  added,
}

/// Runs the action of an NFC tag (#195) through the same repositories as
/// the widgets, so the server decides what the account may do.
class TagActionViewModel extends ChangeNotifier {
  /// Creates the view model and starts the action of the tag link's
  /// [query].
  TagActionViewModel({
    required Map<String, String> query,
    required this._serverRepository,
    required this._habitsRepository,
    required this._smartHomeRepository,
    required this._shoppingRepository,
  }) : action = TagAction.parse(query) {
    _start().ignore();
  }

  /// The action of the tag; `null` for a link the app does not understand.
  final TagAction? action;

  final ServerRepository _serverRepository;
  final HabitsRepository _habitsRepository;
  final SmartHomeRepository _smartHomeRepository;
  final ShoppingRepository _shoppingRepository;

  TagRunState _state = TagRunState.working;
  TagOutcome? _outcome;
  Exception? _error;
  String _subject = '';

  /// Where the action stands.
  TagRunState get state => _state;

  /// What the finished action did.
  TagOutcome? get outcome => _outcome;

  /// Why the action failed.
  Exception? get error => _error;

  /// What the action is about: the habit, the device or the item.
  String get subject => _subject;

  /// Changes the device after the person confirmed it.
  Future<void> confirm() async {
    if (_state != TagRunState.confirm) return;
    if (action case SmartHomeTag(:final id)) {
      _set(TagRunState.working);
      await _act(id);
    }
  }

  Future<void> _start() async {
    final server = _serverRepository.current;
    if (server == null) return _fail(const NotConnectedException());
    switch (action) {
      case null:
        return _fail(const ApiException(ApiFailure.invalid));
      case HabitTag(:final id):
        switch (await _habitsRepository.habits(server)) {
          case Error(:final error):
            return _fail(error);
          case Ok(:final value):
            final habit = value.where((h) => h.id == id).firstOrNull;
            if (habit == null) {
              return _fail(const ApiException(ApiFailure.notFound));
            }
            _subject = habit.emoji.isEmpty
                ? habit.name
                : '${habit.emoji} ${habit.name}';
            // A second touch must not untick it again.
            if (habit.doneToday) return _finish(TagOutcome.alreadyDone);
            switch (await _habitsRepository.toggle(server, id)) {
              case Ok():
                return _finish(TagOutcome.ticked);
              case Error(:final error):
                return _fail(error);
            }
        }
      case SmartHomeTag(:final id, :final ask):
        switch (await _smartHomeRepository.entities(server, ids: [id])) {
          case Error(:final error):
            return _fail(error);
          case Ok(:final value):
            final entity = value.firstOrNull;
            if (entity == null) {
              return _fail(const ApiException(ApiFailure.notFound));
            }
            _subject = entity.name;
            if (entity.action == EntityAction.none) {
              return _fail(const ApiException(ApiFailure.forbidden));
            }
            _pressed = entity.action == EntityAction.press;
            if (ask) return _set(TagRunState.confirm);
            await _act(id);
        }
      case TabTag():
        // The router opens the dashboard for these links; the screen is
        // only reached by a link that bypassed it.
        return _fail(const ApiException(ApiFailure.invalid));
      case ShoppingTag(:final text):
        _subject = text;
        switch (await _shoppingRepository.overview(server)) {
          case Error(:final error):
            return _fail(error);
          case Ok(:final value):
            final list = value.current.isNotEmpty
                ? value.current
                : value.lists.firstOrNull?.id;
            if (list == null) {
              return _fail(const ApiException(ApiFailure.notFound));
            }
            switch (await _shoppingRepository.add(server, list, text)) {
              case Ok():
                return _finish(TagOutcome.added);
              case Error(:final error):
                return _fail(error);
            }
        }
    }
  }

  bool _pressed = false;

  Future<void> _act(String id) async {
    final server = _serverRepository.current;
    if (server == null) return _fail(const NotConnectedException());
    switch (await _smartHomeRepository.act(server, id)) {
      case Ok():
        _finish(_pressed ? TagOutcome.pressed : TagOutcome.switched);
      case Error(:final error):
        _fail(error);
    }
  }

  void _finish(TagOutcome outcome) {
    _outcome = outcome;
    _set(TagRunState.done);
  }

  void _fail(Exception error) {
    _error = error;
    _set(TagRunState.failed);
  }

  void _set(TagRunState state) {
    _state = state;
    notifyListeners();
  }
}
