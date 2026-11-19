import 'package:material_ui/material_ui.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:waylight_mobile/ui/core/localization.dart';

/// The shortcuts on the launcher icon and where they lead (#50).
enum AppShortcut {
  /// Opens the search with the quick capture prefix for a to-do.
  addTodo,

  /// Opens the tab with the departures.
  departures,

  /// Opens the search.
  search;

  /// The shortcut of a platform [type], if it is one of these.
  static AppShortcut? ofType(String? type) {
    for (final s in values) {
      if (s.name == type) return s;
    }
    return null;
  }
}

/// Registers the [AppShortcut]s with translated titles and reports the one
/// the person chose; where it leads is decided by the routing.
class AppShortcuts extends StatefulWidget {
  /// Creates the widget around [child]; [actions] is for tests.
  const AppShortcuts({
    required this.onShortcut,
    required this.child,
    this.actions = const QuickActions(),
    super.key,
  });

  /// Called with the chosen shortcut.
  final void Function(AppShortcut shortcut) onShortcut;

  /// The rest of the app.
  final Widget child;

  /// The platform's shortcuts.
  final QuickActions actions;

  @override
  State<AppShortcuts> createState() => _AppShortcutsState();
}

class _AppShortcutsState extends State<AppShortcuts> {
  bool _initialized = false;
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      widget.actions.initialize((type) {
        if (AppShortcut.ofType(type) case final shortcut?) {
          widget.onShortcut(shortcut);
        }
      }).ignore();
    }
    // The titles follow the language of the app.
    final locale = Localizations.localeOf(context);
    if (locale == _locale) return;
    _locale = locale;
    final l10n = context.l10n;
    widget.actions.setShortcutItems([
      ShortcutItem(
        type: AppShortcut.addTodo.name,
        localizedTitle: l10n.shortcutAddTodo,
      ),
      ShortcutItem(
        type: AppShortcut.departures.name,
        localizedTitle: l10n.shortcutDepartures,
      ),
      ShortcutItem(
        type: AppShortcut.search.name,
        localizedTitle: l10n.searchHint,
      ),
    ]).ignore();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
