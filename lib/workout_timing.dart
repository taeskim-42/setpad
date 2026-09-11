import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
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
    final seconds = elapsed.inMilliseconds / 1000 - 3;
    final into = spec!.tabata ? seconds % (spec!.work + spec!.rest) : seconds;
    return (into * bpm / 60).floor() + 1;
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

  void toggle(Object block, TimingSpec value) {
    if (!value.valid) return;
    if (!identical(owner, block) || spec != value) {
      pause();
      owner = block;
      spec = value;
      _elapsed = Duration.zero;
    }
    if (running) {
      pause();
      return;
    }
    if (phase == TimingPhase.complete) _elapsed = Duration.zero;
    soundFailed = false;
    _started = _time;
    running = true;
    _lastPhase = phase;
    _lastRound = round;
    _lastRemaining = remaining;
    _lastBeat = beat;
    _sound(
      cue: phase == TimingPhase.ready
          ? 'ready'
          : spec!.tabata
          ? 'work'
          : null,
    );
    if (countAloud && _lastBeat > 0) _say(_lastBeat);
    // 100ms 마다 보면 구간이 바뀐 것을 최대 100ms 늦게 안다 — 그만큼 소리가
    // 밀린다. 50ms 로 보면 절반이고, 하는 일은 값 비교뿐이라 싸다.
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
    notifyListeners();
  }

  TimingPhase? _lastPhase;
  int? _lastRound, _lastRemaining;
  int _lastBeat = 0;
  int _voiceGeneration = 0;

  void _say(int n) => _speak(spokenCount(n, voiceLocale));

  /// 세대가 바뀌면(멈춤·되감기) 줄 서 있던 말은 버린다.
  void _speak(String text) {
    final generation = _voiceGeneration;
    _commands = _commands.then((_) async {
      if (_disposed || generation != _voiceGeneration) return;
      // 읽다 실패해도 박자는 계속 간다. 소리는 덤이지 타이머의 전제가 아니다.
      try {
        await _audio.speak(text, voiceLocale);
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
        await _audio.configure(active: active, bpm: bpm, cue: cue);
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

class WorkoutTimingControls extends StatelessWidget {
  const WorkoutTimingControls({
    super.key,
    required this.owner,
    required this.spec,
    required this.timer,
    required this.onStart,
    this.onChanged,
  });
  final Object owner;
  final TimingSpec spec;
  final WorkoutTimer timer;
  final VoidCallback onStart;

  /// 버튼으로 고친 설정. 받는 쪽이 운동 이름을 다시 적는다 — 제목이 설정이다.
  final ValueChanged<TimingSpec>? onChanged;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: timer,
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
      final editable = onChanged != null && !running;
      void change(TimingSpec next) {
        if (next.valid && next != spec) onChanged!(next);
      }

      int lessSeconds(int n) => n - 5 < 5 ? TimingSpec.minSeconds : n - 5;

      final phaseLabel = switch (phase) {
        TimingPhase.ready => l.timingReady,
        TimingPhase.work => l.timingWork,
        TimingPhase.rest => l.timingRest,
        TimingPhase.complete => l.timingComplete,
      };
      final status = spec.tabata
          ? '$phaseLabel · ${l.timingRound(round, spec.rounds)}'
                '${beat > 0 ? ' · ${l.timingBeat(counted)}' : ''}'
          : selected && phase == TimingPhase.ready
          ? phaseLabel
          // 박자는 큰 숫자로 이미 보인다. 옆에는 무엇인지만 적는다 —
          // "5 · 다섯" 처럼 같은 것을 두 번 쓰지 않는다.
          : l.timingMetronome;
      void toggle() {
        if (!running) onStart();
        timer.toggle(owner, spec);
      }

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
                      running ? l.timingPause : l.timingStart,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: selected ? timer.reset : null,
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
