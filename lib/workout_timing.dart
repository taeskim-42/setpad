import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'parser.dart'
    show tempoPattern, timerRoundsPattern, timerTabataWord, timerTokens;
import 'timing_audio.dart';

/// Timing is derived from the saved title, so old records need no migration.
class TimingSpec {
  const TimingSpec({
    this.bpm,
    this.tabata = false,
    this.work = 20,
    this.rest = 10,
    this.rounds = 8,
    this.tail = false,
  });
  final int? bpm;
  final bool tabata;
  final int work, rest, rounds;

  /// The last round keeps its rest. Only alternating shared timers set it
  /// ([SharedTimer.personal]): the partner's last turn lives in my last rest.
  /// Never written to or read from a title or JSON.
  final bool tail;

  static const minBpm = 10, maxBpm = 120;
  static const minSeconds = 1, maxSeconds = 600;

  /// Tempo written by places that create a new metronome (candidate chip,
  /// sheet). [parse] keeps 120 for a bare 'bpm' so old titles keep their meaning.
  static const newBpm = 60;

  /// The one rounds pattern ([parse], [applyTo], [marks], parser's timerTokens).
  static const roundsPattern = timerRoundsPattern;

  TimingSpec copyWith({
    int? bpm,
    int? work,
    int? rest,
    int? rounds,
    bool? tail,
  }) => TimingSpec(
    bpm: bpm ?? this.bpm,
    tabata: tabata,
    work: work ?? this.work,
    rest: rest ?? this.rest,
    rounds: rounds ?? this.rounds,
    tail: tail ?? this.tail,
  );

  /// 이 설정을 제목에 다시 적는다.
  ///
  /// **설정을 따로 저장하지 않는다.** 제목이 곧 설정이라 옛 기록에 옮길 것이
  /// 없고, 사람이 글로 고쳐도 버튼으로 고쳐도 같은 곳이 바뀐다. 두 군데에
  /// 두면 언젠가 어긋난다.
  ///
  /// A tabata name without a tabata word gets [tabataWord] (the caller picks
  /// the locale's word). `parse(applyTo(n)) == this` ([tail] aside, it is
  /// never written) when [n] has no timer word or token of a kind this spec
  /// lacks: a bpm word left in a tabata-only name reads back as a tempo, a
  /// tabata word in a metronome's as a tabata, and a metronome still reads an
  /// interval or rounds in [n] ("3/4 스쿼트" comes back with work 3 / rest 4,
  /// which a metronome does not use). Switching kinds is
  /// `applyTo(removeFrom(n))`.
  String applyTo(String name, {String tabataWord = 'Tabata'}) {
    String add(String out, String token) =>
        out.trim().isEmpty ? token : '${out.trimRight()} $token';
    var out = name;
    if (tabata) {
      if (!_tabataWord.hasMatch(out)) out = add(out, tabataWord);
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
        out = add(out, '$work/$rest');
      }
      if (_repetitions.hasMatch(out)) {
        // Only the count changes; "x 6" keeps its space, "6라운드" its word.
        out = out.replaceFirstMapped(_repetitions, (m) {
          final whole = m[0]!;
          return m[1] != null
              ? '${whole.substring(0, whole.length - m[1]!.length)}$rounds'
              : '$rounds${whole.substring(m[2]!.length)}';
        });
      } else if (rounds != 8) {
        // After a bare number " x6" reads as set notation ("3 x6"); "·x6" not.
        final appended = add(out, 'x$rounds');
        out = _repetitions.hasMatch(appended)
            ? appended
            : '${out.trimRight()} ·x$rounds';
      }
    }
    if (bpm != null) {
      // 템포 수만 바꾼다 — "bpm 3세트" 의 3 은 세트 수라 그대로 둔다.
      if (_tempo.hasMatch(out)) {
        out = out.replaceFirstMapped(
          _tempo,
          (m) => m[1] != null
              ? '$bpm${m[0]!.substring(m[1]!.length)}'
              : '${m[0]!.substring(0, m[0]!.length - m[2]!.length)}$bpm',
        );
      } else if (_bpmWord.hasMatch(out)) {
        out = out.replaceFirst(_bpmWord, '${bpm}bpm');
      } else {
        out = add(out, '${bpm}bpm');
      }
    }
    return out;
  }

  /// [name] without its timer: tempo, interval and rounds tokens (rounds with
  /// the "·" [applyTo] may put before them) and the tabata/bpm words. '' when
  /// nothing else is left. A name that is not a timer comes back trimmed and
  /// otherwise untouched.
  static String removeFrom(String name) {
    if (parse(name) == null) return name.trim();
    return name
        // Dot and rounds go together: without the dot "3 x6" is set notation.
        .replaceAll(_dotRounds, ' ')
        .replaceAll(timerTokens, ' ')
        .replaceAll(_tabataWord, ' ')
        .replaceAll(_bpmWord, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// One card line: "20s work · 10s rest × 8 · 3:53", "60 BPM · Target 30".
  String summary(L l, {int? target}) => [
    if (tabata) l.timerSummaryTabata(work, rest, rounds, timerClock(duration)),
    if (bpm != null)
      [
        l.timingBpm(bpm!),
        if (target != null && target > 0) l.timerTargetChip(target),
      ].join(' · '),
  ].join(' · ');

  bool get valid =>
      (bpm == null || (bpm! >= minBpm && bpm! <= maxBpm)) &&
      work >= minSeconds &&
      work <= maxSeconds &&
      rest >= minSeconds &&
      rest <= maxSeconds &&
      rounds >= 1 &&
      rounds <= 99;

  /// Tabata length in seconds: 3 s ready, then rounds; the last round has no
  /// rest unless [tail].
  int get duration =>
      3 + work * rounds + rest * (rounds - 1) + (tail ? rest : 0);

  static final _bpmWord = RegExp(
    r'(?<![a-z])bpm(?![a-z])',
    caseSensitive: false,
  );
  static final _tabataWord = RegExp(timerTabataWord, caseSensitive: false);
  static final _tempo = RegExp(tempoPattern, caseSensitive: false);
  static final _interval = RegExp(
    r'(\d+)\s*(?:초|s|sec)?\s*[/／]\s*(\d+)\s*(?:초|s|sec)?',
    caseSensitive: false,
  );
  static final _repetitions = RegExp(roundsPattern, caseSensitive: false);
  static final _dotRounds = RegExp(
    '·\\s*(?:$roundsPattern)',
    caseSensitive: false,
  );

  static TimingSpec? parse(String name) {
    final hasBpm = _bpmWord.hasMatch(name);
    final tabata = _tabataWord.hasMatch(name);
    if (!hasBpm && !tabata) return null;
    final tempo = _tempo.firstMatch(name);
    final bpm = hasBpm
        ? (tempo == null ? 120 : int.tryParse(tempo[1] ?? tempo[2]!) ?? 0)
        : null;
    final interval = _interval.firstMatch(name);
    final repetitions = _repetitions.firstMatch(name);
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

  /// [parse] 가 이름에서 읽는 자리 — 템포("30 bpm", "bpm 30"), 타바타의 운동/휴식
  /// 초("30초 / 15초")와 라운드("x8", "8 라운드"). 계획 줄은 이 자리를 목표로
  /// 옮기지 않고 이름에 남긴다 — 타이머는 이름에서 붙는다.
  static List<Match> marks(String name) => [
    if (_bpmWord.hasMatch(name)) ?_tempo.firstMatch(name),
    if (_tabataWord.hasMatch(name)) ...[
      ?_interval.firstMatch(name),
      ?_repetitions.firstMatch(name),
    ],
  ];

  @override
  bool operator ==(Object other) =>
      other is TimingSpec &&
      bpm == other.bpm &&
      tabata == other.tabata &&
      work == other.work &&
      rest == other.rest &&
      rounds == other.rounds &&
      tail == other.tail;
  @override
  int get hashCode => Object.hash(bpm, tabata, work, rest, rounds, tail);
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

/// "0:53", "3:53".
String timerClock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

enum TimingPhase { ready, work, rest, complete }

/// selectionClick / mediumImpact / heavyImpact / heavyImpact twice (150 ms).
enum TimerHaptic { tick, medium, heavy, success }

/// The device haptic for [kind] (no engine: nothing).
void platformHaptic(TimerHaptic kind) {
  Future<void> buzz(Future<void> Function() f) =>
      f().catchError((Object _) {}); // No haptics engine (tests, web).
  switch (kind) {
    case TimerHaptic.tick:
      buzz(HapticFeedback.selectionClick);
    case TimerHaptic.medium:
      buzz(HapticFeedback.mediumImpact);
    case TimerHaptic.heavy:
      buzz(HapticFeedback.heavyImpact);
    case TimerHaptic.success:
      buzz(HapticFeedback.heavyImpact);
      Timer(
        const Duration(milliseconds: 150),
        () => buzz(HapticFeedback.heavyImpact),
      );
  }
}

const _readyUs = 3000000;

/// A monotonic clock determines phases; delayed frames never lengthen a round.
class WorkoutTimer extends ChangeNotifier with WidgetsBindingObserver {
  /// [now] replaces the monotonic clock and [wallNow] the wall clock (tests).
  /// With [now] injected and no [wallNow] the wall-clock correction is off, so
  /// a hand-driven clock is never "corrected" by real time passing.
  WorkoutTimer({
    TimingAudio? audio,
    Duration Function()? now,
    DateTime Function()? wallNow,
    void Function(TimerHaptic)? haptic,
  }) : _audio = audio ?? createTimingAudio(),
       _now = now,
       _wallNow = wallNow ?? (now == null ? DateTime.now : null),
       _haptic = haptic ?? platformHaptic {
    _watch.start();
    _audio.onInterrupted = _onInterrupted;
    _audio.onResumed = _onResumed;
    WidgetsBinding.instance.addObserver(this);
  }
  final TimingAudio _audio;
  final Duration Function()? _now;
  final DateTime Function()? _wallNow;
  final void Function(TimerHaptic) _haptic;
  final _watch = Stopwatch();
  Duration get _time => _now?.call() ?? _watch.elapsed;
  Timer? _ticker;
  Object? owner;
  TimingSpec? spec;

  /// Metronome goal in counts (each phone its own). Ignored for tabata.
  int? target;
  bool running = false, soundFailed = false, _disposed = false;

  /// 박자마다 몇 번째인지 읽어 줄까. 화면을 안 보고 운동할 때 쓴다.
  bool countAloud = false;

  /// Buzz along with the cues (NotesStore.hapticsOn).
  bool haptics = true;

  /// 어느 말로 읽을까. 화면 언어를 그대로 따른다. Chinese script tags become
  /// the region tags the speech engines know.
  String get voiceLocale => _voiceLocale;
  set voiceLocale(String tag) => _voiceLocale = tag == 'zh'
      ? 'zh-CN'
      : tag.startsWith('zh-Hans')
      ? 'zh-CN'
      : tag.startsWith('zh-Hant')
      ? 'zh-TW'
      : tag;
  String _voiceLocale = 'en';
  String get _language => _voiceLocale.split('-').first;

  /// 라운드가 끝날 때 뭐라고 알릴까. 말은 화면이 만든다 — 타이머는 소리만 낸다.
  String Function(int round)? announceRound;

  /// Once per run: natural completion or [end] (not an end under 10 s).
  VoidCallback? onComplete;

  /// The run was ended by [end] rather than by the clock.
  bool get endedEarly => _endedEarly;
  bool _endedEarly = false;

  /// Completed or ended; [follow] leaves the same run alone until a reset.
  bool _finished = false;

  /// Which run this is. Starting from the top ([toggle] on a new or finished
  /// run, [restart], following another shared run) and [reset]/[clear] count
  /// up; pause, resume, skip, back and re-syncing a shared run do not. What
  /// was logged belongs to one run.
  int get runId => _runId;
  int _runId = 0;
  int? _countAtEnd;
  bool _interrupted = false;

  Duration _elapsed = Duration.zero, _started = Duration.zero;
  Future<void> _commands = Future.value();
  Duration get elapsed =>
      _elapsed + (running ? _time - _started : Duration.zero);

  /// 지금 심박이 쓸모 있는가 — 타바타가 돌고 있을 때만이다. 심박은 쉬는 시간을
  /// 끊는 데만 쓰는데, 박자 타이머에는 쉬는 시간이 없다. 그 밖에는 읽지 않는다.
  bool get wantsHeart =>
      running && spec?.tabata == true && phase != TimingPhase.complete;

  /// Whole run length: tabata [TimingSpec.duration]; a metronome with a
  /// [target] ends just after the target count is read (half a beat, at most a
  /// second, plus 50 ms) and before the next click. Otherwise endless (null).
  Duration? get total {
    final s = spec;
    if (s == null) return null;
    if (s.tabata) return Duration(seconds: s.duration);
    final goal = target, bpm = s.bpm;
    if (goal == null || goal < 1 || bpm == null) return null;
    final p = 60 / bpm;
    return Duration(
      microseconds: ((3 + (goal - 1) * p + math.min(p / 2, 1.0) + 0.05) * 1e6)
          .round(),
    );
  }

  /// The interval the timer is in, as (start, end) in µs from the start; end
  /// is null for an endless metronome. Null when complete.
  (int, int?)? get _segment {
    final s = spec;
    final us = elapsed.inMicroseconds;
    if (s == null) return (0, _readyUs);
    if (us < _readyUs) return (0, _readyUs);
    final t = total?.inMicroseconds;
    if (t != null && us >= t) return null;
    if (!s.tabata) return (_readyUs, t);
    final cycle = (s.work + s.rest) * 1000000, work = s.work * 1000000;
    final start = _readyUs + (us - _readyUs) ~/ cycle * cycle;
    return us - start < work
        ? (start, start + work)
        : (start + work, start + cycle);
  }

  /// 시작 전 3초. 메트로놈도 센다 — 첫 클릭이 바로 울리면 손이 자리에 없다.
  /// 템포 앱의 "Start in 3s" 와 같다: 띠·띠·띠 뒤에 한 옥타브 위 긴 소리.
  TimingPhase get phase {
    final us = elapsed.inMicroseconds;
    if (us < _readyUs) return TimingPhase.ready;
    final t = total;
    if (t != null && elapsed >= t) return TimingPhase.complete;
    if (spec?.tabata != true) return TimingPhase.work;
    final cycle = (spec!.work + spec!.rest) * 1000000;
    return (us - _readyUs) % cycle < spec!.work * 1000000
        ? TimingPhase.work
        : TimingPhase.rest;
  }

  int get round => spec?.tabata != true
      ? 1
      : ((elapsed.inMicroseconds - _readyUs) ~/
                    ((spec!.work + spec!.rest) * 1000000))
                .clamp(0, spec!.rounds - 1) +
            1;

  /// 지금 운동 구간에서 몇 번째 박자인가. 소리가 안 날 때는 0.
  ///
  /// 네이티브 오디오가 버퍼를 반복 재생하므로 박자마다 콜백이 오지 않는다.
  /// 지난 시간으로 세면 콜백을 기다릴 필요가 없고 어긋나지도 않는다.
  int get beat => running ? _liveCount : 0;

  /// Beats counted in the current work interval; kept while paused. Frozen at
  /// the value it had when the run completed or was ended.
  int get count {
    if (_finished || phase == TimingPhase.complete) return _countAtEnd ?? 0;
    return _liveCount;
  }

  int get _liveCount {
    final bpm = spec?.bpm;
    if (bpm == null || phase != TimingPhase.work) return 0;
    return (_intoWork * bpm / 60).floor() + 1;
  }

  /// 운동 구간에 들어선 지 몇 초.
  double get _intoWork {
    final us = elapsed.inMicroseconds - _readyUs;
    return (spec!.tabata ? us % ((spec!.work + spec!.rest) * 1000000) : us) /
        1e6;
  }

  /// 지금 박자에 들어선 지 몇 초. 박자가 없으면 null. 나머지(%)로 구하지
  /// 않는다 — 6.6 % 0.6 이 0.5999… 가 되어 박자 하나를 통째로 앞당긴다.
  double? get _intoBeat {
    final n = beat;
    if (n == 0) return null;
    final into = _intoWork - (n - 1) * 60 / spec!.bpm!;
    return into < 0 ? 0 : into;
  }

  /// Landed in a beat whose number is not read yet: its time (half a beat in)
  /// has not come. [_start] and [_seek] land mid-beat.
  bool get _unread {
    final into = _intoBeat;
    return into != null && into < 60 / spec!.bpm! / 2;
  }

  int get remaining {
    final seconds = elapsed.inMicroseconds / 1e6;
    final current = phase;
    if (current == TimingPhase.ready) return (3 - seconds).ceil();
    if (spec?.tabata != true) return elapsed.inSeconds - 3;
    final segment = _segment;
    if (segment == null) return 0;
    return ((segment.$2! - elapsed.inMicroseconds) / 1e6).ceil();
  }

  /// How far into the current interval (ready, work, rest); zero when complete.
  Duration get phaseElapsed {
    final segment = _segment;
    if (segment == null) return Duration.zero;
    final us = elapsed.inMicroseconds - segment.$1;
    return Duration(microseconds: us < 0 ? 0 : us);
  }

  /// Water level 0..1 for the stage: ready drains over 3 s, a tabata interval
  /// over its length, a metronome with a target by counts; 1 without a target.
  double get level {
    final current = phase;
    if (current == TimingPhase.complete) return 0;
    final us = elapsed.inMicroseconds;
    if (current == TimingPhase.ready) {
      return (1 - us / _readyUs).clamp(0.0, 1.0).toDouble();
    }
    final s = spec!;
    if (!s.tabata) {
      final goal = target;
      if (goal == null || goal < 1 || s.bpm == null) return 1;
      return (1 - count / goal).clamp(0.0, 1.0).toDouble();
    }
    final (start, end) = _segment!;
    return ((end! - us) / (end - start)).clamp(0.0, 1.0).toDouble();
  }

  /// 상대와 같은 시각에 맞춰 도는 중인가([follow]). 혼자 시작하면 꺼진다.
  bool shared = false;

  /// Started since the last rewind — "paused at 0 s" is not "not started".
  bool _begun = false;

  bool get _paused => !running && spec != null && _begun && !_finished;

  /// Over by the clock with no tick to see it yet: the end came between ticks,
  /// or a goal came down to what was already counted.
  bool get _due => _begun && !_finished && phase == TimingPhase.complete;

  /// Skip and back work on a solo tabata, running or paused, until it ends.
  bool get canSkip =>
      spec?.tabata == true &&
      !shared &&
      (running || _paused) &&
      phase != TimingPhase.complete;

  /// Different owner/spec: reset and start. Same: start or pause.
  void toggle(Object block, TimingSpec value, {int? target}) {
    if (!value.valid) return;
    _interrupted = false;
    if (!identical(owner, block) || spec != value || shared) {
      _halt();
      owner = block;
      spec = value;
      shared = false;
      _rewind();
    }
    // A new goal (a set was logged meanwhile) does not restart the run; one
    // it already passed ends it.
    if (_retarget(target)) return;
    if (running) {
      pause();
      return;
    }
    if (_finished || phase == TimingPhase.complete) _rewind();
    _start(resumed: _begun);
  }

  /// Sets [target]; true when that leaves the run over (see [_due]) and so
  /// completes it. A goal that came down under the count keeps the time and
  /// the count the run had reached.
  bool _retarget(int? goal) {
    final live = phase != TimingPhase.complete, counted = count;
    target = goal;
    if (!_due) return false;
    if (live) _lastCount = counted;
    _complete(at: live ? elapsed : null);
    return true;
  }

  /// 같이 하는 타이머의 자리 [at] 에 맞춘다. 이미 그 자리에서 돌고 있으면 아무
  /// 일도 하지 않으므로 몇 번을 불러도 된다 — 늦게 들어온 폰, 앱을 내렸다 올린
  /// 폰, 시계 보정이 크게 바뀐 폰이 모두 이 한 길로 제자리에 온다.
  ///
  /// [at] 은 음수일 수 있다: 아직 시작 전이거나, 교대에서 내 차례가 뒤다. 그동안은
  /// 준비 구간이고 남은 초가 3 보다 크게 보인다.
  ///
  /// A run that completed or was ended stays over: following it again does
  /// nothing until [toggle], [reset], [clear] or [restart].
  void follow(Object block, TimingSpec value, Duration at, {int? target}) {
    if (!value.valid) return;
    final same = shared && identical(owner, block) && spec == value;
    if (same && _finished) return;
    if (same && _retarget(target)) return;
    this.target = target;
    // 0.3초 안쪽의 차이는 고치지 않는다. 고칠 때마다 소리가 끊긴다.
    if (same && running && (elapsed - at).inMilliseconds.abs() < 300) return;
    _interrupted = false;
    _halt();
    owner = block;
    spec = value;
    shared = true;
    // Put back in place (late, resumed, rejoined): still the same run.
    if (!same) _rewind();
    _elapsed = at;
    _start();
  }

  void _rewind() {
    _runId++;
    _elapsed = Duration.zero;
    _begun = false;
    _finished = false;
    _endedEarly = false;
    _countAtEnd = null;
  }

  DateTime? _wallMark;
  Duration _monoMark = Duration.zero;

  void _markClocks() {
    _wallMark = _wallNow?.call();
    _monoMark = _time;
  }

  /// The monotonic clock stops while the device sleeps; the wall clock does
  /// not. A gap of 1 s..1 h is added to the run (cues it skipped stay silent).
  /// A shorter one is kept to add up with the next: short sleeps between
  /// ticks are not dropped one by one. A shared timer is put back in place by
  /// [follow] instead.
  void _correctClock() {
    final wall = _wallNow?.call(), mark = _wallMark;
    if (wall != null && mark != null && !shared) {
      final gap = wall.difference(mark) - (_time - _monoMark);
      if (gap >= Duration.zero && gap < const Duration(seconds: 1)) return;
      if (gap >= const Duration(seconds: 1) && gap < const Duration(hours: 1)) {
        _elapsed += gap;
      }
    }
    _markClocks();
  }

  void _start({bool resumed = false}) {
    assert(!running);
    soundFailed = false;
    _voiceFreeAt = 0;
    _started = _time;
    _markClocks();
    running = true;
    _begun = true;
    _lastPhase = phase;
    _lastRound = round;
    _lastRemaining = remaining;
    _lastBeat = beat;
    _lastCount = count;
    final cue = phase == TimingPhase.ready
        // 같이 할 때는 준비가 3초보다 길 수 있다. 그동안은 조용하다.
        ? (remaining <= 3 ? 'ready' : null)
        // 같이 하는 타이머에는 쉬는 도중에 들어올 수도 있다. 그때는 시작 신호가 아니다.
        : spec!.tabata && (phase == TimingPhase.work || !shared)
        ? 'work'
        : null;
    _sound(cue: cue);
    if (resumed) {
      _buzz(TimerHaptic.medium);
    } else if (cue != null) {
      _buzz(_cueHaptic(cue));
    }
    // 박 중간에서 다시 시작했으면(멈췄다 켬, 같이 하기 재동기화) 그 박자의 숫자는
    // 읽을 때(반 박)가 아직 안 왔을 때만 읽는다. 지났으면 다음 박자부터.
    if (countAloud && _unread) _say(_lastBeat);
    // 100ms 마다 보면 구간이 바뀐 것을 최대 100ms 늦게 안다 — 그만큼 소리가
    // 밀린다. 50ms 로 보면 절반이고, 하는 일은 값 비교뿐이라 싸다.
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
    notifyListeners();
  }

  TimingPhase? _lastPhase;
  int? _lastRound, _lastRemaining;
  int _lastBeat = 0, _lastCount = 0;
  int _voiceGeneration = 0;

  /// 앞 말이 끝나는 때(지난 시간, 초). 이보다 이른 박자는 읽지 않는다.
  double _voiceFreeAt = 0;

  void _say(int n) {
    final bpm = spec?.bpm;
    if (bpm == null) return;
    final text = spokenCount(n, _language);
    final pace = countPace(text, _language, bpm);
    // 박자가 **시작한** 때로 잰다. 틱이 알아챈 때(0~50ms 늦다)로 재면 늦게
    // 알아챈 박자 뒤의 숫자가 운에 따라 빠진다.
    final start = elapsed.inMicroseconds / 1e6 - (_intoBeat ?? 0);
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

  static TimerHaptic _cueHaptic(String cue) => switch (cue) {
    'work' => TimerHaptic.heavy,
    'rest' => TimerHaptic.medium,
    'complete' => TimerHaptic.success,
    _ => TimerHaptic.tick,
  };

  void _buzz(TimerHaptic kind) {
    if (haptics) _haptic(kind);
  }

  void _cue(String cue) {
    _sound(cue: cue);
    _buzz(_cueHaptic(cue));
  }

  void tick() {
    if (!running) return;
    _correctClock();
    final next = phase;
    if (next == TimingPhase.complete) {
      _complete();
      return;
    }
    if (next != _lastPhase || round != _lastRound) {
      _cue(next == TimingPhase.work ? 'work' : 'rest');
      // 운동 구간이 끝나면 몇 라운드를 마쳤는지 말한다. 쉬는 동안이라 시작
      // 신호나 박자 세는 말과 겹치지 않는다. The last round of a plain tabata
      // ends in completion, not rest, so its number never runs into that cue.
      if (next == TimingPhase.rest && _lastPhase == TimingPhase.work) {
        final said = announceRound?.call(round);
        if (said != null) _speak(said);
      }
    } else if ((next == TimingPhase.ready || spec!.tabata) &&
        remaining <= 3 &&
        remaining != _lastRemaining) {
      // 구간마다 마지막 3초를 띠·띠·띠 하고 센다 — 타바타 앱들의 공통 신호다.
      // 화면을 안 보고도 다음 구간이 오는 것을 몸이 안다. 준비 3초도 같은 소리.
      _cue('ready');
    }
    final counted = beat;
    if (counted != _lastBeat) {
      _lastBeat = counted;
      if (countAloud && counted > 0) _say(counted);
    }
    final counts = count;
    if (next != _lastPhase ||
        remaining != _lastRemaining ||
        round != _lastRound ||
        counts != _lastCount) {
      _lastPhase = next;
      _lastRound = round;
      _lastRemaining = remaining;
      _lastCount = counts;
      notifyListeners();
    }
  }

  /// The clock ran out (or a skip reached the end): the run ends at [total],
  /// a metronome's count at its goal — or, when the goal came down under the
  /// count, at [at] with the beats it had counted. Speech already queued is
  /// left to finish — the last count is read after the run is over.
  void _complete({Duration? at}) {
    final goal = spec!.tabata ? null : target;
    _countAtEnd = goal == null ? _lastCount : math.max(goal, _lastCount);
    _elapsed = at ?? total!;
    running = false;
    _finished = true;
    _ticker?.cancel();
    _cue('complete');
    notifyListeners();
    onComplete?.call();
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

  /// Stops the clock and the sound without telling anyone.
  void _halt() {
    if (!running) return;
    _elapsed = elapsed;
    running = false;
    _voiceGeneration++;
    _ticker?.cancel();
    _sound();
  }

  /// Prepares the speech engine and cue players (no sound), so the first run
  /// counts on time.
  Future<void> warmUp() async {
    try {
      await _audio.warmUp();
    } catch (_) {}
  }

  void pause() {
    if (!running) return;
    if (_due) {
      _complete();
      return;
    }
    _halt();
    _buzz(TimerHaptic.medium);
    notifyListeners();
  }

  void resume() {
    if (running || spec == null || _finished) return;
    if (phase == TimingPhase.complete) return;
    _interrupted = false;
    _start(resumed: true);
  }

  void reset() {
    _halt();
    _rewind();
    shared = false;
    _interrupted = false;
    notifyListeners();
  }

  void clear() {
    reset();
    owner = null;
    spec = null;
    target = null;
  }

  /// From the top, running. Not while shared — the start time is agreed.
  void restart() {
    if (spec == null || shared) return;
    _halt();
    _rewind();
    _interrupted = false;
    _start();
  }

  /// Stop here and keep the result: paused with [endedEarly], then
  /// [onComplete] once, without the 'complete' cue. Under 10 s there is
  /// nothing worth keeping, so it resets and [onComplete] is not called.
  void end() {
    if (spec == null || _finished) return;
    _interrupted = false;
    if (_due) {
      _complete();
      return;
    }
    if (elapsed < const Duration(seconds: 10)) {
      reset();
      return;
    }
    _halt();
    _countAtEnd = count;
    _finished = true;
    _endedEarly = true;
    notifyListeners();
    onComplete?.call();
  }

  /// To the end of this interval: ready → work, work → rest (the last work →
  /// complete), rest → next work.
  void skip() {
    if (!canSkip) return;
    final end = _segment?.$2;
    if (end == null) return;
    _buzz(TimerHaptic.tick);
    _seek(Duration(microseconds: end));
  }

  /// To the start of this interval once 2 s in, else of the one before.
  void back() {
    if (!canSkip) return;
    final s = spec!;
    final (start, _) = _segment!;
    final us = elapsed.inMicroseconds;
    final int to;
    if (us - start > 2000000 || start == 0) {
      to = start;
    } else if (start == _readyUs) {
      to = 0;
    } else {
      // The interval before starts one work or one rest earlier.
      final intoCycle = (start - _readyUs) % ((s.work + s.rest) * 1000000);
      to = start - (intoCycle == 0 ? s.rest : s.work) * 1000000;
    }
    _buzz(TimerHaptic.tick);
    _seek(Duration(microseconds: to));
  }

  /// 지금 쉬는 중이면 남은 휴식을 건너뛰고 다음 세트로 간다. 휴식은 짧아지기만
  /// 한다. 같이 하는 중에는 건너뛰지 않는다 — 나만 앞서 가면 같이 하는 것이 아니다.
  void skipRest() {
    if (!running || shared || phase != TimingPhase.rest) return;
    _seek(Duration(microseconds: _segment!.$2!));
  }

  /// Moves the clock. Queued words are dropped and the next beat is read
  /// afresh; the click loop is re-placed on the new beat grid every time,
  /// even when the interval does not change.
  void _seek(Duration to) {
    _elapsed = to;
    _started = _time;
    _markClocks();
    _voiceGeneration++;
    _voiceFreeAt = 0;
    // The tick below reads the beat landed in, as a natural entry would.
    _lastBeat = _unread ? beat - 1 : beat;
    _sound();
    if (running) {
      tick();
    } else {
      if (phase == TimingPhase.complete) {
        _complete();
        return;
      }
      notifyListeners();
    }
  }

  void _onInterrupted() {
    if (!running) return;
    pause();
    _interrupted = true;
  }

  void _onResumed() {
    if (_interrupted && !running && phase != TimingPhase.complete) resume();
    _interrupted = false;
  }

  /// 제어 센터·알림 센터·Face ID·화면 꺼짐·홈 버튼에는 멈추지 않는다 — 소리는
  /// 백그라운드에서도 난다. Only a detached engine pauses. Coming back puts the
  /// clock right (sleep gap) and catches up.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) pause();
    if (state == AppLifecycleState.resumed) tick();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    _audio.onInterrupted = null;
    _audio.onResumed = null;
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
    required this.onCancel,
    this.waiting = false,
    this.busy = false,
    this.live = false,
    this.left = false,
    this.alternate = false,
    this.partnerLeft,
    this.mine = const [],
    this.theirs = const [],
    this.more = const [],
    this.onRetry,
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

  final void Function(bool alternate) onPropose;
  final VoidCallback onCancel;

  /// Set while the last together action about this card did not go through
  /// ([PartnerSync.timerError]): the card shows one line, and a tap calls
  /// this — the same action again, or only clearing the line.
  final VoidCallback? onRetry;
}
