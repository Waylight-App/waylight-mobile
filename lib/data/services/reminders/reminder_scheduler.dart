import 'package:flutter/services.dart';

import 'package:waylight_mobile/domain/models/reminder.dart';

/// Schedules notifications on the device (#190). The native side keeps the
/// list, so reminders also fire after a reboot without the app.
abstract interface class ReminderScheduler {
  /// Replaces every scheduled reminder with [reminders].
  Future<void> replaceAll(List<Reminder> reminders);

  /// Cancels every scheduled reminder.
  Future<void> cancelAll();

  /// Asks for the notification permission where the system needs it;
  /// `true` when notifications may be shown.
  Future<bool> requestPermission();
}

/// A [ReminderScheduler] over the channel `app.waylight/reminders`; on
/// platforms without it (iOS for now, tests) it does nothing.
final class MethodChannelReminderScheduler implements ReminderScheduler {
  /// Creates the adapter.
  const MethodChannelReminderScheduler({
    this._channel = const MethodChannel('app.waylight/reminders'),
  });

  final MethodChannel _channel;

  @override
  Future<void> replaceAll(List<Reminder> reminders) => _call('replaceAll', {
    'reminders': [
      for (final r in reminders)
        {
          'id': r.id,
          'at': r.at.millisecondsSinceEpoch,
          'kind': r.kind.name,
          'title': r.title,
          'body': r.body,
          'link': r.link,
        },
    ],
  });

  @override
  Future<void> cancelAll() => _call('cancelAll');

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _call(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // No native side on this platform.
    }
  }
}
