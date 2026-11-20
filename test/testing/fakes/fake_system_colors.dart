import 'package:waylight_mobile/data/services/system_colors/system_colors.dart';

/// A [SystemColors] for tests; `null` means no wallpaper colours.
class FakeSystemColors implements SystemColors {
  /// Creates the fake with the system [color].
  FakeSystemColors([this.color]);

  /// What [accent] returns.
  int? color;

  @override
  Future<int?> accent() async => color;
}
