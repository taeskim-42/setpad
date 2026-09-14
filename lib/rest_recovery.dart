import 'dart:async';

import 'package:flutter/foundation.dart';

import 'health.dart';

/// 휴식을 심박으로 끊는다.
///
/// **절대값은 기준이 못 된다.** 같은 130bpm 이 누구에겐 전력이고 누구에겐
/// 걷기다. 그래서 "이 세트에서 가장 높았던 값에서 얼마나 내려왔나" 로 본다 —
/// 사람마다 다른 것은 최고 심박이지, 회복했다는 사실이 아니다.
///
/// **못 하면 조용히 안 한다.** 워치가 없거나 권한을 안 줬거나 값이 너무
/// 늦게 오면 [recovered] 는 계속 false 이고, 휴식은 원래대로 시간이 끊는다.
/// 심박은 휴식을 **짧게** 만들 뿐 길게 만들지 않는다.
class RestRecovery extends ChangeNotifier {
  RestRecovery({
    required this.health,
    this.drop = 25,
    this.stale = const Duration(seconds: 90),
    this.minimumRest = const Duration(seconds: 5),
  });

  final HealthLink health;

  /// 최고에서 이만큼 내려오면 회복으로 본다.
  final int drop;

  /// 이보다 오래된 값은 지금 심박이 아니다. 워치가 손목에서 내려갔거나
  /// 앱이 깨어나지 못한 것이므로, 옛 숫자로 휴식을 끊으면 안 된다.
  final Duration stale;

  /// 휴식이 시작되자마자 끊기지 않게 하는 최소 시간. 세트 직후 심박은
  /// 아직 올라가는 중이라 그 순간의 비교는 의미가 없다.
  final Duration minimumRest;

  StreamSubscription<HeartBeat>? _feed;
  DateTime? _restStarted;

  int? _bpm;
  int? _peak;
  DateTime? _at;

  /// 마지막으로 받은 심박. 아직 하나도 못 받았으면 null.
  int? get bpm => _bpm;

  /// 이번 세트의 최고. 회복을 재는 기준선이다.
  int? get peak => _peak;

  /// 지금 심박이라고 할 수 있는가.
  bool get fresh =>
      _at != null && DateTime.now().difference(_at!) <= stale && _bpm != null;

  /// 휴식을 끊어도 되는가.
  bool get recovered {
    final started = _restStarted;
    if (started == null || !fresh || _peak == null) return false;
    if (DateTime.now().difference(started) < minimumRest) return false;
    return _bpm! <= _peak! - drop;
  }

  /// 회복까지 남은 심박. 화면에 "132 → 118" 을 그리는 데 쓴다.
  int? get target => _peak == null ? null : _peak! - drop;

  /// 심박 받기를 시작한다. 이미 받고 있으면 아무 일도 하지 않는다.
  void listen() {
    _feed ??= health.beats().listen(_took, onError: (_) {});
  }

  /// 한 세트가 시작됐다. 기준선을 새로 잡는다.
  ///
  /// 최고는 **휴식 동안에도** 계속 갱신한다 — 세트 직후 몇 초 동안 심박이
  /// 더 오르는 것이 보통이고, 그 꼭대기가 진짜 기준선이다.
  void beginRound() {
    _peak = null;
    _restStarted = null;
    notifyListeners();
  }

  /// 휴식이 시작됐다.
  void beginRest() {
    _restStarted = DateTime.now();
    notifyListeners();
  }

  /// 타이머가 멈췄다. 다음에 켤 때 옛 기준선이 남아 있으면 안 된다.
  void reset() {
    _peak = null;
    _restStarted = null;
    notifyListeners();
  }

  void _took(HeartBeat beat) {
    // 같은 값을 다시 읽은 것이면(Android 는 주기적으로 읽는다) 버린다.
    if (_at != null && !beat.at.isAfter(_at!)) return;
    _bpm = beat.bpm;
    _at = beat.at;
    if (_peak == null || beat.bpm > _peak!) _peak = beat.bpm;
    notifyListeners();
  }

  @override
  void dispose() {
    _feed?.cancel();
    _feed = null;
    super.dispose();
  }
}
