import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Reloads the widgets that are on screen (#19).
///
/// Widgets register their load action while they are shown. Pull to
/// refresh and the return of the app to the foreground reload all of them;
/// interval reloads ask [active] first, so nothing loads while the app is in
/// the background.
class RefreshController {
  /// Creates the controller; [now] can be replaced in tests.
  RefreshController({this._now = DateTime.now});

  final DateTime Function() _now;
  final Set<Future<void> Function()> _loads = {};

  /// Whether the app is in the foreground.
  bool active = true;

  /// The current time, for the age of the data.
  DateTime now() => _now();

  /// Registers [load] while its widget is shown.
  void add(Future<void> Function() load) => _loads.add(load);

  /// Removes [load] when its widget is gone.
  void remove(Future<void> Function() load) => _loads.remove(load);

  /// Reloads every registered widget and completes when all are done.
  Future<void> refresh() => Future.wait([
    for (final load in [..._loads]) load(),
  ]);
}

/// Provides a [RefreshController] to the widgets below and reloads them
/// when the app returns to the foreground.
class RefreshHost extends StatefulWidget {
  /// Creates the host around [child]; [controller] is for tests.
  const RefreshHost({required this.child, this.controller, super.key});

  /// The content, usually the tabs of the dashboard.
  final Widget child;

  /// The controller to use; a new one by default.
  final RefreshController? controller;

  /// The controller of the nearest [RefreshHost], if any.
  static RefreshController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RefreshScope>()?.controller;

  @override
  State<RefreshHost> createState() => _RefreshHostState();
}

class _RefreshHostState extends State<RefreshHost> {
  late final RefreshController _controller =
      widget.controller ?? RefreshController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _controller.active = true;
        _controller.refresh().ignore();
      },
      onHide: () => _controller.active = false,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _RefreshScope(controller: _controller, child: widget.child);
}

class _RefreshScope extends InheritedWidget {
  const _RefreshScope({required this.controller, required super.child});

  final RefreshController controller;

  @override
  bool updateShouldNotify(_RefreshScope oldWidget) =>
      controller != oldWidget.controller;
}
