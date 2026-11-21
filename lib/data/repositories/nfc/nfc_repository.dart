import 'package:waylight_mobile/data/services/nfc/nfc_writer.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';

/// Writes Waylight actions onto NFC tags (#195). Reading needs nothing
/// here: the system opens a tag's link in the app like any other link.
class NfcRepository {
  /// Creates the repository.
  const NfcRepository({required this._writer});

  final NfcWriter _writer;

  /// Whether the phone can write tags right now.
  Future<NfcState> state() => _writer.state();

  /// Waits for a tag and writes the link of [action] onto it.
  Future<TagWriteOutcome> write(TagAction action) => _writer.write(action.link);

  /// Stops waiting for a tag.
  Future<void> cancel() => _writer.cancel();
}
