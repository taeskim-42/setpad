/// 같이 하는 타이머 — 두 폰이 같은 타바타·같은 박자를 같은 순간에 돌린다.
///
/// **주고받는 것은 시작 시각 하나다.** 구간·라운드·박자는 전부 지난 시간에서
/// 나오므로([WorkoutTimer]), 늦게 들어온 폰도 앱을 내렸다 올린 폰도 그 시각만
/// 알면 제자리로 돌아온다. 그래서 여기에는 "동기화" 가 없다 — 매번 같은 계산을
/// 다시 할 뿐이다.
///
/// **상대가 받아들여야 시작한다.** 주머니 속 폰이 남이 누른 버튼 때문에 울리면
/// 안 되고, 둘 다 화면을 보고 있을 때 정한 시각이라야 3·2·1 을 같이 센다.
///
/// 라운드마다의 횟수는 여기에 없다. 각자의 기록에 세트로 남고, 상대 것은 이미
/// 공유되는 상대 기록에서 읽는다.
library;

import 'workout_timing.dart';

/// 서버 시계를 이 기기의 **단조 시계**로 옮긴다. 벽시계는 쓰지 않는다 — 운동
/// 중에 자동 시각 맞춤이 돌면 몇 초씩 튄다.
///
/// 요청마다 한 번 잰다. 서버 시각은 보낸 때와 받은 때의 한가운데에 찍혔다고
/// 보므로 오차는 왕복 시간의 절반을 넘지 않는다. 그래서 왕복이 가장 짧았던
/// 표본을 믿는다. 다만 영원히 믿지는 않는다 — 두 시계는 조금씩 벌어지므로
/// 오래된 표본은 분당 10ms 씩 못 미더워진다.
class ServerClock {
  ServerClock({Duration Function()? monotonic}) : _now = monotonic;
  final Duration Function()? _now;
  final _watch = Stopwatch()..start();
  Duration get monotonic => _now?.call() ?? _watch.elapsed;

  int? _offset, _rtt;
  Duration _taken = Duration.zero;

  void sample(Duration sent, Duration received, int serverNow) {
    final rtt = (received - sent).inMilliseconds;
    if (rtt < 0) return;
    final aged = _rtt == null
        ? null
        : _rtt! + (received - _taken).inMilliseconds ~/ 6000;
    if (aged != null && rtt > aged) return;
    _rtt = rtt;
    _taken = received;
    _offset = serverNow - (sent + received).inMilliseconds ~/ 2;
  }

  /// 지금의 서버 시각(ms). 한 번도 못 쟀으면 null — 짐작하지 않는다.
  int? get now => _offset == null ? null : monotonic.inMilliseconds + _offset!;
}

class SharedTimer {
  const SharedTimer({
    required this.seq,
    required this.title,
    required this.spec,
    required this.alternate,
    required this.mine,
    this.startAt,
    this.myLeft,
    this.partnerLeft,
    this.joined = true,
    this.others = const [],
  });

  /// 제안마다 오른다. 옛 제안을 향한 동작은 서버가 버린다.
  final int seq;

  /// 제안한 사람의 운동 이름 그대로. 받는 쪽은 이 이름으로 자기 칸을 만든다.
  final String title;
  final TimingSpec spec;

  /// 교대 — 기구 하나를 번갈아 쓴다. 제안한 사람이 먼저 한다.
  final bool alternate;

  /// 내가 제안했는가.
  final bool mine;

  /// 서버 시계의 epoch ms. 상대가 받아들이기 전에는 null 이다.
  final int? startAt;

  /// 그만둔 자리. 그만두는 것은 각자다 — 상대의 타이머는 계속 간다.
  final ({int ms, int beat})? myLeft, partnerLeft;

  /// 내가 동의했는가. 셋 이상이 같이 할 때, 다른 둘이 시작했다고 내 폰이 울리면
  /// 안 된다. 둘이 할 때는 시작했다는 것이 곧 동의했다는 것이다.
  final bool joined;

  /// 같이 돌리는 다른 사람들과 각자 그만둔 자리.
  final List<({String key, String name, ({int ms, int beat})? left})> others;

  bool get started => startAt != null;

  /// 이 사람이 실제로 돌리는 설정. 교대에서는 내 휴식이 상대의 운동과 두 번의
  /// 자리바꿈을 덮는다: [내 운동][바꿈][상대 운동][바꿈].
  TimingSpec get personal =>
      alternate ? spec.copyWith(rest: spec.work + 2 * spec.rest) : spec;

  /// 내 타이머가 지금 있어야 할 자리. 음수면 아직 시작 전이다 — 교대에서 뒤에
  /// 하는 사람은 상대의 첫 운동이 끝날 때까지 준비 구간에 머문다.
  Duration? elapsedAt(int? serverNow) => serverNow == null || startAt == null
      ? null
      : Duration(
          milliseconds:
              serverNow -
              startAt! -
              (alternate && !mine ? (spec.work + spec.rest) * 1000 : 0),
        );

  /// 끝났는가. 타바타는 시간이 끝낸다. 메트로놈은 끝이 없어서 둘 다 그만둬야 끝난다.
  bool overAt(int? serverNow) {
    final everyoneLeft = others.isEmpty
        ? partnerLeft != null
        : others.every((o) => o.left != null);
    if (myLeft != null && everyoneLeft) return true;
    final at = elapsedAt(serverNow);
    return spec.tabata && at != null && at.inSeconds >= personal.duration;
  }

  SharedTimer copyWith({required ({int ms, int beat})? myLeft}) => SharedTimer(
    seq: seq,
    title: title,
    spec: spec,
    alternate: alternate,
    mine: mine,
    startAt: startAt,
    myLeft: myLeft,
    partnerLeft: partnerLeft,
    joined: joined,
    others: others,
  );

  static SharedTimer? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final s = j['spec'], seq = j['seq'], title = j['title'];
    if (s is! Map || seq is! int || title is! String) return null;
    final work = s['work'], rest = s['rest'], rounds = s['rounds'];
    if (work is! int || rest is! int || rounds is! int) return null;
    final spec = TimingSpec(
      bpm: s['bpm'] is int ? s['bpm'] as int : null,
      tabata: s['tabata'] == true,
      work: work,
      rest: rest,
      rounds: rounds,
    );
    if (!spec.valid || (spec.bpm == null && !spec.tabata)) return null;
    ({int ms, int beat})? left(Object? v) =>
        v is Map && v['ms'] is int && v['beat'] is int
        ? (ms: v['ms'] as int, beat: v['beat'] as int)
        : null;
    final timer = SharedTimer(
      seq: seq,
      title: title,
      spec: spec,
      alternate: j['alternate'] == true,
      mine: j['mine'] == true,
      startAt: j['startAt'] is num ? (j['startAt'] as num).toInt() : null,
      myLeft: left(j['myLeft']),
      partnerLeft: left(j['partnerLeft']),
      // 옛 서버는 이 칸이 없다. 그때는 둘뿐이라, 내가 제안했거나 이미 시작했으면
      // 동의한 것이다.
      joined: j['joined'] is bool
          ? j['joined'] as bool
          : j['mine'] == true || j['startAt'] is num,
      others: [
        for (final o in (j['others'] as List? ?? const []))
          if (o is Map && o['key'] is String && o['name'] is String)
            (
              key: o['key'] as String,
              name: o['name'] as String,
              left: left(o['left']),
            ),
      ],
    );
    return timer.personal.valid ? timer : null;
  }
}
