import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens web addresses outside the app, in the browser the user chose.
///
/// Widgets get it with [LinkOpener.of]; tests put a [LinkOpenerScope] with a
/// fake above them.
class LinkOpener {
  /// Creates the opener that uses the system browser.
  const LinkOpener();

  /// Opens [uri]; `false` if no app could open it.
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  /// The opener of the nearest [LinkOpenerScope], or the system browser.
  static LinkOpener of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LinkOpenerScope>()?.opener ??
      const LinkOpener();
}

/// Provides another [LinkOpener] to the widgets below, e.g. in tests.
class LinkOpenerScope extends InheritedWidget {
  /// Creates the scope.
  const LinkOpenerScope({
    required this.opener,
    required super.child,
    super.key,
  });

  /// The opener for the widgets below.
  final LinkOpener opener;

  @override
  bool updateShouldNotify(LinkOpenerScope oldWidget) =>
      opener != oldWidget.opener;
}

/// Opens [uri] and tells the user with a snack bar when that failed.
Future<void> openLink(
  BuildContext context,
  Uri uri,
  String failedMessage,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (!await LinkOpener.of(context).open(uri)) {
    messenger?.showSnackBar(SnackBar(content: Text(failedMessage)));
  }
}
