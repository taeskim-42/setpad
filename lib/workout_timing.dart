import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'count_voice_lengths.dart';
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
    if (tabata)
      l.timerSummaryTabata(work, rest, rounds, timerClock(shownSeconds)),
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

  /// The workout's length on screen (card, sheet, strip, summary): without
  /// the 3 s ready, so every place shows the same total.
  int get shownSeconds => duration - 3;

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
///
/// 화면에 쓰는 말이다. 소리는 언어와 상관없이 영어 녹음이다([countVoice]).
String spokenCount(int n, String languageCode) {
  if (languageCode != 'ko' || n < 1 || n > 999) return '$n';
  const ones = ['', '하나', '둘', '셋', '넷', '다섯', '여섯', '일곱', '여덟', '아홉'];
  const tens = ['', '열', '스물', '서른', '마흔', '쉰', '예순', '일흔', '여든', '아흔'];
  const sino = ['', '백', '이백', '삼백', '사백', '오백', '육백', '칠백', '팔백', '구백'];
  return '${sino[n ~/ 100]}${tens[n % 100 ~/ 10]}${ones[n % 10]}';
}

/// 소리는 녹음이다 — 시스템 음성(TTS)은 쓰지 않는다. 기계가 읽는 말로 들렸다.
/// 앱 언어와 상관없이 영어다 — Tempo 와 같다(사용자 결정 2026-10-17). [sex]
/// 는 'm'·'w'(NotesStore.voice).
///
/// 세는 말 "One".."One hundred": tool/make_count_voices.py 가 만든다. 101 부터는
/// 녹음이 없어 읽지 않고 클릭만 간다(Tempo 와 같다).
const maxSpokenCount = 100;
String countVoice(String sex, int n) => 'assets/voice/count/en/$sex/$n.m4a';

/// Slack the plan keeps for the platforms' polling (20 ms), Android's first
/// try 5 ms late and timer jitter: off the quarter-beat wait while counting
/// every beat, and between a word's end and the next count once spread out.
const countGapMs = 40;

/// The counts said in a run counting to [last] at [bpm] in voice [sex].
///
/// The platforms (TimingBridge playVoice: iOS, Android, web) start a count
/// half a beat after its click, or as the word before ends (they look every
/// 20 ms), and drop it when that word still sounds a quarter beat after its
/// moment. A word ends its file's length after it starts: Android takes the
/// length with the encoder's priming ([countVoiceMs]), iOS and web the
/// shorter audible one, so the plan takes the longer.
///
/// Every beat while each count starts within that wait (less [countGapMs]).
/// Just before a word would not, counting widens to every 2nd, then 5th, then
/// 10th count, never back, and a widened count is said only when the word
/// before ended [countGapMs] before its moment. So a long number at a fast
/// tempo never drops the next one at random: 80 bpm in the man's voice is
/// One … Sixteen, Eighteen, Twenty …; 60 bpm counts every beat to Forty-six.
/// "One" is always said: it marks the start.
Set<int> countsSaid(String sex, int bpm, int last) {
  final top = math.min(math.max(last, 1), maxSpokenCount);
  final period = 60000 / bpm, half = math.min(period / 2, 1000);
  final ms = countVoiceMs[sex] ?? countVoiceMs['m']!;
  final wait = period / 4 - countGapMs;
  double at(int n) => (n - 1) * period + half;
  bool reaches(double end, int n, int s) =>
      s == 1 ? end <= at(n) + wait : end + countGapMs <= at(n);
  final said = <int>{};
  var s = 1;
  var end = double.negativeInfinity;
  for (var n = 1; n <= top; n++) {
    if (n % s != 0 || !reaches(end, n, s)) continue;
    final start = end <= at(n)
        ? at(n)
        : at(n) + ((end - at(n)) / 20).ceil() * 20;
    final mine = start + ms[n - 1];
    if (n + s <= top && !reaches(mine, n + s, s)) {
      // This word would hold up the next count too long: widen now. Off the
      // wider grid it goes unsaid, except "One".
      final from = s;
      s = const [2, 5, 10].firstWhere(
        (w) =>
            w > from &&
            (n % w != 0 || n + w > top || mine + countGapMs <= at(n + w)),
        orElse: () => 10,
      );
      if (n % s != 0 && n != 1) continue;
    }
    end = mine;
    said.add(n);
  }
  return said;
}

/// 구간 음성: Tempo 의 녹음(healthopia tool/make_voices.py) — start "Go!",
/// rest "Rest!", round_1..[maxVoicedRound] "Round n, go!", last_round, done,
/// ten_left.
const maxVoicedRound = 30;
String phraseVoice(String sex, String key) => 'assets/voice/en/$sex/$key.m4a';

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

/// Whole run length: tabata [TimingSpec.duration]; a metronome with a
/// [target] ends just after the target count is read (half a beat, at most a
/// second, plus 50 ms) and before the next click. Otherwise endless (null).
Duration? runLength(TimingSpec s, int? target) {
  if (s.tabata) return Duration(seconds: s.duration);
  final bpm = s.bpm;
  if (target == null || target < 1 || bpm == null) return null;
  final p = 60 / bpm;
  return Duration(
    microseconds: ((3 + (target - 1) * p + math.min(p / 2, 1.0) + 0.05) * 1e6)
        .round(),
  );
}

/// What is said as [next] begins in round [n] (Tempo's _phaseVoice): the
/// round at a tabata's work ("Round 3, go!", the last of several "Last
/// round"), "Go!" at a metronome's, "Rest!", and "Workout complete" at the
/// end. Null when nothing is: the ready, and a work start while counting
/// aloud with a tempo — the first count ("One", always said) marks it, as in
/// Tempo's metronome.
String? phraseKey(
  TimingSpec s,
  TimingPhase next,
  int n, {
  required bool countAloud,
}) => switch (next) {
  TimingPhase.ready => null,
  TimingPhase.rest => 'rest',
  TimingPhase.complete => 'done',
  _ when countAloud && s.bpm != null => null,
  _ when !s.tabata || s.rounds == 1 => 'start',
  _ when n == s.rounds => 'last_round',
  _ when n <= maxVoicedRound => 'round_$n',
  _ => 'start',
};

/// A moment a run's interval changes: [at] is its time from the run's start
/// (ready included), [phase] the interval it begins (work, rest, complete),
/// [round] the tabata round (1 for a metronome), [voice] the recorded phrase
/// said there (a Flutter asset), null when none is.
typedef Boundary = ({
  Duration at,
  TimingPhase phase,
  int round,
  String? voice,
});

/// The boundaries of a run of [s] that come after [from] by at least
/// [lead], earliest first, at most [limit]. A boundary sooner than [lead] is
/// left to the running engine. Voices follow [phraseKey] in voice [sex];
/// none when [voiceCues] is off.
List<Boundary> runBoundaries(
  TimingSpec s, {
  int? target,
  Duration from = Duration.zero,
  String sex = 'm',
  bool voiceCues = true,
  bool countAloud = false,
  Duration lead = const Duration(seconds: 1),
  int? limit,
}) {
  final out = <Boundary>[];
  void add(int us, TimingPhase phase, int round) {
    final at = Duration(microseconds: us);
    if (at - from < lead) return;
    final key = phraseKey(s, phase, round, countAloud: countAloud);
    out.add((
      at: at,
      phase: phase,
      round: round,
      voice: voiceCues && key != null ? phraseVoice(sex, key) : null,
    ));
  }

  final end = runLength(s, target);
  if (s.tabata) {
    final cycle = (s.work + s.rest) * 1000000, work = s.work * 1000000;
    for (var r = 1; r <= s.rounds; r++) {
      final start = _readyUs + (r - 1) * cycle;
      add(start, TimingPhase.work, r);
      if (r < s.rounds || s.tail) add(start + work, TimingPhase.rest, r);
    }
  } else {
    add(_readyUs, TimingPhase.work, 1);
  }
  if (end != null) {
    add(end.inMicroseconds, TimingPhase.complete, s.tabata ? s.rounds : 1);
  }
  return limit == null || out.length <= limit ? out : out.sublist(0, limit);
}

/// The lock-screen title of [b] in a run of [s]: "Round 3", "Last round",
/// "Go" (a metronome or a one-round tabata), "Rest", "Workout complete".
String boundaryTitle(L l, TimingSpec s, Boundary b) => switch (b.phase) {
  TimingPhase.rest => l.timerNoticeRest,
  TimingPhase.complete => l.timerNoticeDone,
  _ when !s.tabata || s.rounds == 1 => l.timerNoticeGo,
  _ when b.round == s.rounds => l.timerNoticeLastRound,
  _ => l.timerNoticeRound(b.round),
};

/// Puts a run's upcoming boundaries on the lock screen while the app is away
/// (iOS: lib/boundary_notify.dart). The engine stays quiet on the phrases a
/// schedule covers.
abstract class BoundaryNotifier {
  /// Gets the sounds of [voices] ready (once per file), when a run starts:
  /// nothing heavy happens on the way to the background.
  Future<void> prepare(Iterable<String> voices);

  /// Schedules [boundaries] of a run of [spec], the run being at [from] at
  /// the wall-clock time [now]. How many of them, from the first, will sound
  /// (allowed, with sound, under the system's limit); 0: none.
  Future<int> schedule(
    TimingSpec spec,
    List<Boundary> boundaries, {
    required Duration from,
    required DateTime now,
  });

  /// Drops every boundary notification still pending.
  Future<void> cancel();
}

/// At most this many boundary notifications are pending, the earliest
/// first. iOS keeps 64 pending local notifications per app (Apple staff,
/// developer forums thread 811171: "a limit of 64 for how many simultaneous
/// notification requests can be active/pending at one time per app"); the
/// set rest and the trainer reports need the rest.
const maxBoundaryNotices = 40;

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

  /// The recorded voice, 'm' or 'w' (NotesStore.voice): counts and phrases.
  String voice = 'm';

  /// Say the interval starts and the end (NotesStore.voiceCues): "Round 3,
  /// go!", "Rest!", "Workout complete, great job!".
  bool voiceCues = true;

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

  /// [runLength] of this run.
  Duration? get total {
    final s = spec;
    return s == null ? null : runLength(s, target);
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
    // Joining a shared run at work, or going on after a skip made while
    // paused; said once, so a plain resume or a re-sync says nothing.
    if (cue == 'work') _phrase(phase);
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
    if (!resumed) _prepareNotices();
    _cover();
    notifyListeners();
  }

  /// The sounds the run's notifications may use, made ready as it starts.
  void _prepareNotices() {
    final n = notifier, s = spec;
    if (n == null || s == null || !voiceCues) return;
    final voices = {
      for (final b in runBoundaries(
        s,
        target: target,
        sex: voice,
        countAloud: countAloud,
        lead: Duration.zero,
      ))
        ?b.voice,
    };
    n.prepare(voices).catchError((Object _) {});
  }

  TimingPhase? _lastPhase;
  int? _lastRound, _lastRemaining;
  int _lastBeat = 0, _lastCount = 0;
  int _voiceGeneration = 0;

  /// How far this run's phrases went: (run, round × 4 + phase). They only
  /// go forward, so putting a shared run back in place ([follow]), even back
  /// over a boundary, never says one twice. A seek starts afresh.
  (int, int)? _phrased;

  /// Beat [n]'s count, unless [countsSaid] leaves it out: up to the run's
  /// goal, or a tabata work's beats.
  void _say(int n) {
    final s = spec!, bpm = s.bpm, goal = target;
    if (n > maxSpokenCount) return;
    if (bpm != null) {
      final last = s.tabata
          ? (s.work * bpm / 60).ceil()
          : (goal == null || goal < 1 ? maxSpokenCount : goal);
      if (!countsSaid(voice, bpm, last).contains(n)) return;
    }
    _voice(countVoice(voice, n), onBeat: true);
  }

  /// [phraseKey] as [next] begins, once. Not when a scheduled notification
  /// says it ([_covered]): the app may still be awake in the background.
  void _phrase(TimingPhase next) {
    final n = round, step = n * 4 + next.index, last = _phrased;
    if (!voiceCues || (last?.$1 == _runId && last!.$2 >= step)) return;
    _phrased = (_runId, step);
    final at = next == TimingPhase.complete ? total : null;
    final boundary = at?.inMicroseconds ?? _segment?.$1;
    if (_covered.contains(boundary)) return;
    final key = phraseKey(spec!, next, n, countAloud: countAloud);
    if (key != null) _voice(phraseVoice(voice, key));
  }

  /// Boundary notifications ([BoundaryNotifier]); null: none (web, tests).
  BoundaryNotifier? notifier;

  /// The app is in the background (hidden or paused).
  bool _away = false;

  /// Boundary times (µs from the start) whose phrase a scheduled
  /// notification says.
  Set<int> _covered = const {};

  /// Bumped by every schedule and cancel: a schedule that returns after a
  /// newer one, or after the cancel, covers nothing.
  int _coverGen = 0;
  bool _scheduled = false;

  /// While away and running: the boundaries ahead go to [notifier].
  void _cover() {
    final n = notifier, s = spec;
    if (n == null || s == null || !_away || !running) return;
    final from = elapsed;
    final list = runBoundaries(
      s,
      target: target,
      from: from,
      sex: voice,
      voiceCues: voiceCues,
      countAloud: countAloud,
      limit: maxBoundaryNotices,
    );
    if (list.isEmpty) return;
    final gen = ++_coverGen;
    _scheduled = true;
    final now = (_wallNow ?? DateTime.now)();
    n.schedule(s, list, from: from, now: now).then((sounds) {
      if (gen == _coverGen) {
        _covered = {for (final b in list.take(sounds)) b.at.inMicroseconds};
      }
    }, onError: (Object _) {});
  }

  /// Drops what [_cover] scheduled; the engine says its phrases again.
  void _uncover() {
    _coverGen++;
    _covered = const {};
    if (!_scheduled) return;
    _scheduled = false;
    notifier?.cancel().catchError((Object _) {});
  }

  /// 세대가 바뀌면(멈춤·되감기) 줄 서 있던 말은 버린다.
  void _voice(String asset, {bool onBeat = false}) {
    final generation = _voiceGeneration;
    _commands = _commands.then((_) async {
      if (_disposed || generation != _voiceGeneration) return;
      // 못 내도 박자는 계속 간다. 소리는 덤이지 타이머의 전제가 아니다.
      try {
        await _audio.playVoice(asset, onBeat: onBeat);
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

  /// [quiet]: back in front after the background — the boundaries passed
  /// meanwhile were the notifications' (or went unheard); they are not
  /// played late. The run lands where the clock says, silently.
  void tick({bool quiet = false}) {
    if (!running) return;
    _correctClock();
    final next = phase;
    if (next == TimingPhase.complete) {
      _complete(quiet: quiet);
      return;
    }
    if (next != _lastPhase || round != _lastRound) {
      if (quiet) {
        _phrased = (_runId, round * 4 + next.index);
      } else {
        _cue(next == TimingPhase.work ? 'work' : 'rest');
        _phrase(next);
      }
    } else if (!quiet &&
        (next == TimingPhase.ready || spec!.tabata) &&
        remaining <= 3 &&
        remaining != _lastRemaining) {
      // 구간마다 마지막 3초를 띠·띠·띠 하고 센다 — 타바타 앱들의 공통 신호다.
      // 화면을 안 보고도 다음 구간이 오는 것을 몸이 안다. 준비 3초도 같은 소리.
      _cue('ready');
    }
    final counted = beat;
    if (counted != _lastBeat) {
      _lastBeat = counted;
      if (countAloud && counted > 0 && !quiet) _say(counted);
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
  /// [quiet]: it ended while the app was away (see [tick]); no end sound.
  void _complete({Duration? at, bool quiet = false}) {
    final goal = spec!.tabata ? null : target;
    _countAtEnd = goal == null ? _lastCount : math.max(goal, _lastCount);
    _elapsed = at ?? total!;
    running = false;
    _finished = true;
    _ticker?.cancel();
    if (quiet) {
      _sound();
    } else {
      _cue('complete');
      _phrase(TimingPhase.complete);
    }
    if (_away && at == null) {
      // Its own notification is due now: cancelling could beat it. Every
      // other one scheduled came before the end. They stay [_scheduled]:
      // coming back clears them off the lock screen, as after a suspension.
      _coverGen++;
      _covered = const {};
    } else {
      _uncover();
    }
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
    _uncover();
    _sound();
  }

  /// Prepares the cue players and the first recorded words (no sound), so
  /// the first run counts on time.
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
    // The tick below reads the beat and says the phrase of the interval
    // landed in, as a natural entry would.
    _phrased = null;
    _lastBeat = _unread ? beat - 1 : beat;
    _sound();
    if (running) {
      // The boundaries moved with the clock.
      _uncover();
      _cover();
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

  /// 제어 센터·알림 센터·Face ID·화면 꺼짐·홈 버튼에는 멈추지 않는다. Only a
  /// detached engine pauses. Going away (hidden, or paused — iOS sends both
  /// when locking or switching apps, first one wins) hands the boundaries
  /// ahead to [notifier]: the app may be suspended in a silent stretch.
  /// Coming back drops them all before anything sounds, puts the clock right
  /// (sleep gap) and lands there quietly.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        if (_away) return;
        _away = true;
        _cover();
      case AppLifecycleState.resumed:
        final was = _away;
        _away = false;
        _uncover();
        tick(quiet: was);
        // The click loop may have stopped meanwhile (a rest in the background
        // let the session go, or the system refused to start it there): put
        // back on the beat. Natively a no-op when it still runs.
        if (was && running) _sound();
      case AppLifecycleState.detached:
        pause();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    _uncover();
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
