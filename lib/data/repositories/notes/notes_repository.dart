import 'package:waylight_mobile/domain/models/note.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The notes module of the server.
abstract interface class NotesRepository {
  /// The notes of the signed-in account on [server].
  Future<Result<List<Note>>> notes(
    ServerAddress server, {
    bool pinnedOnly = false,
  });
}
