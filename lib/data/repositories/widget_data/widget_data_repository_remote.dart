import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [WidgetDataRepository] that asks the server; the API client keeps the
/// answers for offline use (ADR 0007).
class WidgetDataRepositoryRemote implements WidgetDataRepository {
  /// Creates the repository.
  const WidgetDataRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<T>> read<T>(ServerAddress server, WidgetQuery<T> query) =>
      _api.read(server, query.path, query.parse, query: query.query);
}
