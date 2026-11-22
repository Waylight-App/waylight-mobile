import 'package:waylight_mobile/domain/models/compact_state.dart';

/// The short help of one widget kind (`GET /api/help/widgets`, #289): what
/// it shows and how to set it up, in the server's words.
final class WidgetHelp {
  /// Creates the help.
  const WidgetHelp({
    required this.kind,
    required this.shows,
    required this.setUp,
    required this.docsUrl,
  });

  /// The widget kind the help is for.
  final String kind;

  /// What the widget shows.
  final CompactText shows;

  /// How to set the widget up.
  final CompactText setUp;

  /// The page of the widget in the documentation.
  final Uri docsUrl;
}

/// Where the documentation starts; the help links here when the server
/// gives no page of the widget.
final Uri documentationUrl = Uri.parse('https://getwaylight.app/docs/');
