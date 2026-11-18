import 'package:material_ui/material_ui.dart';

/// Creates a view model once, keeps it while the screen is shown and
/// disposes it with the screen.
///
/// Routes build their screens through a host instead of calling the view
/// model constructor in the route builder: the router may rebuild a route
/// at any time, which would otherwise create a new view model each time,
/// lose its state and never dispose the old one.
///
/// ```dart
/// GoRoute(
///   path: Routes.home,
///   builder: (context, state) => ViewModelHost(
///     create: (context) => HomeViewModel(serverRepository: context.read()),
///     builder: (context, viewModel) => HomeScreen(viewModel: viewModel),
///   ),
/// )
/// ```
class ViewModelHost<T extends ChangeNotifier> extends StatefulWidget {
  /// Creates the host.
  const ViewModelHost({required this.create, required this.builder, super.key});

  /// Creates the view model; called once, when the screen appears.
  final T Function(BuildContext context) create;

  /// Builds the screen for the view model.
  final Widget Function(BuildContext context, T viewModel) builder;

  @override
  State<ViewModelHost<T>> createState() => _ViewModelHostState<T>();
}

class _ViewModelHostState<T extends ChangeNotifier>
    extends State<ViewModelHost<T>> {
  late final T _viewModel = widget.create(context);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _viewModel);
}
