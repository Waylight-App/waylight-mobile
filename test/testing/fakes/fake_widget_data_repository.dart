import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [WidgetDataRepository] that answers each path with recorded JSON and
/// runs it through the real parser, so widget tests also cover parsing.
class FakeWidgetDataRepository implements WidgetDataRepository {
  /// The JSON per endpoint path; a missing path fails with "not found".
  final Map<String, Object?> json = {};

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
}
