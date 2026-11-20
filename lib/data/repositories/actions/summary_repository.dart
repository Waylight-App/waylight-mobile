import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// Summaries by the server's local Ollama (#155).
abstract interface class SummaryRepository {
  /// Whether the server has summaries set up; otherwise nothing is shown.
  Future<bool> available(ServerAddress server);

  /// Answers [question] about [context] in [language] (#155).
  Future<Result<String>> ask(
    ServerAddress server, {
    required String question,
    required String context,
    required String language,
  });

  /// Summarises [text], or the page behind [url], in [language].
  Future<Result<String>> summarise(
    ServerAddress server, {
    required String language,
    String text = '',
    Uri? url,
  });
}

/// A [SummaryRepository] on `/api/summary`.
class SummaryRepositoryRemote implements SummaryRepository {
  /// Creates the repository.
  const SummaryRepositoryRemote({required this._api});

  final ModuleApi _api;

  static Result<String> _summary(Result<Object?> r) => switch (r) {
    Ok(value: {'summary': final String s}) => Result.ok(s),
    Ok() => const Result.error(ApiException(ApiFailure.server)),
    Error(:final error) => Result.error(error),
  };

  @override
  Future<bool> available(ServerAddress server) async => switch (await _api.read(
    server,
    '/api/summary/settings',
    (json) => switch (json) {
      {'configured': final bool c} => c,
      _ => null,
    },
  )) {
    Ok(:final value) => value,
    Error() => false,
  };

  @override
  Future<Result<String>> summarise(
    ServerAddress server, {
    required String language,
    String text = '',
    Uri? url,
  }) async => _summary(
    await _api.post(
      server,
      '/api/summary',
      body: {
        if (text.isNotEmpty) 'text': text,
        if (url != null) 'url': '$url',
        'language': language,
      },
    ),
  );

  @override
  Future<Result<String>> ask(
    ServerAddress server, {
    required String question,
    required String context,
    required String language,
  }) => _api.postText(
    server,
    '/api/summary/ask',
    body: {'question': question, 'context': context, 'language': language},
  );
}
