import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/utils/result.dart';

/// An action of a view model that the UI can trigger and observe.
///
/// A command runs its asynchronous action once at a time and tells whether
/// it is [running], has [completed] or failed ([error]), so views keep no
/// loading or error flags of their own. See
/// https://docs.flutter.dev/app-architecture/design-patterns/command.
sealed class Command<T> extends ChangeNotifier {
  bool _running = false;
  Result<T>? _result;

  /// Whether the action is in progress.
  bool get running => _running;

  /// Whether the last run failed.
  bool get error => _result is Error<T>;

  /// Whether the last run succeeded.
  bool get completed => _result is Ok<T>;

  /// The result of the last run, or `null` before the first run.
  Result<T>? get result => _result;

  /// Forgets the last result, for example once an error was shown.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(Future<Result<T>> Function() action) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A [Command] without an argument.
final class Command0<T> extends Command<T> {
  /// Creates a command that runs [_action].
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  /// Runs the action unless it is already running.
  Future<void> execute() => _execute(_action);
}

/// A [Command] with one argument of type [A].
final class Command1<T, A> extends Command<T> {
  /// Creates a command that runs [_action] with an argument.
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  /// Runs the action with [argument] unless it is already running.
  Future<void> execute(A argument) => _execute(() => _action(argument));
}
