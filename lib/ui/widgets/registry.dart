import 'package:waylight_mobile/ui/core/widget_registry.dart';
import 'package:waylight_mobile/ui/widgets/clock/clock_widget.dart';
import 'package:waylight_mobile/ui/widgets/weather/weather_widget.dart';

/// The widget kinds with a native view. Add a kind here when its feature
/// folder in `ui/widgets/` is done (docs/adding-a-feature.md).
const nativeWidgets = WidgetRegistry({
  'clock': ClockWidget.forPlacement,
  'weather': WeatherWidget.forPlacement,
});
