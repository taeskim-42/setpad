import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'agent_alarm.dart';
import 'rest_timer.dart';

/// The end of a set rest as a local notification, for when the app is away
/// (spec focus-stage-1.8 §5). Uses [AgentAlarm]'s plugin and initialization;
/// where that did not start (web, tests) everything quietly does nothing —
/// the sound in front is the main signal, this is the backup.
class LocalRestNotifier implements RestNotifier {
  const LocalRestNotifier();

  /// One notice at a time. Above every [agentAlarmSlots] id (< 2,016,000,000)
  /// and inside a 32-bit int (Android).
  static const id = 2147480000;

  /// Asks once for notifications; false when refused or unavailable. An
  /// answer already given returns without a prompt.
  static Future<bool> ensurePermission() => AgentAlarm.ensurePermission();

  @override
  Future<void> schedule(DateTime at, String title, String body) async {
    final plugin = await AgentAlarm.plugin;
    if (plugin == null) return;
    try {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.UTC),
        NotificationDetails(
          // The channel is named after what it says ("Rest's over"): no
          // separate string to translate.
          android: AndroidNotificationDetails(
            'focus_rest',
            title,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Play refused the exact-alarm permission before (AndroidManifest):
        // inexact, never early.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  @override
  Future<void> cancel() async {
    final plugin = await AgentAlarm.plugin;
    if (plugin == null) return;
    try {
      await plugin.cancel(id);
    } catch (_) {}
  }
}
