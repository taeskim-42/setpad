import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'agent_alarm.dart';
import 'boundary_notify.dart';
import 'rest_timer.dart';

/// The end of a set rest as a local notification, for when the app is away
/// (spec focus-stage-1.8 §5). Uses [AgentAlarm]'s plugin and initialization;
/// where that did not start (web, tests) everything quietly does nothing —
/// the sound in front is the main signal, this is the backup.
class LocalRestNotifier implements RestNotifier {
  const LocalRestNotifier({this.voice});

  /// The recorded "Go!" the rest ends with in the app (a Flutter asset), as
  /// the notification's sound on iOS; null (voice cues off): the default
  /// sound.
  final String? Function()? voice;

  /// One notice at a time. Above every [agentAlarmSlots] id (< 2,016,000,000)
  /// and inside a 32-bit int (Android).
  static const id = 2147480000;

  /// Asks once for notifications; false when refused or unavailable. An
  /// answer already given returns without a prompt.
  static Future<bool> ensurePermission() => AgentAlarm.ensurePermission();

  @override
  Future<bool> schedule(DateTime at, String title, String body) async {
    final plugin = await AgentAlarm.plugin;
    if (plugin == null) return false;
    final asset = voice?.call();
    // Ready since the stage opened; this only looks it up.
    if (asset != null) await NotificationSounds.prepare([asset]);
    try {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        // The calendar trigger keeps whole seconds: rounded up, never before
        // the rest's end (lib/boundary_notify.dart).
        tz.TZDateTime.from(wholeSecondUp(at), tz.UTC),
        _details(
          title,
          sound: asset == null ? null : NotificationSounds.of(asset),
        ),
        // Play refused the exact-alarm permission before (AndroidManifest):
        // inexact, never early.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      return false;
    }
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    final allowed = await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    return allowed != null && allowed.isEnabled && allowed.isSoundEnabled;
  }

  // The channel is named after what it says ("Rest's over"): no separate
  // string to translate. [sound]: the iOS file (NotificationSounds.of); null
  // is the default sound.
  static NotificationDetails _details(String title, {String? sound}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_rest',
          title,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(sound: sound),
      );

  /// Android schedules inexactly (no exact-alarm permission): with the
  /// workout service keeping the app alive, the end sound has just played
  /// and the scheduled notice could still come minutes later, in the next
  /// set. So it is replaced by one shown now. iOS schedules to the second
  /// (rounded up) and its notice carries the recorded "Go!", which the app
  /// then does not say again (RestTimer): left alone.
  @override
  Future<void> endedAway(String title, String body) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final plugin = await AgentAlarm.plugin;
    if (plugin == null) return;
    try {
      await plugin.cancel(id);
      await plugin.show(id, title, body, _details(title));
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
