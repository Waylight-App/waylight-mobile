import 'package:waylight_mobile/domain/models/actions.dart';

/// How Android's device controls offer a smart home entity (#194).
enum DeviceControlType {
  /// Switched on and off, such as a light or a switch.
  toggle,

  /// Pressed once, such as a scene or a script.
  button,

  /// Only shown, such as a sensor or an entity the server does not let the
  /// app change.
  readOnly,
}

/// What kind of device an entity is, for the icon Android draws.
enum DeviceControlDevice {
  /// `light.*`
  light,

  /// `switch.*` and `input_boolean.*`
  switcher,

  /// `scene.*` and `script.*`
  routine,

  /// `sensor.*` and `binary_sensor.*`
  sensor,

  /// Anything else.
  other;

  /// The device kind of the Home Assistant entity [id].
  static DeviceControlDevice of(String id) => switch (id.split('.').first) {
    'light' => light,
    'switch' || 'input_boolean' => switcher,
    'scene' || 'script' => routine,
    'sensor' || 'binary_sensor' => sensor,
    _ => other,
  };
}

/// One device control as the native side draws it.
final class DeviceControl {
  /// Creates the control.
  const DeviceControl({
    required this.id,
    required this.name,
    required this.type,
    required this.device,
    required this.on,
    required this.status,
  });

  /// The control for [entity]. The server's allow-list decides the type:
  /// what it does not let the app change stays read-only.
  factory DeviceControl.of(SmartEntity entity, String status) => DeviceControl(
    id: entity.id,
    name: entity.name,
    type: switch (entity.action) {
      EntityAction.toggle => DeviceControlType.toggle,
      EntityAction.press => DeviceControlType.button,
      EntityAction.none => DeviceControlType.readOnly,
    },
    device: DeviceControlDevice.of(entity.id),
    on: entity.isOn,
    status: status,
  );

  /// The entity id, such as `light.desk_lamp`.
  final String id;

  /// The name shown on the control.
  final String name;

  /// How the control can be used.
  final DeviceControlType type;

  /// The icon Android draws.
  final DeviceControlDevice device;

  /// Whether a toggle is on.
  final bool on;

  /// The state in words, such as "On" or "21.4 °C".
  final String status;

  /// The form the native side reads.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'device': device.name,
    'on': on,
    'status': status,
  };
}

/// Everything the device controls show. While [available] is false, the
/// native side shows the controls it knows as unavailable with [reason]
/// instead of a state that may be wrong.
final class DeviceControlsSnapshot {
  /// Creates the snapshot.
  const DeviceControlsSnapshot({
    required this.available,
    this.reason = '',
    this.controls = const [],
  });

  /// Whether the states are current.
  final bool available;

  /// Why the controls are unavailable, in the app's language.
  final String reason;

  /// The controls; empty while unavailable, so the last known ones stay.
  final List<DeviceControl> controls;

  /// The form the native side reads.
  Map<String, Object?> toJson() => {
    'available': available,
    'reason': reason,
    'controls': [for (final c in controls) c.toJson()],
  };
}

/// Why the device controls cannot show a state.
enum DeviceControlsProblem {
  /// No server or no session: the app must be opened to sign in.
  signedOut,

  /// The server did not answer or refused.
  unreachable,
}

/// The words of the device controls in the app's language; given by the
/// UI layer, which has the texts.
abstract interface class DeviceControlFormatter {
  /// The state of [entity] in words.
  String state(SmartEntity entity);

  /// Why the controls are unavailable.
  String problem(DeviceControlsProblem problem);
}
