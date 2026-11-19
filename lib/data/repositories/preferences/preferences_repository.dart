import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/domain/models/appearance.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The settings kept on the device, independent of the web settings (#14).
///
/// Notifies its listeners when they change, so the app applies them at once.
abstract class PreferencesRepository extends ChangeNotifier {
  /// The look of the app.
  Appearance get appearance;

  /// Loads the stored settings; call once at start.
  Future<Result<void>> restore();

  /// Stores [appearance] and applies it.
  Future<Result<void>> setAppearance(Appearance appearance);
}
