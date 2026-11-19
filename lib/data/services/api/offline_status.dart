import 'package:flutter/foundation.dart';

/// Whether the app shows stored data because the server cannot be reached
/// (#23).
///
/// The API client reports each stored answer it serves and each request
/// that reached the server; the dashboard shows the time of the oldest data
/// on screen.
class OfflineStatus extends ChangeNotifier {
  DateTime? _since;

  /// The time of the oldest stored answer shown, or `null` when online.
  DateTime? get showingDataFrom => _since;

  /// A stored answer from [storedAt] was served instead of the server's.
  void servedStored(DateTime storedAt) {
    final since = _since;
    if (since != null && !storedAt.isBefore(since)) return;
    _since = storedAt;
    notifyListeners();
  }

  /// A request reached the server again.
  void reachedServer() {
    if (_since == null) return;
    _since = null;
    notifyListeners();
  }
}
