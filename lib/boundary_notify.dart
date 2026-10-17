import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'agent_alarm.dart';
import 'workout_timing.dart';

/// Recorded words as notification sounds, iOS only: TimingBridge.swift
/// (NotificationSounds) copies each Flutter asset once into Library/Sounds as
/// linear PCM CAF, a format and place a local notification plays from.
/// Elsewhere nothing: notifications keep the default sound.
class NotificationSounds {
  static const _channel = MethodChannel('setpad/timing');
  static final _files = <String, String>{};

  static bool get _ios =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// The sound file name of [asset] once ready; null: the default sound.
  static String? of(String asset) => _files[asset];

  /// Converts the [assets] not ready yet. Never throws.
  static Future<void> prepare(Iterable<String> assets) async {
    final missing = {...assets}.where((a) => !_files.containsKey(a)).toList();
    if (!_ios || missing.isEmpty) return;
    try {
      final ready = await _channel.invokeMapMethod<String, String>(
        'notificationSounds',
        {'assets': missing},
      );
      _files.addAll(ready ?? const {});
    } on MissingPluginException {
      /* Widget tests. */
    } on PlatformException {
      /* Default sound then. */
    }
  }
}

/// A run's boundaries as local notifications while the app is away, iOS
/// only (Android keeps its foreground service). Apple's way for alerts in a
/// silent stretch: the app may be suspended there, and nothing silent is
/// played to keep it awake (TimingBridge.swift). Uses [AgentAlarm]'s plugin,
/// initialization and permission.
///
/// Interruption level: the default (active). Time Sensitive and Critical
/// Alerts need entitlements the app does not have.
class LocalBoundaryNotifier implements BoundaryNotifier {
  LocalBoundaryNotifier({required this.title});

  /// The lock-screen title of a boundary of a run of the given spec.
  final String Function(TimingSpec spec, Boundary b) title;

  /// Ids [firstId] .. [firstId] + [idCount] - 1: under the set rest's
  /// (LocalRestNotifier.id, 2147480000), above every trainer report id
  /// (< 2,016,000,000).
  static const firstId = 2147470000;

  /// Room for two runs away at once: my record's and a proxy one's editor
  /// each have a timer.
  static const idCount = 2 * maxBoundaryNotices;

  /// Apple: "a limit of 64 for how many simultaneous notification requests
  /// can be active/pending at one time per app" (forum, Apple staff).
  static const systemLimit = 64;

  /// Ids held by any run's notices in this process, and this run's.
  static final _taken = <int>{};
  final _mine = <int>[];

  /// Plugin calls in order, for every run (one plugin): a cancel never
  /// overtakes a schedule, and a count of what is pending stays true until
  /// the schedule after it is done.
  static Future<void> _chain = Future.value();
  static Future<T> _serial<T>(Future<T> Function() f) {
    final next = _chain.then((_) => f());
    _chain = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  @protected
  bool get onIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// A run does not outlive the process: what one of an earlier process left
  /// (killed by the user or the system) goes. Once, at launch (main).
  static Future<void> clearStale() =>
      LocalBoundaryNotifier(title: (_, _) => '').clearRange();

  @visibleForTesting
  Future<void> clearRange() => onIOS
      ? _serial(() async {
          for (var id = firstId; id < firstId + idCount; id++) {
            try {
              await remove(id);
            } catch (_) {}
          }
        })
      : Future.value();

  @override
  Future<void> prepare(Iterable<String> voices) =>
      onIOS ? prepareSounds(voices) : Future.value();

  @override
  Future<int> schedule(
    TimingSpec spec,
    List<Boundary> boundaries, {
    required Duration from,
    required DateTime now,
  }) {
    if (!onIOS) return Future.value(0);
    return _serial(() async {
      try {
        await _drop();
        final allowed = await permission();
        if (allowed == null || !allowed.enabled) return 0;
        // Under the system limit with the trainer reports and one left for
        // the set rest: what goes over it, Apple does not say.
        final room = systemLimit - await held() - 1;
        final free = [
          for (var id = firstId; id < firstId + idCount; id++)
            if (!_taken.contains(id)) id,
        ];
        final n = [
          boundaries.length,
          maxBoundaryNotices,
          room,
          free.length,
        ].reduce(math.min);
        for (var i = 0; i < n; i++) {
          final b = boundaries[i], voice = b.voice, id = free[i];
          _taken.add(id);
          _mine.add(id);
          await add(
            id,
            title(spec, b),
            wholeSecondUp(now.add(b.at - from)),
            voice == null ? null : NotificationSounds.of(voice),
          );
        }
        // Allowed without sound: the lock screen shows them, and the app
        // keeps saying its phrases while it is awake.
        return allowed.sound ? math.max(n, 0) : 0;
      } catch (_) {
        return 0;
      }
    });
  }

  @override
  Future<void> cancel() => onIOS ? _serial(_drop) : Future.value();

  /// Removes this run's notices, pending or delivered.
  Future<void> _drop() async {
    for (final id in _mine) {
      _taken.remove(id);
      try {
        await remove(id);
      } catch (_) {}
    }
    _mine.clear();
  }

  /// The app's notification requests the system holds now, pending or
  /// delivered (the limit's "active/pending": counted both ways, the
  /// conservative reading).
  @protected
  Future<int> held() async {
    final plugin = await AgentAlarm.plugin;
    if (plugin == null) return 0;
    final pending = await plugin.pendingNotificationRequests();
    final shown = await plugin.getActiveNotifications();
    return pending.length + shown.length;
  }

  /// Notifications allowed, and with sound; null when unavailable (the
  /// plugin did not start: web, tests).
  @protected
  Future<({bool enabled, bool sound})?> permission() async {
    final plugin = await AgentAlarm.plugin;
    final options = await plugin
        ?.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    return options == null
        ? null
        : (enabled: options.isEnabled, sound: options.isSoundEnabled);
  }

  /// [sound]: a file in Library/Sounds; null plays the default sound.
  @protected
  Future<void> add(int id, String title, DateTime at, String? sound) async {
    final plugin = await AgentAlarm.plugin;
    await plugin?.zonedSchedule(
      id,
      title,
      null,
      tz.TZDateTime.from(at, tz.UTC),
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          sound: sound,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @protected
  Future<void> remove(int id) async =>
      (await AgentAlarm.plugin)?.cancel(id);

  @protected
  Future<void> prepareSounds(Iterable<String> voices) =>
      NotificationSounds.prepare(voices);
}

/// The calendar trigger keeps whole seconds (flutter_local_notifications'
/// iOS side drops the fraction): rounded up, a notice is never early.
@visibleForTesting
DateTime wholeSecondUp(DateTime t) {
  final r = t.microsecondsSinceEpoch % Duration.microsecondsPerSecond;
  return r == 0
      ? t
      : t.add(Duration(microseconds: Duration.microsecondsPerSecond - r));
}
