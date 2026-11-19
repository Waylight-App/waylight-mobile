import 'package:flutter/foundation.dart';

import 'package:waylight_mobile/data/services/api/offline_status.dart';

/// Tells the UI when it shows stored data because the server cannot be
/// reached (#23).
class OfflineRepository extends ChangeNotifier {
  /// Creates the repository on top of the API client's [OfflineStatus].
  OfflineRepository(this._status) {
    _status.addListener(notifyListeners);
  }

  final OfflineStatus _status;

  /// The time of the oldest stored data on screen, or `null` when online.
  DateTime? get showingDataFrom => _status.showingDataFrom;

  @override
  void dispose() {
    _status.removeListener(notifyListeners);
    super.dispose();
  }
}
