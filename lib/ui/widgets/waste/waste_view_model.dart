import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/waste/waste_repository.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/utils/command.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The state of a waste collection widget (#49).
class WasteViewModel extends ChangeNotifier {
  /// Creates the view model and starts loading.
  WasteViewModel({
    required this._serverRepository,
    required this._wasteRepository,
  }) {
    load = Command0(_load)..execute().ignore();
    subscribe = Command1(_subscribe);
  }

  final ServerRepository _serverRepository;
  final WasteRepository _wasteRepository;

  /// Loads the next collections; run again to reload.
  late final Command0<List<WasteCollection>> load;

  /// Subscribes to the waste calendar at an address while none is set up
  /// (#230), then loads the collections.
  late final Command1<void, String> subscribe;

  Future<Result<void>> _subscribe(String url) async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    final result = await _wasteRepository.subscribe(server, url.trim());
    if (result is Ok<void>) load.execute().ignore();
    return result;
  }

  Future<Result<List<WasteCollection>>> _load() async {
    final server = _serverRepository.current;
    if (server == null) return const Result.error(NotConnectedException());
    return _wasteRepository.upcoming(server);
  }

  @override
  void dispose() {
    load.dispose();
    subscribe.dispose();
    super.dispose();
  }
}
