import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'rest_recovery.dart';
import 'timing_audio.dart';

/// Timing is derived from the saved title, so old records need no migration.
class TimingSpec {
  const TimingSpec({
    this.bpm,
    this.tabata = false,
    this.work = 20,
    this.rest = 10,
    this.rounds = 8,
  });
  final int? bpm;
  final bool tabata;
  final int work, rest, rounds;

  // 10~120 을 10 씩. voom-frontend 의 BPM 타이머와 같은 눈금이다 — 같은 사람이
  // 두 앱을 쓰는데 한 번 누르는 폭이 다르면 손이 헷갈린다.
  static const minBpm = 10, maxBpm = 120, bpmStep = 10;
  static const minSeconds = 1, maxSeconds = 600;

  TimingSpec copyWith({int? bpm, int? work, int? rest, int? rounds}) =>
      TimingSpec(
        bpm: bpm ?? this.bpm,
        tabata: tabata,
        work: work ?? this.work,
        rest: rest ?? this.rest,
        rounds: rounds ?? this.rounds,
      );

  /// 이 설정을 제목에 다시 적는다.
  ///
  /// **설정을 따로 저장하지 않는다.** 제목이 곧 설정이라 옛 기록에 옮길 것이
  /// 없고, 사람이 글로 고쳐도 버튼으로 고쳐도 같은 곳이 바뀐다. 두 군데에
  /// 두면 언젠가 어긋난다.
  String applyTo(String name) {
    var out = name;
    if (bpm != null) {
      final withNumber = RegExp(
        r'([+-]?\d+(?:[.,]\d+)?)(\s*bpm(?![a-z]))',
        caseSensitive: false,
      );
      final afterWord = RegExp(
        r'((?<![a-z])bpm\s*[:=]?\s*)([+-]?\d+(?:[.,]\d+)?)',
        caseSensitive: false,
      );
      if (withNumber.hasMatch(out)) {
        out = out.replaceFirstMapped(withNumber, (m) => '$bpm${m[2]}');
      } else if (afterWord.hasMatch(out)) {
        out = out.replaceFirstMapped(afterWord, (m) => '${m[1]}$bpm');
      } else {
        final bare = RegExp(r'(?<![a-z])bpm(?![a-z])', caseSensitive: false);
        out = bare.hasMatch(out)
            ? out.replaceFirst(bare, '${bpm}bpm')
            : '${out.trimRight()} ${bpm}bpm';
      }
    }
    if (tabata) {
      final interval = RegExp(
        r'(\d+)(\s*(?:초|s|sec)?\s*[/／]\s*)(\d+)(\s*(?:초|s|sec)?)',
        caseSensitive: false,
      );
      if (interval.hasMatch(out)) {
        out = out.replaceFirstMapped(
          interval,
          (m) => '$work${m[2]}$rest${m[4]}',
        );
      } else if (work != 20 || rest != 10) {
        // 기본값은 안 적는다. 안 바꾼 것까지 제목에 붙으면 지저분해진다.
        out = '${out.trimRight()} $work/$rest';
      }
      final reps = RegExp(
        r'([x×]\s*)(\d+)|(\d+)(\s*(?:라운드|rounds?|ラウンド))',
        caseSensitive: false,
      );
      if (reps.hasMatch(out)) {
        out = out.replaceFirstMapped(
          reps,
          (m) => m[1] != null ? '${m[1]}$rounds' : '$rounds${m[4]}',
        );
      } else if (rounds != 8) {
        out = '${out.trimRight()} x$rounds';
      }
    }
    return out;
  }

  bool get valid =>
      (bpm == null || (bpm! >= minBpm && bpm! <= maxBpm)) &&
      work >= minSeconds &&
      work <= maxSeconds &&
      rest >= minSeconds &&
      rest <= maxSeconds &&
      rounds >= 1 &&
      rounds <= 99;
  int get duration => 3 + (work + rest) * rounds;

  static TimingSpec? parse(String name) {
    final bpmWord = RegExp(r'(?<![a-z])bpm(?![a-z])', caseSensitive: false);
    final hasBpm = bpmWord.hasMatch(name);
    final tabata = RegExp(
      r'타바타|タバタ|(?<![a-z])tabata(?![a-z])',
      caseSensitive: false,
    ).hasMatch(name);
    if (!hasBpm && !tabata) return null;
    final tempo = RegExp(
      r'([+-]?\d+(?:[.,]\d+)?)\s*bpm(?![a-z])|(?<![a-z])bpm\s*[:=]?\s*([+-]?\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    ).firstMatch(name);
    final bpm = hasBpm
        ? (tempo == null ? 120 : int.tryParse(tempo[1] ?? tempo[2]!) ?? 0)
        : null;
    final interval = RegExp(
      r'(\d+)\s*(?:초|s|sec)?\s*[/／]\s*(\d+)\s*(?:초|s|sec)?',
      caseSensitive: false,
    ).firstMatch(name);
    final repetitions = RegExp(
      r'[x×]\s*(\d+)|(\d+)\s*(?:라운드|rounds?|ラウンド)',
      caseSensitive: false,
    ).firstMatch(name);
    return TimingSpec(
      bpm: bpm,
      tabata: tabata,
      work: interval == null ? 20 : int.parse(interval[1]!),
      rest: interval == null ? 10 : int.parse(interval[2]!),
      rounds: repetitions == null
          ? 8
          : int.parse(repetitions[1] ?? repetitions[2]!),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TimingSpec &&
      bpm == other.bpm &&
      tabata == other.tabata &&
      work == other.work &&
      rest == other.rest &&
      rounds == other.rounds;
  @override
  int get hashCode => Object.hash(bpm, tabata, work, rest, rounds);
}

/// 세는 말. 한국어는 헬스장에서 "일, 이, 삼" 이라 세지 않는다 — "하나, 둘, 셋"
/// 이다. 숫자를 읽는 말과 개수를 세는 말이 다른 언어라서, 그 언어에서만 말로
/// 바꾼다. 다른 언어는 숫자를 그대로 둔다 — 영어의 one·two·three 는 눈으로
/// 읽을 때 12 보다 느리고, 일본어·중국어는 숫자를 읽는 말이 곧 세는 말이다.
///
/// **백 자리는 한자말이고 그 아래는 고유어다** — 백하나, 이백서른일곱. 실제로
/// 그렇게 센다. 고유어에는 백에 해당하는 말이 없다(온은 이제 안 쓴다).
///
/// 천을 넘으면 숫자로 돌아간다. 한 세트에 천 번을 세는 일은 없고, 그때는
/// 말이 길어져 힐끗 보고 못 읽는다.
String spokenCount(int n, String languageCode) {
  if (languageCode != 'ko' || n < 1 || n > 999) return '$n';
  const ones = ['', '하나', '둘', '셋', '넷', '다섯', '여섯', '일곱', '여덟', '아홉'];
  const tens = ['', '열', '스물', '서른', '마흔', '쉰', '예순', '일흔', '여든', '아흔'];
  const sino = ['', '백', '이백', '삼백', '사백', '오백', '육백', '칠백', '팔백', '구백'];
  return '${sino[n ~/ 100]}${tens[n % 100 ~/ 10]}${ones[n % 10]}';
}

/// 세는 말 한 마디를 얼마나 빨리 읽고, 그러면 얼마나 걸리는가.
///
/// 말이 다음 박자 전에 끝나야 숫자가 안 빠진다. "스물일곱" 은 네 음절이라
/// 100bpm(0.6초)에 기본 속도로는 안 들어간다. 박자에 맞춰 빠르게 읽되 최대
/// 두 배까지만 — 그 이상은 알아듣기 어렵다.
///
/// 말은 클릭 뒤 반 박에 시작하므로(템포 앱과 같다) 반 박보다 긴 숫자는 다음
/// 클릭 위로 이어진다. 의도한 것이다 — 숫자끼리 겹치지만 않으면 된다.
///
/// ponytail: 음절당 시간은 어림값이다. 기기 음성이 더 느리면 [syllableSeconds]
/// 를 올린다(실기기에서 숫자가 빠지면 이것부터).
const syllableSeconds = 0.2, speechLead = 0.08;
({double rate, double seconds}) countPace(
  String text,
  String languageCode,
  int bpm,
) {
  // 한국어는 글자가 곧 음절이다. 다른 말은 숫자 한 자리를 두세 음절로 본다 —
  // seventy-seven 은 다섯, setenta y siete 는 여섯이다. 넉넉히 잡는다.
  final syllables = languageCode == 'ko' ? text.length : text.length * 2.5;
  final budget = 60 / bpm * 0.9 - speechLead;
  final rate = budget <= 0
      ? 2.0
      : (syllables * syllableSeconds / budget).clamp(1.15, 2.0).toDouble();
  return (rate: rate, seconds: speechLead + syllables * syllableSeconds / rate);
}

enum TimingPhase { ready, work, rest, complete }

/// A monotonic clock determines phases; delayed frames never lengthen a round.
class WorkoutTimer extends ChangeNotifier with WidgetsBindingObserver {
  WorkoutTimer({TimingAudio? audio, Duration Function()? now})
    : _audio = audio ?? createTimingAudio() {
    _now = now;
    _watch.start();
    _audio.onInterrupted = pause;
    WidgetsBinding.instance.addObserver(this);
  }
  final TimingAudio _audio;
  late final Duration Function()? _now;
  final _watch = Stopwatch();
  Duration get _time => _now?.call() ?? _watch.elapsed;
  Timer? _ticker;
  Object? owner;
  TimingSpec? spec;
  bool running = false, soundFailed = false, _disposed = false;

  /// 박자마다 몇 번째인지 읽어 줄까. 화면을 안 보고 운동할 때 쓴다.
  bool countAloud = false;

  /// 어느 말로 읽을까. 화면 언어를 그대로 따른다.
  String voiceLocale = 'en';

  /// 라운드가 끝날 때 뭐라고 알릴까. 말은 화면이 만든다 — 타이머는 소리만 낸다.
  String Function(int round)? announceRound;
  Duration _elapsed = Duration.zero, _started = Duration.zero;
  Future<void> _commands = Future.value();
  Duration get elapsed =>
      _elapsed + (running ? _time - _started : Duration.zero);

  /// 시작 전 3초. 메트로놈도 센다 — 첫 클릭이 바로 울리면 손이 자리에 없다.
  /// 템포 앱의 "Start in 3s" 와 같다: 띠·띠·띠 뒤에 한 옥타브 위 긴 소리.
  TimingPhase get phase {
    final seconds = elapsed.inMilliseconds / 1000;
    if (seconds < 3) return TimingPhase.ready;
    if (spec?.tabata != true) return TimingPhase.work;
    if (seconds >= spec!.duration) return TimingPhase.complete;
    return (seconds - 3) % (spec!.work + spec!.rest) < spec!.work
        ? TimingPhase.work
        : TimingPhase.rest;
  }

  int get round => spec?.tabata != true
      ? 1
      : ((elapsed.inMilliseconds / 1000 - 3) / (spec!.work + spec!.rest))
                .floor()
                .clamp(0, spec!.rounds - 1) +
            1;

  /// 지금 운동 구간에서 몇 번째 박자인가. 소리가 안 날 때는 0.
  ///
  /// 네이티브 오디오가 버퍼를 반복 재생하므로 박자마다 콜백이 오지 않는다.
  /// 지난 시간으로 세면 콜백을 기다릴 필요가 없고 어긋나지도 않는다.
  int get beat {
    final bpm = spec?.bpm;
    if (bpm == null || !running || phase != TimingPhase.work) return 0;
    return (_intoWork * bpm / 60).floor() + 1;
  }

  /// 운동 구간에 들어선 지 몇 초.
  double get _intoWork {
    final seconds = elapsed.inMilliseconds / 1000 - 3;
    return spec!.tabata ? seconds % (spec!.work + spec!.rest) : seconds;
  }

  /// 지금 박자에 들어선 지 몇 초. 박자가 없으면 null. 나머지(%)로 구하지
  /// 않는다 — 6.6 % 0.6 이 0.5999… 가 되어 박자 하나를 통째로 앞당긴다.
  double? get _intoBeat {
    final n = beat;
    if (n == 0) return null;
    final into = _intoWork - (n - 1) * 60 / spec!.bpm!;
    return into < 0 ? 0 : into;
  }

  int get remaining {
    final seconds = elapsed.inMilliseconds / 1000;
    if (phase == TimingPhase.ready) return (3 - seconds).ceil();
    if (spec?.tabata != true) return elapsed.inSeconds - 3;
    if (phase == TimingPhase.complete) return 0;
    final within = (seconds - 3) % (spec!.work + spec!.rest);
    return ((phase == TimingPhase.work ? spec!.work : spec!.work + spec!.rest) -
            within)
        .ceil();
  }

  /// 지금 쉬는 중이면 남은 휴식을 건너뛰고 다음 세트로 간다.
  ///
  /// 시계를 앞으로 당기는 것으로 끝낸다 — 구간·라운드·소리는 전부 지난
  /// 시간에서 나오므로, 이 한 줄이면 tick 이 알아서 다음 구간의 신호를 낸다.
  /// 되감는 길은 두지 않는다. 휴식은 짧아지기만 한다.
  void skipRest() {
    // 같이 하는 중에는 건너뛰지 않는다 — 나만 앞서 가면 같이 하는 것이 아니다.
    if (!running || shared || phase != TimingPhase.rest) return;
    final seconds = elapsed.inMilliseconds / 1000;
    final cycle = spec!.work + spec!.rest;
    final within = (seconds - 3) % cycle;
    _elapsed += Duration(milliseconds: ((cycle - within) * 1000).round());
    tick();
  }

  /// 상대와 같은 시각에 맞춰 도는 중인가([follow]). 혼자 시작하면 꺼진다.
  bool shared = false;

  void toggle(Object block, TimingSpec value) {
    if (!value.valid) return;
    if (!identical(owner, block) || spec != value || shared) {
      pause();
      owner = block;
      spec = value;
      shared = false;
      _elapsed = Duration.zero;
    }
    if (running) {
      pause();
      return;
    }
    if (phase == TimingPhase.complete) _elapsed = Duration.zero;
    _start();
  }

  /// 같이 하는 타이머의 자리 [at] 에 맞춘다. 이미 그 자리에서 돌고 있으면 아무
  /// 일도 하지 않으므로 몇 번을 불러도 된다 — 늦게 들어온 폰, 앱을 내렸다 올린
  /// 폰, 시계 보정이 크게 바뀐 폰이 모두 이 한 길로 제자리에 온다.
  ///
  /// [at] 은 음수일 수 있다: 아직 시작 전이거나, 교대에서 내 차례가 뒤다. 그동안은
  /// 준비 구간이고 남은 초가 3 보다 크게 보인다.
  void follow(Object block, TimingSpec value, Duration at) {
    if (!value.valid) return;
    final same = shared && identical(owner, block) && spec == value;
    // 0.3초 안쪽의 차이는 고치지 않는다. 고칠 때마다 소리가 끊긴다.
    if (same && running && (elapsed - at).inMilliseconds.abs() < 300) return;
    pause();
    owner = block;
    spec = value;
    shared = true;
    _elapsed = at;
    _start();
  }

  void _start() {
    soundFailed = false;
    _voiceFreeAt = 0;
    _started = _time;
    running = true;
    _lastPhase = phase;
    _lastRound = round;
    _lastRemaining = remaining;
    _lastBeat = beat;
    _sound(
      cue: phase == TimingPhase.ready
          // 같이 할 때는 준비가 3초보다 길 수 있다. 그동안은 조용하다.
          ? (remaining <= 3 ? 'ready' : null)
          // 같이 하는 타이머에는 쉬는 도중에 들어올 수도 있다. 그때는 시작 신호가 아니다.
          : spec!.tabata && (phase == TimingPhase.work || !shared)
          ? 'work'
          : null,
    );
    // 박 중간에서 다시 시작했으면(멈췄다 켬, 같이 하기 재동기화) 그 박자의 숫자는
    // 읽을 때(반 박)가 아직 안 왔을 때만 읽는다. 지났으면 다음 박자부터.
    final into = _intoBeat;
    if (countAloud &&
        _lastBeat > 0 &&
        into != null &&
        into < 60 / spec!.bpm! / 2) {
      _say(_lastBeat);
    }
    // 100ms 마다 보면 구간이 바뀐 것을 최대 100ms 늦게 안다 — 그만큼 소리가
    // 밀린다. 50ms 로 보면 절반이고, 하는 일은 값 비교뿐이라 싸다.
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
    notifyListeners();
  }

  TimingPhase? _lastPhase;
  int? _lastRound, _lastRemaining;
  int _lastBeat = 0;
  int _voiceGeneration = 0;

  /// 앞 말이 끝나는 때(지난 시간, 초). 이보다 이른 박자는 읽지 않는다.
  double _voiceFreeAt = 0;

  void _say(int n) {
    final bpm = spec?.bpm;
    if (bpm == null) return;
    final text = spokenCount(n, voiceLocale);
    final pace = countPace(text, voiceLocale, bpm);
    // 박자가 **시작한** 때로 잰다. 틱이 알아챈 때(0~50ms 늦다)로 재면 늦게
    // 알아챈 박자 뒤의 숫자가 운에 따라 빠진다.
    final start = elapsed.inMilliseconds / 1000 - (_intoBeat ?? 0);
    // 빨리 읽어도 한 박에 안 들어가면, 앞 말이 끝난 뒤 첫 박자에서 읽는다.
    // 예전에는 네이티브가 "아직 말하는 중" 이면 그냥 버려서 어느 숫자가 빠질지
    // 운이었다 — 여기서 미리 정하면 빠지는 박자가 늘 같다.
    if (start + 0.01 < _voiceFreeAt) return;
    _voiceFreeAt = start + pace.seconds;
    _speak(text, rate: pace.rate);
  }

  /// 세대가 바뀌면(멈춤·되감기) 줄 서 있던 말은 버린다.
  void _speak(String text, {double rate = 1.15}) {
    final generation = _voiceGeneration;
    _commands = _commands.then((_) async {
      if (_disposed || generation != _voiceGeneration) return;
      // 읽다 실패해도 박자는 계속 간다. 소리는 덤이지 타이머의 전제가 아니다.
      try {
        await _audio.speak(text, voiceLocale, rate: rate);
      } catch (_) {}
    });
  }

  void tick() {
    if (!running) return;
    final next = phase;
    if (next == TimingPhase.complete) {
      _elapsed = Duration(seconds: spec!.duration);
      running = false;
      _ticker?.cancel();
      _voiceGeneration++;
      _sound(cue: 'complete');
      notifyListeners();
      return;
    }
    if (next != _lastPhase || round != _lastRound) {
      _sound(cue: next == TimingPhase.work ? 'work' : 'rest');
      // 운동 구간이 끝나면 몇 라운드를 마쳤는지 말한다. 쉬는 동안이라 시작
      // 신호나 박자 세는 말과 겹치지 않는다.
      if (next == TimingPhase.rest && _lastPhase == TimingPhase.work) {
        final said = announceRound?.call(round);
        if (said != null) _speak(said);
      }
    } else if ((next == TimingPhase.ready || spec!.tabata) &&
        remaining <= 3 &&
        remaining != _lastRemaining) {
      // 구간마다 마지막 3초를 띠·띠·띠 하고 센다 — 타바타 앱들의 공통 신호다.
      // 화면을 안 보고도 다음 구간이 오는 것을 몸이 안다. 준비 3초도 같은 소리.
      _sound(cue: 'ready');
    }
    final counted = beat;
    if (counted != _lastBeat) {
      _lastBeat = counted;
      if (countAloud && counted > 0) _say(counted);
    }
    if (next != _lastPhase ||
        remaining != _lastRemaining ||
        round != _lastRound) {
      _lastPhase = next;
      _lastRound = round;
      _lastRemaining = remaining;
      notifyListeners();
    }
  }

  void _sound({String? cue}) {
    final active = running;
    final bpm = active && phase == TimingPhase.work ? spec?.bpm : null;
    _commands = _commands.then((_) async {
      if (_disposed) return;
      try {
        // 박 안의 자리는 보내는 순간에 잰다 — 앞 명령을 기다린 만큼 늦었다.
        await _audio.configure(
          active: active,
          bpm: bpm,
          cue: cue,
          phase: bpm == null ? null : _intoBeat,
        );
      } catch (_) {
        if (!_disposed) {
          soundFailed = true;
          notifyListeners();
        }
      }
    });
  }

  void pause() {
    if (!running) return;
    _elapsed = elapsed;
    running = false;
    _voiceGeneration++;
    _ticker?.cancel();
    _sound();
    notifyListeners();
  }

  void reset() {
    pause();
    _elapsed = Duration.zero;
    shared = false;
    notifyListeners();
  }

  void clear() {
    reset();
    owner = null;
    spec = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) pause();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    _audio.onInterrupted = null;
    unawaited(_commands.then((_) => _audio.dispose()));
    super.dispose();
  }
}

/// 같이 하기가 타이머 칸에 보태는 것. 없으면 혼자 쓰는 타이머 그대로다.
///
/// 칸은 그리기만 한다. 누가 제안했고 지금 어디쯤인지는 받은 대로 보여 주고,
/// 눌린 것은 그대로 돌려준다 — 서버와 말하는 것은 부르는 쪽이다.
class TogetherTiming {
  const TogetherTiming({
    required this.partner,
    required this.onPropose,
    required this.onToggle,
    required this.onCancel,
    required this.onLog,
    this.waiting = false,
    this.busy = false,
    this.live = false,
    this.left = false,
    this.alternate = false,
    this.partnerLeft,
    this.mine = const [],
    this.theirs = const [],
    this.more = const [],
  });
  final String partner;

  /// 내가 제안했고 상대의 답을 기다린다.
  final bool waiting;

  /// 다른 칸에서 같이 하는 중이다. 여기서 새로 제안하면 그것이 끊긴다 — 상대는
  /// 한창 운동 중이다. 제안 버튼을 내지 않는다.
  final bool busy;

  /// 이 칸의 타이머를 둘이 같이 돌리고 있다(아직 안 끝났다).
  final bool live;

  /// 나는 그만뒀다. 아직 돌고 있으면 다시 들어갈 수 있다.
  final bool left;
  final bool alternate;

  /// 상대가 그만둔 자리를 말로. 없으면 아직 하고 있다.
  final String? partnerLeft;

  /// 세트마다의 횟수. 안 적은 세트는 null 이다 — 0 이 아니다.
  final List<int?> mine, theirs;

  /// 셋 이상이 같이 할 때 [partner] 말고 나머지 사람들의 줄.
  final List<({String name, List<int?> counts})> more;

  /// 가장 많이 적은 사람의 세트 수. 짧은 줄은 여기까지 – 로 채운다.
  int get longest => [
    mine.length,
    theirs.length,
    for (final p in more) p.counts.length,
  ].reduce((a, b) => a > b ? a : b);

  final void Function(bool alternate) onPropose;

  /// 시작·정지를 눌렀다. true 를 돌려주면 같이 하기가 처리한 것이다(그만두기·
  /// 다시 들어가기). false 면 혼자 쓰는 타이머가 평소대로 움직인다.
  final bool Function() onToggle;
  final VoidCallback onCancel;
  final ValueChanged<int> onLog;
}

class WorkoutTimingControls extends StatelessWidget {
  const WorkoutTimingControls({
    super.key,
    required this.owner,
    required this.spec,
    required this.timer,
    required this.onStart,
    this.onChanged,
    this.recovery,
    this.together,
  });

  /// 같이 운동 중일 때만 있다.
  final TogetherTiming? together;
  final Object owner;
  final TimingSpec spec;
  final WorkoutTimer timer;
  final VoidCallback onStart;

  /// 심박으로 휴식을 끊어 주는 쪽. 없으면 심박을 그리지 않는다.
  final RestRecovery? recovery;

  /// 버튼으로 고친 설정. 받는 쪽이 운동 이름을 다시 적는다 — 제목이 설정이다.
  final ValueChanged<TimingSpec>? onChanged;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // 심박이 바뀌어도 다시 그려야 한다. 둘 다 듣는다.
    listenable: recovery == null ? timer : Listenable.merge([timer, recovery]),
    builder: (context, _) {
      final l = L.of(context);
      final selected = identical(timer.owner, owner);
      final running = selected && timer.running;
      final phase = selected ? timer.phase : TimingPhase.ready;
      final seconds = selected ? timer.remaining : 3;
      final beat = selected ? timer.beat : 0;
      final counted = spokenCount(beat, l.localeName.split('_').first);
      // 템포 앱처럼 초를 맨숫자로 크게. "0:20" 보다 "20" 이 힐끗 봐도 읽힌다.
      // 1분을 넘는 구간만 분:초. 메트로놈은 준비 뒤로는 몇 번째 박자인지.
      final big = !spec.tabata && phase != TimingPhase.ready
          ? (beat > 0 ? '$beat' : '')
          : seconds < 60
          ? '$seconds'
          : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
      final bigColor = switch (phase) {
        TimingPhase.work => seal.resolveFrom(context),
        TimingPhase.rest => CupertinoColors.systemGreen.resolveFrom(context),
        TimingPhase.ready when selected && timer.running =>
          CupertinoColors.label.resolveFrom(context),
        _ => CupertinoColors.tertiaryLabel.resolveFrom(context),
      };
      final round = selected ? timer.round : 1;
      final doneRounds = switch (phase) {
        TimingPhase.complete => spec.rounds,
        TimingPhase.ready => 0,
        _ => round - 1,
      };
      final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
      // 돌아가는 중에 길이를 바꾸면 남은 시간이 튄다. 멈춘 뒤에 바꾸게 한다.
      final editable =
          onChanged != null &&
          !running &&
          !(together?.live ?? false) &&
          !(together?.waiting ?? false);
      void change(TimingSpec next) {
        if (next.valid && next != spec) onChanged!(next);
      }

      int lessSeconds(int n) => n - 5 < 5 ? TimingSpec.minSeconds : n - 5;

      final duo = together;
      final sharing = duo != null && duo.live && selected && timer.shared;
      // 교대에서는 내가 쉬는 동안이 곧 상대의 차례다. 시작 전 긴 준비도 그렇다.
      final theirTurn =
          sharing &&
          duo.alternate &&
          running &&
          (phase == TimingPhase.rest ||
              (phase == TimingPhase.ready && seconds > 3));
      final phaseLabel = theirTurn
          ? l.togetherTheirTurn
          : switch (phase) {
              TimingPhase.ready => l.timingReady,
              TimingPhase.work => l.timingWork,
              TimingPhase.rest => l.timingRest,
              TimingPhase.complete => l.timingComplete,
            };
      // 심박은 쉬는 동안에만 붙인다. 세트 중에는 볼 겨를도 없고, 회복을
      // 재는 것은 휴식이다. 값이 낡았으면 아무것도 안 쓴다 — 옛 숫자를
      // 지금 심박인 척 보여 주면 안 된다.
      final heart = recovery;
      final showHeart =
          heart != null &&
          selected &&
          phase == TimingPhase.rest &&
          heart.fresh &&
          heart.target != null;
      final heartLine = showHeart
          ? ' · ${l.timingHeart(heart.bpm!, heart.target!)}'
          : '';
      final status = spec.tabata
          ? '$phaseLabel · ${l.timingRound(round, spec.rounds)}'
                '${beat > 0 ? ' · ${l.timingBeat(counted)}' : ''}$heartLine'
          : selected && phase == TimingPhase.ready
          ? phaseLabel
          // 박자는 큰 숫자로 이미 보인다. 옆에는 무엇인지만 적는다 —
          // "5 · 다섯" 처럼 같은 것을 두 번 쓰지 않는다.
          : l.timingMetronome;
      void toggle() {
        if (duo != null && duo.onToggle()) return;
        if (!running) onStart();
        timer.toggle(owner, spec);
      }

      // 돌아가는 중에 길이를 바꾸면 두 폰이 어긋난다. 같이 하는 동안은 잠근다.
      final canPropose =
          duo != null &&
          !duo.live &&
          !duo.waiting &&
          !duo.busy &&
          !running &&
          spec.valid;
      final canAlternate =
          spec.tabata && spec.work + 2 * spec.rest <= TimingSpec.maxSeconds;
      // 쉬는 동안, 방금 끝난 라운드를 아직 안 적었으면 한 번 눌러 적게 한다.
      // 숨이 찬 10초에 숫자판을 열어 치라고 할 수는 없다.
      final owesCount =
          sharing &&
          spec.tabata &&
          running &&
          phase == TimingPhase.rest &&
          duo.mine.length < round;

      // 칸 너비를 똑같이 고정한다. 예전에는 Wrap 이라 5초→10초 처럼 글자가
      // 한 자 늘면 마지막 칸이 다음 줄로 떨어지고 카드 아래가 통째로 밀렸다.
      final cells = <Widget>[
        if (spec.bpm != null)
          _Stepper(
            label: l.timingBpm(spec.bpm!),
            onLess: editable && spec.bpm! > TimingSpec.minBpm
                ? () =>
                      change(spec.copyWith(bpm: spec.bpm! - TimingSpec.bpmStep))
                : null,
            onMore: editable && spec.bpm! < TimingSpec.maxBpm
                ? () =>
                      change(spec.copyWith(bpm: spec.bpm! + TimingSpec.bpmStep))
                : null,
          ),
        if (spec.tabata) ...[
          _Stepper(
            label: l.timingWorkSeconds(spec.work),
            onLess: editable && spec.work > TimingSpec.minSeconds
                ? () => change(spec.copyWith(work: lessSeconds(spec.work)))
                : null,
            onMore: editable && spec.work < TimingSpec.maxSeconds
                ? () => change(spec.copyWith(work: spec.work + 5))
                : null,
          ),
          _Stepper(
            label: l.timingRestSeconds(spec.rest),
            onLess: editable && spec.rest > TimingSpec.minSeconds
                ? () => change(spec.copyWith(rest: lessSeconds(spec.rest)))
                : null,
            onMore: editable && spec.rest < TimingSpec.maxSeconds
                ? () => change(spec.copyWith(rest: spec.rest + 5))
                : null,
          ),
          _Stepper(
            label: l.timingRounds(spec.rounds),
            onLess: editable && spec.rounds > 1
                ? () => change(spec.copyWith(rounds: spec.rounds - 1))
                : null,
            onMore: editable && spec.rounds < 99
                ? () => change(spec.copyWith(rounds: spec.rounds + 1))
                : null,
          ),
        ],
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [for (final c in cells) Expanded(child: c)]),
            if (!spec.valid)
              Text(
                l.timingInvalid,
                style: TextStyle(fontSize: 13, color: muted),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 템포 앱처럼 숫자 자체를 눌러도 시작·정지. 헬스장에서 작은
                  // 글자 버튼을 겨누기 어렵다.
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: toggle,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (big.isNotEmpty) ...[
                            Text(
                              big,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                color: bigColor,
                                letterSpacing: -1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Flexible(
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: muted,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    onPressed: toggle,
                    child: Text(
                      duo != null && duo.live
                          ? (duo.left ? l.togetherRejoin : l.togetherLeave)
                          : running
                          ? l.timingPause
                          : l.timingStart,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    // 같이 하는 동안 나만 되감을 수는 없다.
                    onPressed: selected && !(duo?.live ?? false)
                        ? timer.reset
                        : null,
                    child: Icon(
                      CupertinoIcons.arrow_counterclockwise,
                      size: 18,
                      semanticLabel: l.timingReset,
                    ),
                  ),
                ],
              ),
              // 라운드마다 한 칸. 템포 앱의 고리를 글줄에 맞게 눕힌 것이다.
              if (spec.tabata)
                _RoundBar(
                  rounds: spec.rounds,
                  done: doneRounds,
                  current:
                      running &&
                          (phase == TimingPhase.work ||
                              phase == TimingPhase.rest)
                      ? doneRounds
                      : null,
                  color: bigColor,
                ),
            ],
            if (duo != null && spec.valid) ...[
              if (canPropose)
                Row(
                  children: [
                    CupertinoButton(
                      key: const ValueKey('together-start'),
                      padding: const EdgeInsets.only(right: 16),
                      minimumSize: const Size(0, 32),
                      onPressed: () => duo.onPropose(false),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.person_2_fill, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            l.togetherStart,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (canAlternate)
                      CupertinoButton(
                        key: const ValueKey('together-alternate'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        onPressed: () => duo.onPropose(true),
                        child: Text(
                          l.togetherAlternate,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              if (duo.waiting) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.togetherWaiting(duo.partner),
                        style: TextStyle(fontSize: 14, color: muted),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      onPressed: duo.onCancel,
                      child: Text(
                        l.cancel,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                Text(
                  l.togetherWaitingHint,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
              if (owesCount)
                _CountEntry(
                  // 라운드가 바뀌면 새로 센다.
                  key: ValueKey('together-count-$round'),
                  initial:
                      duo.mine.whereType<int>().lastOrNull ??
                      duo.theirs.whereType<int>().lastOrNull ??
                      10,
                  label: l.togetherLog,
                  onLog: duo.onLog,
                ),
              if (duo.longest > 0)
                for (final (name, counts) in [
                  (l.togetherMe, duo.mine),
                  (duo.partner, duo.theirs),
                  for (final p in duo.more) (p.name, p.counts),
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            // 짧은 쪽은 – 로 채운다. 안 적은 것이지 0 이 아니다.
                            [
                              ...counts,
                              for (var i = counts.length; i < duo.longest; i++)
                                null,
                            ].map((n) => n ?? '–').join('  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              if (duo.partnerLeft != null)
                Text(
                  duo.partnerLeft!,
                  style: TextStyle(fontSize: 13, color: muted),
                )
              // 표에 이미 상대 이름이 있으면 또 적지 않는다.
              else if (duo.live && duo.longest == 0)
                Text(
                  l.togetherWith(duo.partner),
                  style: TextStyle(fontSize: 13, color: muted),
                ),
            ],
            if (selected && timer.soundFailed)
              Text(
                l.timingSoundFailed,
                style: TextStyle(fontSize: 13, color: muted),
              ),
          ],
        ),
      );
    },
  );
}

/// 방금 한 라운드의 횟수를 한 번에 적는다: − 12 + [기록].
class _CountEntry extends StatefulWidget {
  const _CountEntry({
    super.key,
    required this.initial,
    required this.label,
    required this.onLog,
  });
  final int initial;
  final String label;
  final ValueChanged<int> onLog;
  @override
  State<_CountEntry> createState() => _CountEntryState();
}

class _CountEntryState extends State<_CountEntry> {
  late int _n = widget.initial;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _RepeatingKey(
        onTap: _n > 0 ? () => setState(() => _n--) : null,
        child: const Icon(CupertinoIcons.minus_circle, size: 30),
      ),
      SizedBox(
        width: 56,
        child: Text(
          '$_n',
          key: const ValueKey('together-count'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
      _RepeatingKey(
        onTap: _n < 999 ? () => setState(() => _n++) : null,
        child: const Icon(CupertinoIcons.plus_circle, size: 30),
      ),
      const Spacer(),
      CupertinoButton.filled(
        key: const ValueKey('together-log'),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        minimumSize: const Size(0, 36),
        onPressed: () => widget.onLog(_n),
        child: Text(widget.label),
      ),
    ],
  );
}

/// 값 한 줄 위에, −/+ 한 줄 아래. 칸 너비는 부모가 고정한다.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, this.onLess, this.onMore});
  final String label;
  final VoidCallback? onLess, onMore;

  @override
  Widget build(BuildContext context) {
    Widget key(IconData icon, VoidCallback? tap, String semantics) =>
        _RepeatingKey(
          onTap: tap,
          child: Icon(icon, size: 16, semanticLabel: semantics),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            key(CupertinoIcons.minus, onLess, '-'),
            key(CupertinoIcons.plus, onMore, '+'),
          ],
        ),
      ],
    );
  }
}

/// 누르고 있으면 되풀이한다 — 20초를 600초로 올릴 때 116번 두드리지 않게.
class _RepeatingKey extends StatefulWidget {
  const _RepeatingKey({required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_RepeatingKey> createState() => _RepeatingKeyState();
}

class _RepeatingKeyState extends State<_RepeatingKey> {
  Timer? _repeat;

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: widget.onTap == null
        ? null
        : (_) => _repeat = Timer.periodic(
            const Duration(milliseconds: 120),
            (_) => widget.onTap == null ? _stop() : widget.onTap!(),
          ),
    onLongPressEnd: (_) => _stop(),
    onLongPressCancel: _stop,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(40, 32),
      onPressed: widget.onTap,
      child: widget.child,
    ),
  );
}

/// 라운드 칸. 지금 하는 칸은 깜빡여서 어디쯤인지 눈으로 잡힌다.
class _RoundBar extends StatefulWidget {
  const _RoundBar({
    required this.rounds,
    required this.done,
    required this.current,
    required this.color,
  });
  final int rounds, done;

  /// 지금 진행 중인 칸(0부터). 멈춰 있거나 준비·완료면 null.
  final int? current;
  final Color color;

  @override
  State<_RoundBar> createState() => _RoundBarState();
}

class _RoundBarState extends State<_RoundBar>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _RoundBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.current == null) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true, min: 0.2, max: 1);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idle = CupertinoColors.systemFill.resolveFrom(context);
    final done = seal.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Row(
          children: [
            for (var i = 0; i < widget.rounds; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    color: i == widget.current
                        ? widget.color.withValues(alpha: _pulse.value)
                        : i < widget.done
                        ? done
                        : idle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
