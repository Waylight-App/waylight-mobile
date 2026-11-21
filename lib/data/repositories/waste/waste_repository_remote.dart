import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/data/services/api/waste_api.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A [WasteRepository] that asks the server every time.
class WasteRepositoryRemote implements WasteRepository {
  /// Creates the repository.
  const WasteRepositoryRemote({required this._api});

  final WasteApi _api;

  @override
  Future<Result<List<WasteCollection>>> upcoming(ServerAddress server) =>
      _api.upcoming(server);

  @override
  Future<Result<void>> subscribe(ServerAddress server, String url) =>
      _api.subscribe(server, url);
}
