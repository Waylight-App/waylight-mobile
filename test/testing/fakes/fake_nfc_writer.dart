import 'package:waylight_mobile/data/services/nfc/nfc_writer.dart';
import 'package:waylight_mobile/domain/models/tag_action.dart';

/// An [NfcWriter] without a phone: [write] answers with [outcome].
class FakeNfcWriter implements NfcWriter {
  /// What [state] returns.
  NfcState nfc = NfcState.ready;

  /// What [write] returns.
  TagWriteOutcome outcome = TagWriteOutcome.written;

  /// The links written.
  final List<Uri> written = [];

  /// How often [cancel] ran.
  int cancels = 0;

  @override
  Future<NfcState> state() async => nfc;

  @override
  Future<TagWriteOutcome> write(Uri link) async {
    written.add(link);
    return outcome;
  }

  @override
  Future<void> cancel() async => cancels++;
}
