import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/domain/models/waste_collection.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The waste module of the server (#49).
abstract interface class WasteRepository {
  /// The next collections on [server].
  Future<Result<List<WasteCollection>>> upcoming(ServerAddress server);
}
