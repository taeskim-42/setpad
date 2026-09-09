import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'l10n/generated/app_localizations.dart';
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

  static const minBpm = 10, maxBpm = 120;
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
          interval, (m) => '$work${m[2]}$rest${m[4]}');
      } else if (work != 20 || rest != 10) {
        // 기본값은 안 적는다. 안 바꾼 것까지 제목에 붙으면 지저분해진다.
        out = '${out.trimRight()} $work/$rest';
      }
      final reps = RegExp(r'([x×]\s*)(\d+)|(\d+)(\s*(?:라운드|rounds?|ラウンド))',
          caseSensitive: false);
      if (reps.hasMatch(out)) {
        out = out.replaceFirstMapped(reps, (m) =>
            m[1] != null ? '${m[1]}$rounds' : '$rounds${m[4]}');
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
  Duration _elapsed = Duration.zero, _started = Duration.zero;
  Future<void> _commands = Future.value();
  Duration get elapsed =>
      _elapsed + (running ? _time - _started : Duration.zero);
  TimingPhase get phase {
    if (spec?.tabata != true) return TimingPhase.work;
    final seconds = elapsed.inMilliseconds / 1000;
    if (seconds < 3) return TimingPhase.ready;
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
    final seconds = elapsed.inMilliseconds / 1000;
    final into = spec!.tabata
        ? (seconds - 3) % (spec!.work + spec!.rest)
        : seconds;
    return (into * bpm / 60).floor() + 1;
  }

  int get remaining {
    if (spec?.tabata != true) return elapsed.inSeconds;
    final seconds = elapsed.inMilliseconds / 1000;
    if (phase == TimingPhase.ready) return (3 - seconds).ceil();
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
    _sound(
      cue: spec!.tabata
          ? (phase == TimingPhase.ready ? 'ready' : 'work')
          : null,
    );
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => tick());
    notifyListeners();
  }

  TimingPhase? _lastPhase;
  int? _lastRound, _lastRemaining;
  void tick() {
    if (!running) return;
    final next = phase;
    if (next == TimingPhase.complete) {
      _elapsed = Duration(seconds: spec!.duration);
      running = false;
      _ticker?.cancel();
      _sound(cue: 'complete');
      notifyListeners();
      return;
    }
    if (next != _lastPhase || round != _lastRound) {
      _sound(cue: next == TimingPhase.work ? 'work' : 'rest');
    } else if (next == TimingPhase.ready && remaining != _lastRemaining) {
      _sound(cue: 'ready');
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
      final clock =
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
      final beat = selected ? timer.beat : 0;
      final counted = spokenCount(beat, l.localeName.split('_').first);
      // 돌아가는 중에 길이를 바꾸면 남은 시간이 튄다. 멈춘 뒤에 바꾸게 한다.
      final editable = onChanged != null && !running;
      void change(TimingSpec next) {
        if (next.valid && next != spec) onChanged!(next);
      }
      final phaseLabel = switch (phase) {
        TimingPhase.ready => l.timingReady,
        TimingPhase.work => l.timingWork,
        TimingPhase.rest => l.timingRest,
        TimingPhase.complete => l.timingComplete,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (spec.bpm != null)
                  _Stepper(
                    label: l.timingBpm(spec.bpm!),
                    onLess: editable && spec.bpm! > TimingSpec.minBpm
                        ? () => change(spec.copyWith(
                            bpm: (spec.bpm! - 5).clamp(
                                TimingSpec.minBpm, TimingSpec.maxBpm)))
                        : null,
                    onMore: editable && spec.bpm! < TimingSpec.maxBpm
                        ? () => change(spec.copyWith(
                            bpm: (spec.bpm! + 5).clamp(
                                TimingSpec.minBpm, TimingSpec.maxBpm)))
                        : null,
                  ),
                if (spec.tabata) ...[
                  _Stepper(
                    label: l.timingWorkSeconds(spec.work),
                    onLess: editable && spec.work > TimingSpec.minSeconds
                        ? () => change(spec.copyWith(work: spec.work - 5 < 5
                            ? TimingSpec.minSeconds
                            : spec.work - 5))
                        : null,
                    onMore: editable && spec.work < TimingSpec.maxSeconds
                        ? () => change(spec.copyWith(work: spec.work + 5))
                        : null,
                  ),
                  _Stepper(
                    label: l.timingRestSeconds(spec.rest),
                    onLess: editable && spec.rest > TimingSpec.minSeconds
                        ? () => change(spec.copyWith(rest: spec.rest - 5 < 5
                            ? TimingSpec.minSeconds
                            : spec.rest - 5))
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
              ],
            ),
            if (!spec.valid)
              Text(
                l.timingInvalid,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spec.tabata
                          ? '$phaseLabel  $clock  ·  ${l.timingRound(selected ? timer.round : 1, spec.rounds)}'
                                '${beat > 0 ? '  ·  ${l.timingBeat(counted)}' : ''}'
                          : (beat > 0 ? l.timingBeat(counted) : l.timingMetronome),
                      style: const TextStyle(
                        fontSize: 15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    onPressed: () {
                      if (!running) onStart();
                      timer.toggle(owner, spec);
                    },
                    child: Text(running ? l.timingPause : l.timingStart),
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
            if (selected && timer.soundFailed)
              Text(
                l.timingSoundFailed,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
          ],
        ),
      );
    },
  );
}


/// 값 하나와 −/+ 두 개. 키패드의 무게 조절과 같은 결로 둔다.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, this.onLess, this.onMore});
  final String label;
  final VoidCallback? onLess, onMore;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    Widget key(IconData icon, VoidCallback? tap, String semantics) =>
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(30, 28),
          onPressed: tap,
          child: Icon(icon, size: 15, semanticLabel: semantics),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: muted)),
        key(CupertinoIcons.minus, onLess, '-'),
        key(CupertinoIcons.plus, onMore, '+'),
      ],
    );
  }
}
