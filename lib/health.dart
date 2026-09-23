import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

/// 한 번 잰 심박. [at] 은 **잰 시각**이고 [lag] 은 그것이 우리에게
/// 도착하기까지 걸린 시간이다. 휴식을 심박으로 끊으려면 값이 최신이어야
/// 하므로, 값만 있고 시각이 없으면 쓸 수가 없다.
typedef HeartBeat = ({int bpm, DateTime at, Duration lag});

/// 건강 앱 연동.
///
/// **하는 일은 둘이다.** 여기서 친 운동을 건강 앱에 운동 기록으로 남기고,
/// 그 시간 동안 **애플워치가 이미 잰** 활동 칼로리를 읽어 온다.
///
/// **칼로리를 직접 추정하지 않는다.** 무게와 횟수로 소모량을 계산하는 공식은
/// 세트 수·휴식·수행 속도를 못 보기 때문에 그럴듯한 숫자를 만들 뿐이다.
/// 워치는 심박으로 재므로 우리가 흉내 낼 이유가 없다. 워치가 없으면 칼로리는
/// 그냥 빈칸이다 — 지어내는 것보다 없는 편이 낫다.
///
/// **실패해도 조용하다.** 권한을 안 줬거나 기기에 건강 앱이 없어도 기록 자체는
/// 되어야 한다. 연동은 덤이지 전제가 아니다.
class HealthLink {
  HealthLink({Health? health, TargetPlatform? platform})
    : _health = health ?? Health(),
      _platform = platform ?? _nativePlatform;

  final Health _health;
  final TargetPlatform? _platform;
  bool _configured = false;

  // Keep each data type and its access together so the lists cannot diverge.
  // 심박은 iOS 에서만 읽는다. Play 가 Health Connect 의 심박 읽기를 "기능에
  // 필요 이상" 으로 보고 반려했다(2026-09-23) — Android 매니페스트에도 없다.
  Map<HealthDataType, HealthDataAccess> get _access => {
    HealthDataType.WORKOUT: HealthDataAccess.WRITE,
    HealthDataType.ACTIVE_ENERGY_BURNED: HealthDataAccess.READ,
    if (_platform == TargetPlatform.iOS)
      HealthDataType.HEART_RATE: HealthDataAccess.READ,
  };

  bool get _heart => supported && _platform == TargetPlatform.iOS;

  static TargetPlatform? get _nativePlatform {
    if (kIsWeb) return null;
    if (Platform.isIOS) return TargetPlatform.iOS;
    if (Platform.isAndroid) return TargetPlatform.android;
    return null;
  }

  /// 이 기기에서 쓸 수 있는가. Android 는 Health Connect 가 깔려 있어야 한다.
  bool get supported =>
      !kIsWeb &&
      (_platform == TargetPlatform.iOS || _platform == TargetPlatform.android);

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// 권한을 묻는다. 이미 있으면 묻지 않는다.
  ///
  /// 사용자가 거절해도 그만이다 — false 를 돌려주고 부르는 쪽은 넘어간다.
  Future<bool> authorize() async {
    if (!supported) return false;
    try {
      await _ensureConfigured();
      final types = _access.keys.toList();
      final permissions = _access.values.toList();
      final has = await _health.hasPermissions(types, permissions: permissions);
      if (has ?? false) return true;
      return await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
    } catch (e) {
      debugPrint('건강 권한 요청 실패: $e');
      return false;
    }
  }

  /// 그 시간 동안 워치가 잰 활동 칼로리 합. 잰 것이 없으면 null.
  ///
  /// 0 이 아니라 null 인 이유는 "0 킬로칼로리를 태웠다"와 "아무도 재지
  /// 않았다"가 다른 말이기 때문이다.
  Future<double?> activeEnergy(DateTime start, DateTime end) async {
    if (!supported) return null;
    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      double? total;
      for (final p in points) {
        if (p.type != HealthDataType.ACTIVE_ENERGY_BURNED) continue;
        final v = p.value;
        if (v is NumericHealthValue) {
          total = (total ?? 0) + v.numericValue.toDouble();
        }
      }
      return total;
    } catch (e) {
      debugPrint('활동 칼로리 읽기 실패: $e');
      return null;
    }
  }

  /// 워치가 심박을 쓸 때마다 iOS 가 앱을 깨워 올려 보내는 값.
  ///
  /// health 플러그인에는 이 경로가 없다 — iOS 쪽이 일회성 쿼리만 구현하고
  /// HKObserverQuery 와 enableBackgroundDelivery 가 빠져 있다. 그 두 개만
  /// 우리가 붙였다(ios/Runner/HeartRateObserver.swift).
  static const _channel = MethodChannel('setpad/heart_rate');

  /// 심박이 올 때마다 부른다. [sinceLastWake] 는 직전 깨어남과의 간격 —
  /// HealthKit 이 실제로 얼마나 자주 깨워 주는지가 여기 드러난다. 심박으로
  /// 휴식을 끊어 줄 수 있는지가 이 숫자에 달려 있어서 같이 낸다.
  void onBeat(
    void Function({
      required int bpm,
      required Duration lag,
      Duration? sinceLastWake,
    })
    f,
  ) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'beat') return null;
      final a = (call.arguments as Map).cast<String, dynamic>();
      final since = a['sinceLastWakeSeconds'] as int?;
      f(
        bpm: a['bpm'] as int,
        lag: Duration(seconds: a['lagSeconds'] as int),
        sinceLastWake: since == null ? null : Duration(seconds: since),
      );
      return null;
    });
  }

  /// 관찰을 시작한다. 권한을 거절하거나 기기가 안 되면 false.
  Future<bool> watchHeartRate() async {
    if (!supported || _platform != TargetPlatform.iOS) return false;
    try {
      return await _channel.invokeMethod<bool>('start') ?? false;
    } catch (e) {
      debugPrint('심박 관찰 시작 실패: $e');
      return false;
    }
  }

  Future<void> unwatchHeartRate() async {
    if (!supported || _platform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod<bool>('stop');
    } catch (e) {
      debugPrint('심박 관찰 중지 실패: $e');
    }
  }

  /// 심박을 계속 받는다. **두 플랫폼의 차이는 여기서 끝난다.**
  ///
  /// iOS 는 워치가 값을 쓸 때마다 HealthKit 이 앱을 깨워 밀어 준다. Android
  /// 의 Health Connect 에는 밀어 주는 길이 없어서 주기적으로 읽는 수밖에
  /// 없다. 같은 값을 여러 번 읽게 되지만, 받는 쪽이 [HeartBeat.at] 으로
  /// 걸러내므로 문제가 되지 않는다.
  Stream<HeartBeat> beats({Duration poll = const Duration(seconds: 10)}) {
    if (!_heart) return const Stream.empty();
    return _platform == TargetPlatform.iOS ? _pushed() : _polled(poll);
  }

  Stream<HeartBeat> _pushed() {
    late final StreamController<HeartBeat> out;
    out = StreamController<HeartBeat>(
      onListen: () async {
        if (!await watchHeartRate()) {
          await out.close();
          return;
        }
        onBeat(({required bpm, required lag, sinceLastWake}) {
          if (!out.isClosed) {
            out.add((bpm: bpm, at: DateTime.now().subtract(lag), lag: lag));
          }
        });
        // 첫 값은 기다리지 않는다 — 워치가 다음에 쓸 때까지 화면이 빈다.
        final first = await latestHeartRate();
        if (first != null && !out.isClosed) out.add(first);
      },
      onCancel: unwatchHeartRate,
    );
    return out.stream;
  }

  /// 듣는 사람이 없으면 알아서 멈춘다 — async* 가 그렇게 동작한다.
  Stream<HeartBeat> _polled(Duration every) async* {
    while (true) {
      final beat = await latestHeartRate();
      if (beat != null) yield beat;
      await Future<void>.delayed(every);
    }
  }

  /// 가장 최근 심박과 **그것이 언제 측정된 것인지**.
  ///
  /// 시각을 같이 돌려주는 게 요점이다. 심박으로 휴식을 끊어 주려면 값이
  /// 최신이어야 하는데, 워치 앱 없이 아이폰이 워치 심박을 얼마나 빨리 받는지는
  /// 재보기 전에는 알 수 없다. 몇 초면 쓸 수 있고 몇 분이면 못 쓴다.
  /// 그 판단을 하려고 지연을 같이 낸다.
  Future<HeartBeat?> latestHeartRate() async {
    if (!_heart) return null;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now,
      );
      if (points.isEmpty) return null;
      points.sort((a, b) => a.dateTo.compareTo(b.dateTo));
      final last = points.last;
      final v = last.value;
      if (v is! NumericHealthValue) return null;
      return (
        bpm: v.numericValue.round(),
        at: last.dateTo,
        lag: now.difference(last.dateTo),
      );
    } catch (e) {
      debugPrint('심박 읽기 실패: $e');
      return null;
    }
  }

  /// 운동 하나를 건강 앱에 남긴다. 성공하면 true.
  Future<bool> writeWorkout({
    required DateTime start,
    required DateTime end,
    String? title,
    double? energyBurned,
  }) async {
    if (!supported) return false;
    // 시작과 끝이 같으면 건강 앱이 받지 않는다.
    if (!end.isAfter(start)) return false;
    try {
      await _ensureConfigured();
      return await _health.writeWorkoutData(
        // iOS 의 HealthKit 에는 STRENGTH_TRAINING 이 없다 — 폰 로그가 "not supported
        // on iOS" 로 거절했다. 안드로이드는 반대로 TRADITIONAL 을 모른다.
        activityType: Platform.isIOS
            ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
            : HealthWorkoutActivityType.STRENGTH_TRAINING,
        start: start,
        end: end,
        title: title,
        totalEnergyBurned: energyBurned?.round(),
        // iOS 는 manual/automatic 만 받는다. 사람이 친 기록이므로 manual 이다.
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('운동 기록 쓰기 실패: $e');
      return false;
    }
  }
}
