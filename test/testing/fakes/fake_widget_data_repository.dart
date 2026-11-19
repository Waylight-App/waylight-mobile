import 'dart:typed_data';

import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [WidgetDataRepository] that answers each path with recorded JSON and
/// runs it through the real parser, so widget tests also cover parsing.
class FakeWidgetDataRepository implements WidgetDataRepository {
  /// The JSON per endpoint path; a missing path fails with "not found".
  final Map<String, Object?> json = {};

  /// The images per path; a missing path fails with "not found".
  final Map<String, Uint8List> images = {};

  /// The queries asked, in order.
  final List<WidgetQuery<Object?>> asked = [];

  @override
  Future<Result<T>> read<T>(ServerAddress server, WidgetQuery<T> query) async {
    asked.add(query);
    if (!json.containsKey(query.path)) {
      return const Result.error(ApiException(ApiFailure.notFound));
    }
    final parsed = query.parse(json[query.path]);
    return parsed == null
        ? const Result.error(ApiException(ApiFailure.server))
        : Result.ok(parsed);
  }

  @override
  Future<Result<Uint8List>> image(
    ServerAddress server,
    String path, {
    Map<String, String> query = const {},
  }) async => switch (images[path]) {
    final bytes? => Result.ok(bytes),
    null => const Result.error(ApiException(ApiFailure.notFound)),
  };
}
