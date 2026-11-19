import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/session/session_repository.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The person cancelled the sign-in in the browser.
final class SignInCancelled implements Exception {
  /// Creates the exception.
  const SignInCancelled();
}

/// Finishes a sign-in in the browser with the answer the server sent to
/// `waylight://auth` (#45). The router opens the dashboard afterwards.
class AuthCallbackViewModel extends ChangeNotifier {
  /// Creates the view model for the link's [_query] and starts finishing.
  AuthCallbackViewModel({
    required this._query,
    required this._sessionRepository,
  }) {
    finish = Command0(_finish)..execute().ignore();
  }

  final Map<String, String> _query;
  final SessionRepository _sessionRepository;

  /// Redeems the code of the answer.
  late final Command0<void> finish;

  Future<Result<void>> _finish() async {
    if (_query['error'] == 'access_denied') {
      return const Result.error(SignInCancelled());
    }
    return _sessionRepository.finishBrowserSignIn(
      code: _query['code'] ?? '',
      state: _query['state'] ?? '',
    );
  }

  @override
  void dispose() {
    finish.dispose();
    super.dispose();
  }
}
