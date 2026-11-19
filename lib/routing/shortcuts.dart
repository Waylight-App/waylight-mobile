import 'package:waylight_mobile/routing/routes.dart';
import 'package:waylight_mobile/ui/core/app_shortcuts.dart';

/// Where a shortcut on the launcher icon leads (#50); the router signs in
/// first if needed.
String shortcutLocation(AppShortcut shortcut) => switch (shortcut) {
  AppShortcut.addTodo => Uri(
    path: Routes.search,
    queryParameters: {'q': 't '},
  ).toString(),
  AppShortcut.departures => Uri(
    path: Routes.home,
    queryParameters: {'widget': 'transit'},
  ).toString(),
  AppShortcut.search => Routes.search,
};
