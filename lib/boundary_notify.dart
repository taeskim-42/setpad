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

  /// Ids [firstId] .. [firstId] + [maxBoundaryNotices] - 1: under the set
  /// rest's (LocalRestNotifier.id, 2147480000), above every trainer report
  /// id (< 2,016,000,000).
  static const firstId = 2147470000;

  /// Plugin calls in order: a cancel never overtakes a schedule.
  Future<void> _chain = Future.value();
  Future<T> _serial<T>(Future<T> Function() f) {
    final next = _chain.then((_) => f());
    _chain = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  @protected
  bool get onIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> prepare(Iterable<String> voices) =>
      onIOS ? prepareSounds(voices) : Future.value();

  @override
  Future<bool> schedule(
    TimingSpec spec,
    List<Boundary> boundaries, {
    required Duration from,
    required DateTime now,
  }) {
    if (!onIOS) return Future.value(false);
    return _serial(() async {
      try {
        final allowed = await permission();
        if (allowed == null || !allowed.enabled) return false;
        for (final (i, b) in boundaries.take(maxBoundaryNotices).indexed) {
          final voice = b.voice;
          await add(
            firstId + i,
            title(spec, b),
            now.add(b.at - from),
            voice == null ? null : NotificationSounds.of(voice),
          );
        }
        // Allowed without sound: the lock screen shows them, and the app
        // keeps saying its phrases while it is awake.
        return allowed.sound;
      } catch (_) {
        return false;
      }
    });
  }

  @override
  Future<void> cancel() => onIOS
      ? _serial(() async {
          for (var i = 0; i < maxBoundaryNotices; i++) {
            try {
              await remove(firstId + i);
            } catch (_) {}
          }
        })
      : Future.value();

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
