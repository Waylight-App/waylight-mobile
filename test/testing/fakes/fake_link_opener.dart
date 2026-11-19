import 'package:waylight_mobile/ui/core/link_opener.dart';

/// A [LinkOpener] that records the addresses instead of opening them.
class FakeLinkOpener extends LinkOpener {
  /// Creates the fake; [succeeds] decides what [open] answers.
  FakeLinkOpener({this.succeeds = true});

  /// Whether opening works.
  final bool succeeds;

  /// The addresses that were opened.
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }
}
