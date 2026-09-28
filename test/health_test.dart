import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:setpad/health.dart';
import 'package:setpad/notes.dart';

// Keep the plugin's actual permission validation and workout serialization.
// Only device discovery and sensor samples need a stand-in on the host Mac.
class _Health extends Health {
  var configureCount = 0;
  List<HealthDataPoint> points = [];
  List<HealthDataType>? requestedTypes;
  (DateTime, DateTime)? interval;
  bool failQuery = false;

  @override
  Future<void> configure() async => configureCount++;

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    required DateTime startTime,
    required DateTime endTime,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    requestedTypes = types;
    interval = (startTime, endTime);
    if (failQuery) throw PlatformException(code: 'unavailable');
    return [...points];
  }
}

HealthDataPoint _point(HealthDataType type, double value, DateTime at) =>
    HealthDataPoint(
      uuid: '$type-$value-$at',
      value: NumericHealthValue(numericValue: value),
      type: type,
      unit: type == HealthDataType.HEART_RATE
          ? HealthDataUnit.BEATS_PER_MINUTE
          : HealthDataUnit.KILOCALORIE,
      dateFrom: at.subtract(const Duration(minutes: 1)),
      dateTo: at,
      sourcePlatform: HealthPlatformType.appleHealth,
      sourceDeviceId: 'test-watch',
      sourceId: 'test-health',
      sourceName: 'Test Watch',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const healthChannel = MethodChannel('flutter_health');
  const heartChannel = MethodChannel('setpad/heart_rate');
  final start = DateTime(2026, 9, 7, 10);
  final end = start.add(const Duration(hours: 1));
  late _Health health;
  late HealthLink link;
  late List<MethodCall> calls;
  bool? granted;
  var authorized = true;
  String? written;
  var deleted = true;

  setUp(() {
    health = _Health();
    link = HealthLink(health: health, platform: TargetPlatform.iOS);
    calls = [];
    granted = null;
    authorized = true;
    written = 'w1';
    deleted = true;
    messenger.setMockMethodCallHandler(healthChannel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'hasPermissions' => granted,
        'requestAuthorization' => authorized,
        'writeWorkoutDataUUID' => written,
        'deleteByUUID' => deleted,
        'delete' => true,
        _ => throw MissingPluginException(call.method),
      };
    });
    messenger.setMockMethodCallHandler(heartChannel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(healthChannel, null);
    messenger.setMockMethodCallHandler(heartChannel, null);
    heartChannel.setMethodCallHandler(null);
  });

  test(
    'authorization reaches the native plugin with matching access for all types',
    () async {
      expect(await link.authorize(), isTrue);
      expect(calls.map((c) => c.method), [
        'hasPermissions',
        'requestAuthorization',
      ]);
      for (final call in calls) {
        final args = call.arguments as Map;
        expect(args['types'], [
          'WORKOUT',
          'ACTIVE_ENERGY_BURNED',
          'BASAL_ENERGY_BURNED',
          'HEART_RATE',
        ]);
        expect(args['permissions'], [
          HealthDataAccess.WRITE.index,
          HealthDataAccess.READ.index,
          HealthDataAccess.READ.index,
          HealthDataAccess.READ.index,
        ]);
      }
      expect(health.configureCount, 1);
    },
  );

  test(
    'existing permissions skip the prompt and configuration is reused',
    () async {
      granted = true;
      expect(await link.authorize(), isTrue);
      expect(await link.authorize(), isTrue);
      expect(calls.map((c) => c.method), ['hasPermissions', 'hasPermissions']);
      expect(health.configureCount, 1);
    },
  );

  test('permission denial returns false', () async {
    granted = false;
    authorized = false;
    expect(await link.authorize(), isFalse);
  });

  test('permission errors do not interrupt workout logging', () async {
    messenger.setMockMethodCallHandler(healthChannel, (_) async {
      throw PlatformException(code: 'denied');
    });
    expect(await link.authorize(), isFalse);
  });

  test(
    'calories exclude heart rate samples and use the workout interval',
    () async {
      health.points = [
        _point(HealthDataType.ACTIVE_ENERGY_BURNED, 12.5, end),
        _point(HealthDataType.HEART_RATE, 140, end),
        _point(HealthDataType.ACTIVE_ENERGY_BURNED, 17.75, end),
      ];
      expect(await link.activeEnergy(start, end), 30.25);
      expect(health.requestedTypes, [HealthDataType.ACTIVE_ENERGY_BURNED]);
      expect(health.interval, (start, end));
    },
  );

  test(
    'missing energy data remains unknown, including heart-rate-only data',
    () async {
      expect(await link.activeEnergy(start, end), isNull);
      health.points = [_point(HealthDataType.HEART_RATE, 140, end)];
      expect(await link.activeEnergy(start, end), isNull);
    },
  );

  test('a recorded zero is distinct from missing calorie data', () async {
    health.points = [_point(HealthDataType.ACTIVE_ENERGY_BURNED, 0, end)];
    expect(await link.activeEnergy(start, end), 0);
  });

  test('read errors preserve the no-data behavior', () async {
    health.failQuery = true;
    expect(await link.activeEnergy(start, end), isNull);
    expect(await link.latestHeartRate(), isNull);
  });

  test(
    'latest heart rate selects the newest sample and reports its age',
    () async {
      final now = DateTime.now();
      final latest = now.subtract(const Duration(seconds: 20));
      health.points = [
        _point(HealthDataType.HEART_RATE, 123, latest),
        _point(
          HealthDataType.HEART_RATE,
          90,
          now.subtract(const Duration(minutes: 10)),
        ),
      ];
      final result = await link.latestHeartRate();
      expect(result?.bpm, 123);
      expect(result?.at, latest);
      expect(result!.lag.inSeconds, inInclusiveRange(20, 21));
      expect(health.requestedTypes, [HealthDataType.HEART_RATE]);
    },
  );

  test(
    'the first save clears this app’s copies at the same start, then writes measured calories (iOS)',
    () async {
      final saved = await link.saveWorkout(
        start: start,
        end: end,
        title: '벤치프레스',
        energyBurned: 30.25,
      );
      expect(calls.map((c) => c.method), ['delete', 'writeWorkoutDataUUID']);
      final cleared = calls.first.arguments as Map;
      expect(cleared['dataTypeKey'], 'WORKOUT');
      expect(
        cleared['startTime'],
        start.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch,
      );
      expect(
        cleared['endTime'],
        start.add(const Duration(seconds: 1)).millisecondsSinceEpoch,
        reason: '예전 판이 이 기록으로 쌓은 것만 — 구간 전체를 지우지 않는다',
      );
      final args = calls.last.arguments as Map;
      expect(args['activityType'], 'TRADITIONAL_STRENGTH_TRAINING');
      expect(args['title'], '벤치프레스');
      expect(args['totalEnergyBurned'], 30);
      expect(args['totalEnergyBurnedUnit'], 'KILOCALORIE');
      expect(args['recordingMethod'], RecordingMethod.manual.toInt());
      expect(args['startTime'], start.millisecondsSinceEpoch);
      expect(args['endTime'], end.millisecondsSinceEpoch);
      expect(saved!.id, 'w1');
      expect(saved.covers(start, end), isTrue);
      expect(saved.kcal, 30);
    },
  );

  test(
    'no time-range delete when another record’s workout covers this start',
    () async {
      final saved = await link.saveWorkout(
        start: start,
        end: end,
        clearLegacy: false,
      );
      expect(calls.map((c) => c.method), ['writeWorkoutDataUUID']);
      expect(saved!.id, 'w1');
    },
  );

  test('leaving again with the same interval writes nothing', () async {
    final first = await link.saveWorkout(
      start: start,
      end: end,
      energyBurned: 30,
    );
    calls.clear();
    expect(
      await link.saveWorkout(
        start: start,
        end: end,
        energyBurned: 30.2,
        previous: first,
      ),
      same(first),
    );
    expect(
      await link.saveWorkout(start: start, end: end, previous: first),
      same(first),
      reason: '칼로리를 이번에 못 읽었다고 적어 둔 칼로리를 지우지 않는다',
    );
    expect(calls, isEmpty);
  });

  test(
    'a longer workout or late watch calories replace only this record’s workout',
    () async {
      const old = 'old';
      final first = HealthWorkout(id: old, from: start, to: end, kcal: 30);
      final later = end.add(const Duration(minutes: 20));
      written = 'w2';
      final longer = await link.saveWorkout(
        start: start,
        end: later,
        energyBurned: 41,
        previous: first,
      );
      expect(calls.map((c) => c.method), [
        'deleteByUUID',
        'writeWorkoutDataUUID',
      ]);
      expect(calls.first.arguments, {'uuid': old, 'dataTypeKey': 'WORKOUT'});
      expect(longer!.id, 'w2');
      expect(longer.covers(start, later), isTrue);
      expect(longer.kcal, 41);

      calls.clear();
      written = 'w3';
      final synced = await link.saveWorkout(
        start: start,
        end: later,
        energyBurned: 48,
        previous: longer,
      );
      expect(calls.map((c) => c.method), [
        'deleteByUUID',
        'writeWorkoutDataUUID',
      ]);
      expect(synced!.kcal, 48, reason: '워치 칼로리가 늦게 들어왔다');
    },
  );

  test(
    'nothing new is written while the old workout cannot be removed',
    () async {
      deleted = false;
      final first = HealthWorkout(id: 'old', from: start, to: end);
      final saved = await link.saveWorkout(
        start: start,
        end: end.add(const Duration(minutes: 5)),
        previous: first,
      );
      expect(saved, same(first), reason: '새로 쓰면 둘이 된다');
      expect(calls.map((c) => c.method), ['deleteByUUID']);
    },
  );

  test('a failed write after removing the old workout leaves none', () async {
    written = '';
    final first = HealthWorkout(id: 'old', from: start, to: end);
    expect(
      await link.saveWorkout(
        start: start,
        end: end.add(const Duration(minutes: 5)),
        previous: first,
      ),
      isNull,
      reason: '다음에 나올 때 처음부터 다시 쓴다',
    );
    written = null;
    expect(await link.saveWorkout(start: start, end: end), isNull);
  });

  test(
    'Android writes the session without calories (no total-calories permission)',
    () async {
      final android = HealthLink(
        health: health,
        platform: TargetPlatform.android,
      );
      final saved = await android.saveWorkout(
        start: start,
        end: end,
        energyBurned: 30.25,
      );
      final args = calls.last.arguments as Map;
      expect(args['activityType'], 'STRENGTH_TRAINING');
      expect(args['totalEnergyBurned'], isNull);
      expect(saved!.kcal, isNull);
      calls.clear();
      expect(
        await android.saveWorkout(
          start: start,
          end: end,
          energyBurned: 45,
          previous: saved,
        ),
        same(saved),
        reason: '운동에 칼로리를 적지 않으니 칼로리만 바뀌어서는 다시 쓸 것이 없다',
      );
      expect(calls, isEmpty);
    },
  );

  test(
    'workout saves preserve unknown calories and reject invalid intervals',
    () async {
      expect(await link.saveWorkout(start: start, end: start), isNull);
      expect(await link.saveWorkout(start: end, end: start), isNull);
      expect(calls, isEmpty);
      expect(await link.saveWorkout(start: start, end: end), isNotNull);
      expect((calls.last.arguments as Map)['totalEnergyBurned'], isNull);
    },
  );

  test('a note remembers the workout it left in the health app', () {
    final note = Note(id: 'n', createdAt: start, updatedAt: end)
      ..healthWorkout = HealthWorkout(id: 'w', from: start, to: end, kcal: 30);
    final back = Note.fromJson(
      jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
    );
    expect(back.healthWorkout!.id, 'w');
    expect(back.healthWorkout!.covers(start, end), isTrue);
    expect(back.healthWorkout!.kcal, 30);
    final plain = Note(id: 'm', createdAt: start, updatedAt: end).toJson();
    expect(plain.containsKey('healthWorkout'), isFalse);
    expect(Note.fromJson(plain).healthWorkout, isNull);
    expect(
      HealthWorkout.tryFromJson({
        'id': '',
        'from': start.toIso8601String(),
        'to': end.toIso8601String(),
      }),
      isNull,
    );
  });

  test(
    'heart-rate observation starts and stops through the native channel',
    () async {
      expect(await link.watchHeartRate(), isTrue);
      await link.unwatchHeartRate();
      expect(calls.map((c) => c.method), ['start', 'stop']);
    },
  );

  test(
    'heart-rate events preserve latency and an absent previous wake',
    () async {
      final beats = <(int, Duration, Duration?)>[];
      link.onBeat(({required bpm, required lag, sinceLastWake}) {
        beats.add((bpm, lag, sinceLastWake));
      });
      for (final gap in [null, 45]) {
        await messenger.handlePlatformMessage(
          heartChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('beat', {
              'bpm': 123,
              'lagSeconds': 7,
              'sinceLastWakeSeconds': gap,
            }),
          ),
          (_) {},
        );
      }
      expect(beats, [
        (123, const Duration(seconds: 7), null),
        (123, const Duration(seconds: 7), const Duration(seconds: 45)),
      ]);
    },
  );

  test('unsupported platforms do not invoke health APIs', () async {
    final desktop = HealthLink(health: health, platform: TargetPlatform.macOS);
    expect(await desktop.authorize(), isFalse);
    expect(await desktop.activeEnergy(start, end), isNull);
    expect(await desktop.latestHeartRate(), isNull);
    expect(await desktop.watchHeartRate(), isFalse);
    expect(await desktop.saveWorkout(start: start, end: end), isNull);
    expect(calls, isEmpty);
    expect(health.configureCount, 0);
  });
}
