import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:setpad/health.dart';

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

  setUp(() {
    health = _Health();
    link = HealthLink(health: health, platform: TargetPlatform.iOS);
    calls = [];
    granted = null;
    authorized = true;
    messenger.setMockMethodCallHandler(healthChannel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'hasPermissions' => granted,
        'requestAuthorization' => authorized,
        'writeWorkoutData' => true,
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
    'workouts pass measured calories and the manual recording method to native code',
    () async {
      expect(
        await link.writeWorkout(
          start: start,
          end: end,
          title: '벤치프레스',
          energyBurned: 30.25,
        ),
        isTrue,
      );
      final args = calls.single.arguments as Map;
      expect(args['activityType'], 'STRENGTH_TRAINING');
      expect(args['totalEnergyBurned'], 30);
      expect(args['totalEnergyBurnedUnit'], 'KILOCALORIE');
      expect(args['recordingMethod'], RecordingMethod.manual.toInt());
      expect(args['startTime'], start.millisecondsSinceEpoch);
      expect(args['endTime'], end.millisecondsSinceEpoch);
    },
  );

  test(
    'workout writes preserve unknown calories and reject invalid intervals',
    () async {
      expect(await link.writeWorkout(start: start, end: start), isFalse);
      expect(await link.writeWorkout(start: end, end: start), isFalse);
      expect(calls, isEmpty);
      expect(await link.writeWorkout(start: start, end: end), isTrue);
      expect((calls.single.arguments as Map)['totalEnergyBurned'], isNull);
    },
  );

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
    expect(await desktop.writeWorkout(start: start, end: end), isFalse);
    expect(calls, isEmpty);
    expect(health.configureCount, 0);
  });
}
