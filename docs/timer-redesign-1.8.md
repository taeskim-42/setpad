# 타이머(타바타·박자) 재설계 — 1.8.0 (v2, 비평 반영)

작성 2026-10-17. 입력: scratchpad `understand/timing.md`(결함 지도), `understand/tempo-timer-spec.md`(Tempo 이식 명세), `understand/ui-ux-review.md`, `critics.md`(엔진·호환 / 접근성·국제화·범위 비평), 현재 화면 캡처(`understand/shots/*`).
표기: 🟩 확인한 사실 / 🟦 결정. **이 문서가 구현 레인(A 엔진 · L 문구 · N 네이티브 · S 실행 화면 · C 카드·시트·연결)의 계약이다.** 계약(§4 API, §5 채널, §15 키)을 바꿔야 하면 보고서에 적고 최소한으로 더하기만 한다.

## 0. 한 줄

기록 카드 안의 한 줄 타이머를 **카드(설정 요약·시작) + 전체 화면 실행 무대(Tempo 수위·히어로 숫자·큰 일시정지 바·길게 눌러 종료·잠금) + 요약(세트로 적기)** 로 바꾼다. 엔진의 뼈대(단조 시계, 오디오 계약, 같이 하기 startAt 하나, 심박 훅, 세는 말, 제목=설정)는 지키고 그 위를 다시 그린다.

## 1. 원칙

1. 3 m 밖·바닥의 폰에서 **색 + 구간 라벨 + 숫자 하나**로 "지금 뭘, 얼마나 더"가 보인다(색만으로 판단하지 않는다 — 마지막 라운드는 흰 테두리).
2. 화면·숫자 탭은 아무 일도 하지 않는다. 일시정지는 하단 큰 바, 종료는 길게 누르기(1초), 잠금은 길게 누르기(2초).
3. 제목이 곧 설정(옛 기록 호환). 같은 제목은 영원히 같은 spec 으로 읽힌다. 설정 UI 는 제목을 다시 쓸 뿐이다.
4. 타이머가 끝나면 **세트가 남는다**(라운드마다 횟수, 박자는 센 수). 지어내지 않는다 — 안 센 라운드는 `reps: null`(격자에 '–').
5. 실행 무대는 **항상 어둡다**(라이트 모드에서도). 카드·시트는 앱 팔레트(밝기 두 벌).
6. iOS 는 백그라운드·잠금·제어 센터에서 멈추지 않는다. Android 는 이번 판에서 화면 꺼짐·홈 버튼에 멈추지 않는 데까지(포그라운드 서비스는 1.8.1, §13).
7. 햅틱은 화면이 켜져 있을 때의 보조다. 잠금 중 신호는 소리다.
8. 같이 하기와 심박은 실행 무대 안에 산다.

## 2. 흐름

```
운동 카드(타이머 없음) ── ⋯ 설정 칩 줄의 [타이머] 칩 / 빈 입력 줄의 후보 막대 [타바타]·[박자] 칩 ──> 타이머 시트
운동 카드(타이머 있음, 대기): [미니 띠][요약 "운동 20초 · 휴식 10초 × 8 · 3:53"][▶ 시작]   (요약 탭 → 시트)
      같이 하기 세션 중:      [▶ 시작][같이 ▾]  — 혼자 시작은 늘 된다. 같이 ▾ = 같이 시작 / 교대로
[▶ 시작] ──(첫 타바타면 건강 권한·AlarmKit 권한을 여기서)──> 실행 무대(전체 화면)
실행 무대 [접기 ▾] ──> 타이머는 계속 돈다. 카드: [구간색 띠][남은 수 28pt][운동 · R3/8][∥][열기 ▸]
완료·조기 종료 ──> 같은 무대에서 요약 ──[세트로 적기]──> 카드로
요약을 [닫기] 하면 카드: "완료 · 8라운드 · 3:53 · [적기 ▸] [↺]"
다른 칸의 [▶ 시작] 을 누를 때 도는 타이머가 있으면 확인 시트 "도는 타이머를 멈추고 이것을 시작할까요?" [멈추고 시작][취소];
적지 않은 완료 타이머가 있으면 "적지 않은 N라운드가 있어요" [먼저 적기][버리고 시작][취소].
```

## 3. 설정(TimingSpec)·제목 해석

🟩 지금: `타바타|tabata|タバタ` + `N/N`(초) + `xN|N라운드`, `bpm` + 수(없으면 120), bpm 10~120, 운동·휴식 1~600, 라운드 1~99.

🟦 결정:
- **`parse` 의 bpm 기본값은 120 그대로**(옛 제목·옛 앱과 같이 하기). 새로 만드는 자리만 60 을 **수로 적는다**: 후보 칩 이름 `60bpm`, 시트 초기값 60, `applyTo` 는 늘 `${bpm}bpm` 을 쓴다. 상수 `TimingSpec.newBpm = 60`.
- **라운드 패턴 하나**: `TimingSpec.roundsPattern = r'(?<!\d\s*)[x×]\s*(\d+)|(\d+)\s*(?:라운드|rounds?|ラウンド)'`(대소문자 무시). `parse`·`applyTo`·`marks`·`parser.timerTokens` 가 이 하나를 쓴다. "3x10"·"3 x 10" 은 세트 표기라 라운드가 아니다. `applyTo` 가 라운드를 덧붙일 때 제목 끝이 숫자면 ` x6` 대신 ` 6라운드`가 아니라 `·x6`(앞에 ' ·' ) 로 붙여 다시 읽힐 것 — **수락 기준: 모든 테스트 제목에서 `parse(applyTo(n)) == spec` 이고 원 제목의 세트 표기(3x10)는 그대로.**
- **타바타 길이**: `int get duration`(초) = `3 + work*rounds + rest*(rounds-1)` (+`rest` if `tail`). 마지막 라운드의 휴식은 없다(완료). 
- **`tail`**: 생성자·`copyWith`·`==`·`hashCode` 에만 있다(`applyTo`/`parse`/JSON 에는 없다). `SharedTimer.personal` 은 `alternate ? spec.copyWith(rest: work + 2*rest, tail: true) : spec`. 교대의 뒤 사람 차례가 내 마지막 휴식 안에 들어가므로 옛 식을 유지한다. `overAt` 은 `personal.duration` 그대로라 저절로 맞는다. 🟦 옛 앱(243초)과 새 앱(233초)이 같은 세션이면 새 앱이 10초 먼저 끝난다 — 사용자 없음(2026-09-23)이라 받아들인다.
- **`removeFrom(name)`**: `record_query.statName` 의 본체(타이머 토큰과 타바타·bpm 낱말 제거)를 `TimingSpec.removeFrom` 으로 옮기고 `statName` 은 호출만(`bare.isEmpty ? title.trim() : bare` 는 statName 에 남김). `removeFrom` 은 남는 것이 없으면 `''`.
- **박자 목표(target)는 제목이 아니라 칸의 설정**: `setup.repsPerSet` 이 있으면 그것, 없고 `setup.totalReps` 가 있으면 `max(0, totalReps - block.completedReps)`(0 이면 목표 없음), 둘 다 없으면 목표 없음(끝없이 센다). 목표는 그 기록 안에서 산다(다음 날 같은 제목 칸은 시트에서 다시 — `earlierSetup` 은 바꾸지 않는다).
- `summary(L l, {int? target})`: 카드 한 줄. 타바타 `timerSummaryTabata(work, rest, rounds, total)`, 박자 `timingBpm` (+ ` · ${timerTargetChip}`), 둘 다면 " · " 로 잇는다.

## 4. 엔진 API (lib/workout_timing.dart, lib/run_link.dart) — 레인 A

```dart
enum TimingPhase { ready, work, rest, complete }
enum TimerHaptic { tick, medium, heavy, success } // selectionClick / mediumImpact / heavyImpact / heavyImpact×2(150ms)

class WorkoutTimer extends ChangeNotifier with WidgetsBindingObserver {
  WorkoutTimer({TimingAudio? audio, Duration Function()? now, DateTime Function()? wallNow,
                void Function(TimerHaptic)? haptic});
  Object? owner; TimingSpec? spec; int? target;          // target: 박자 목표(폰마다 제 것)
  bool running, shared, soundFailed;
  bool countAloud; bool haptics;                         // haptics 기본 true (NotesStore.hapticsOn)
  String voiceLocale;                                    // setter 가 zh-Hans→zh-CN, zh-Hant→zh-TW, zh→zh-CN
  String Function(int round)? announceRound;
  VoidCallback? onComplete;                              // 자연 완료·end() 때 한 번(같은 run 에서 두 번 없음)
  bool get endedEarly;                                   // end() 로 끝났다
  Duration get elapsed; TimingPhase get phase; int get round; int get remaining; // remaining: 구간 남은 초(ceil)
  int get beat;     // 소리용: running && work 일 때만
  int get count;    // 운동 구간에서 센 박자 수. 멈춰도 유지(elapsed 의 함수). 완료·종료 순간 값으로 굳는다(_countAtEnd)
  double get level; // 수위 0..1: ready 1-e/3s, tabata work/rest 구간 남은 비율(µs), 박자+target 1-count/target, 박자 목표 없음 1.0, complete 0, 
  Duration? get total;   // tabata: duration초, 박자+target: 3s + 끝 시각(아래), 그 밖 null
  Duration get phaseElapsed; // 지금 구간에 들어선 지(요약의 운동·휴식 합 계산·'다음' 줄용)
  bool get wantsHeart;   // 그대로(타바타 running)
  bool get canSkip;      // spec.tabata && !shared && (running || paused) && phase != complete
  void toggle(Object owner, TimingSpec spec, {int? target});   // 다른 owner/spec 이면 리셋 후 시작; 같은 것이면 시작/일시정지
  void follow(Object owner, TimingSpec spec, Duration at, {int? target});
  void pause(); void resume(); void reset(); void clear(); void restart(); void end();
  void skip(); void back(); void skipRest();
}
```
규칙:
- **박자 완료**: target 이 있으면 `intoWork >= (target-1)*p + min(p/2, 1.0) + 0.05`(p = 60/bpm) 에서 complete — 목표 번째 숫자를 읽기 시작한 뒤, 다음 클릭 전. 이때 complete 큐는 말을 끊지 않는다(§5). `count` 는 그 순간 target 으로 굳는다. **shared 일 때 target 완료**는 complete 로 표시하고 엔진은 멈추되, 편집기가 `onComplete` 에서 `leaveTimer(at, count)` 를 보낸다(C 레인). 완료(또는 end) 뒤 같은 owner·spec 의 `follow()` 는 아무 일도 하지 않는다(`toggle/reset/clear/restart` 전까지).
- **complete 판정·시간은 ms**(박자 끝 시각이 소수 초). `tick()` 의 완료 분기만 'complete' 큐·`HapticKind.success`·`onComplete` 를 낸다. `end()` 는 tick 의 완료 분기를 타지 않는다: `pause()` 상태로 굳히고 `endedEarly = true`, 'complete' 큐 없이 `onComplete`. 10초 미만의 end 는 `reset()` 하고 `onComplete` 를 부르지 않는다(이미 적은 세트는 그대로).
- **skip/back/skipRest**: `_elapsed` 를 옮긴 뒤 `_voiceGeneration++`, `_voiceFreeAt = 0`, `_lastBeat = beat` 다시 재고, **항상** `_sound()`(cue 없음, 지금 `_intoBeat` 로 클릭 재배치)를 보낸 뒤 `tick()`. skip: 구간 끝으로(ready→work 시작, work→rest 시작, rest→다음 work; 마지막 work 의 skip 은 완료). back: 구간 시작 2초 지났으면 구간 처음, 아니면 앞 구간 처음(ready 는 0). shared 면 무시(skipRest 포함).
- **notify**: phase/round/remaining 에 더해 `count` 가 바뀔 때도 notify(박마다 한 번). 수위는 엔진 notify 를 기다리지 않는다 — 무대가 자기 Ticker 로 `level` 을 읽는다(§6.2).
- **햅틱**(haptics && 엔진이 소리를 내는 같은 지점): 구간 시작 work=heavy, rest=medium, 준비·마지막 3초 띠=tick, 완료=success, pause/resume=medium, skip/back=tick. 주입 함수로(테스트에서 센다).
- **수명주기**: `didChangeAppLifecycleState` 는 `detached` 에서만 pause. `resumed` 에서는 벽시계 보정 후 `tick()`. **벽시계 보정**: 매 tick 에 (벽시계 차 − 단조 차) 가 1초 이상이고 1시간 미만이면 그만큼 `_elapsed` 에 더한다(기기 잠자기로 단조 시계가 멈춘 만큼; 놓친 큐는 다시 울리지 않는다). shared 는 `follow` 가 우선.
- **인터럽션**: `onInterrupted` = `if (running) { pause(); _interrupted = true; }`. `onResumed` = `if (_interrupted && !running && phase != complete) resume(); _interrupted = false`. toggle/follow/reset/clear/end/restart 는 `_interrupted = false`. `_start()` 는 `assert(!running)`.
- `RestRecovery.listen` 은 스트림 onError/onDone 에서 `_feed = null` 로 되돌려 다음 `listen()` 이 다시 붙는다.
- 엔진은 세트를 모른다. 기록은 편집기가 `RunLink` 콜백으로 한다.

```dart
// lib/run_link.dart — 편집기(C)가 채우고 실행 무대(S)가 읽는다
class RunLink extends ChangeNotifier {
  RunLink(this.timer);
  final WorkoutTimer timer;
  String title = '';                 // 운동 이름(무대 맨 위 작은 글)
  String? weightLabel;               // 설정 무게 "16kg" (있으면 무대·요약에)
  TogetherTiming? together;          // 같이 하는 중일 때만(편집기가 다시 계산해 넣는다)
  RestRecovery? recovery;            // 심박(없으면 null)
  bool heartShared = false;          // 같이 할 땐 회복으로 끊지 않는다
  final List<int?> roundReps = [];   // 이번 run 에 적은 라운드별 횟수(0 = 1라운드). null = 안 적음
  void Function(int round, int? reps)? onLogRound;   // 라운드 세트를 쓰거나 고친다(편집기가 roundSets 로 관리)
  void Function(int reps)? onLogCount;               // 박자: 세트 하나
  VoidCallback? onLeave, onRejoin;                    // 같이: 그만·다시 들어가기(편집기의 _leaveShared 등)
  VoidCallback? onLogged;                             // 요약에서 다 적었다(무대를 닫는다)
  bool logged = false;                                // 이번 run 을 세트로 적었다
  void changed() => notifyListeners();
}
```

## 5. 네이티브 채널 계약 — 레인 N (Dart 쪽은 A)

`MethodChannel('setpad/timing')`:
- Dart→네이티브: `configure{active,bpm,cue,phase}`(그대로), `speak{text,locale,rate}`(그대로), **`warmUp`**(새: TTS 엔진·큐 플레이어를 미리 만든다, 소리 없음, 몇 번 불러도 됨).
- 네이티브→Dart: `interrupted`(iOS 인터럽션 began 에서만), **`resumed`**(새: iOS 인터럽션 ended + shouldResume).
- `TimingAudio`: `void Function()? onResumed;`, `Future<void> warmUp() async {}`(기본 구현 있음 — 테스트 가짜가 안 써도 된다).

iOS (`TimingBridge.swift`, `Info.plist`):
- `UIBackgroundModes: [audio]`.
- `willResignActiveNotification` 관찰 삭제. `AVAudioSession.interruptionNotification`: began → stop + `interrupted`; ended 에 `.shouldResume` 이면 세션 재활성 + `resumed`.
- **keep-alive (지움, 2026-10-17)**: 처음엔 active 동안 무음 버퍼를 반복 재생해 앱을 깨워 두었다. 애플의 audio 모드 정의 ("The app plays audible content in the background")와 App Review 2.5.4 에 어긋나 지웠다. 오디오 세션은 소리를 내는 타이머가 도는 동안만 켜고, 소리 없는 구간의 신호는 앱이 화면 밖에 있을 때 로컬 알림으로 낸다(`lib/boundary_notify.dart`, `docs/ios-app-review-notes.md`).
- **complete 는 말을 끊지 않는다**: `configure(active:false, cue:'complete')` 는 클릭 루프만 멈추고 대기·진행 중 말을 남긴다. `cue == nil && !active`(일시정지·정지)만 말을 끊는다.
- `warmUp`: `AVSpeechSynthesizer` 첫 발화 지연을 줄이려고 큐 플레이어 4개 prepare + 빈 문자열 말하기는 하지 않는다(소리 없음 보장) — 플레이어만.
- 화면 켜 둠(`isIdleTimerDisabled = active`) 유지. `.playback + .mixWithOthers` 유지.

Android (`TimingBridge.kt`, `MainActivity.kt`):
- `MainActivity.onPause` 의 `timing?.interrupt()` 삭제(화면 꺼짐·홈 버튼에 멈추지 않는다). 오디오 포커스는 잡지 않는다(음악을 낮추지 않는다) — 통화 감지는 이번 판에 없다(체크리스트에 적는다).
- `warmUp` = `prepareSpeech()` + 큐 트랙 미리 만들기.
- complete 는 말을 끊지 않는다(iOS 와 같은 규칙).
- `FLAG_KEEP_SCREEN_ON` 유지.

웹(`web/timing_audio.js` — N, `lib/timing_audio_web.dart` — A): `setpadTiming.configure(active, bpm, cue, phase)` 가 phase 로 클릭 격자를 맞추고, `setpadTiming.speak(text, locale, rate)` 가 rate 를 쓴다.

`docs/timer-device-checklist.md`(N): 잠금 중 소리(iOS), 제어 센터·알림 센터·Face ID 뒤 계속, 전화 뒤 자동 재개(iOS), Android 화면 끄고 2분 뒤 자리(벽시계 보정)·소리, 블루투스 이어폰, 무음 스위치(playback 은 무시 — 의도), 설치 뒤 첫 실행 준비 3초 안에 "하나·둘", zh 기기 세는 말 언어, 잠금 중 진동 없음(의도), 심사 노트 문구("타이머 신호음·박자 세기를 잠금화면에서도 내기 위한 오디오 재생"), keep-alive 반려 시 상수 false.

## 6. 실행 무대 (`lib/run_page.dart`, `lib/stage_palette.dart`) — 레인 S

열기: `Navigator.push(CupertinoPageRoute(fullscreenDialog: true, builder: (_) => RunPage(link: link)))`. push 때 `SystemChrome.setPreferredOrientations([portraitUp])`, pop 때 `setPreferredOrientations([])`(복원). 루트에 `AnnotatedRegion<SystemUiOverlayStyle>(light, systemNavigationBarColor #141414)`.
닫기(접기): 좌상단 44pt `[접기 ▾]`(시맨틱 "접기, 타이머는 계속 돌아요") 와 Android 뒤로(`PopScope`). iOS 가장자리 스와이프는 fullscreenDialog 라 없다. 잠금 중엔 Android 뒤로가 nudge. 접어도 타이머는 돈다.

### 6.1 레이아웃(세로, SafeArea 안, Tempo `_RunBody` portrait)
```
Stack(expand)
 ├ Flood               // 창 전체, 상태바 띠는 비움(waterline 은 View.of(context) padding.top 기준)
 ├ EndPulse            // 타바타 구간 끝 3·2·1초 흰 플래시 alpha 0.18/250ms, 구간 ≥4초, reduce motion 이면 없음, 내용 아래
 ├ SafeArea(Column[
 │   Top:   [접기 ▾] [운동 이름 15pt, 1줄]                         … 
 │          [구간 라벨 title1 32pt, FittedBox 1줄] … [R 3/8 | 60 BPM 20pt]   (라벨 textScale 1.5 상한)
 │   Center(Expanded): 숫자 — 폭 90%, 글자 상한 높이 45%, FittedBox scaleDown, tabular, noScaling
 │          타바타+bpm 운동 중: 숫자 아래 박자 줄 title1 — ko `spokenCount`(스물일곱), 그 밖 `timerBeatLine`("Beat 27")
 │          박자+target: 숫자 아래 `timerTarget`("/ 30회") title3
 │   Info:  [다음 · 휴식 10초 | 경과 0:42] … [전체 남은 3:20 | 남은 약 0:30]  labelTnum 16, Wrap
 │          RoundBar 8pt(타바타; 자기 어두운 바탕 radius 8 padding 4; 지난 칸 흰색, 지금 칸 구간색, 남은 칸 surface2)
 │   Extra: 심박 "♥ 132 → 107"(타바타 휴식, 신선할 때만; heartShared 면 `timerHeartShared` 13pt)
 │          같이: "민수 님과 같이" / "민수 님은 3라운드에서 멈춤" / 교대 "상대 차례" 라벨은 Top 라벨 자리
 │   RestLog: 타바타 휴식 && 이번 라운드 미기록 → [−] 12 [+] [기록] (키 56pt, 숫자 44pt, 기본값: 이번 run 마지막 → 칸의 내 마지막 세트 → 10)
 │   Controls(§6.4)
 │ ])
 ├ LastRoundBorder     // 마지막 라운드 운동 구간: 6px 흰 테두리 (IgnorePointer)
 └ (잠금 nudge 는 Controls 안)
```
- `short = height < 700` 이면 간격 8/12. 모든 라벨 줄 textScaler 1.5 상한(높이와 무관), 숫자는 noScaling.

### 6.2 수위·색 (`stage_palette.dart`)
- bg `#141414`, text `#FFFFFF`, textSecondary `#B8B8B8`, outline `#6A6A6A`, surface2 `#2E2E2E`, fillPrep `#FFC24D`, fillWork `#FF4F51`, fillRest `#7CC8FF`, onFill `#141414`, 일시정지 채움 = textSecondary. (대비: onFill 대 세 채움 5.69/10.14/11.47 — 테스트로 단언)
- `waterline = round(H − (H − top) * level)`; 글자는 두 겹(빈 쪽 흰 잉크, 채움 쪽 onFill, 아래쪽 clipRect) — Tempo `_Faces/_FloodClip/_RenderFloodClip` 이식. 버튼은 자기 바탕색(흰 바/bg 원).
- **Flood 는 자기 Ticker(또는 100ms Timer) 로 `timer.level` 을 읽어 그린다**. 숫자·라벨 레이어만 `ListenableBuilder(timer)`. 수락: 숫자 레이어 build ≤ 초당 max(1, bpm/60)+2, Flood repaint ≤ 초당 12. reduce motion 이면 Flood 는 초당 1회.

### 6.3 숫자·라벨·시맨틱
- 타바타·준비: 남은 초 ceil, 60 미만 "27", 이상 "1:30", 완료 대기 "0". 박자: 준비 "3·2·1", 첫 박 전 `timerGo`("시작!"), 이후 `count`. 박마다 펄스 박스(테두리 3px radius 24, alpha 1→0 250ms, scale 1.04; reduce motion 은 scale 없음·테두리만; bpm > 180 펄스 없음).
- 라벨: `timingReady/timingWork/timingRest/timerLastRound/timingComplete`, 일시정지면 `timerPaused`, 교대 상대 차례면 `togetherTheirTurn`. 오른쪽: 타바타 `timerRoundShort`, 박자 `timingBpm`.
- 시맨틱: Top 라벨 liveRegion(구간 바뀔 때만), 숫자 container label(`timerRemainingA11y`/`timerCountA11y`/박자 줄 `timerBeatA11y`), 두 얼굴 ExcludeSemantics, 잠금·해제 때 `SemanticsService.announce`.

### 6.4 조작 (Tempo `_Controls`)
- 실행 중: `[« 56] [일시정지 바 88, 흰 바탕, 아이콘+timingPause 24pt] [» 56]` (« » 는 `canSkip`) / `[🔒 56] [길게 눌러 종료 56]`(shared: `timerHoldLeave`).
- 일시정지: `[«] [계속 바(timerResume)] [»]` / `[🔒(잠겼을 때만)] [처음부터(timerRestart)] [종료(timerEnd, 탭)]`. shared: 처음부터 없음, 종료 = 그만(`onLeave`). 그만둔 뒤: `[다시 들어가기(togetherRejoin)] [닫기]`.
- 잠금: 길게 2초(링, `AnimationBehavior.preserve`), 잠기면 조작 0.35 + IgnorePointer, 터치는 nudge(종료 버튼 라벨이 300ms 밝아져 `timerLockedHint`), 햅틱 없음. 화면리더는 두 번 탭(`timerLockHint`/`timerUnlockHint`).
- 길게 눌러 종료 1초(테두리 채움). 화면리더는 longPress.
- 좌우 스와이프(속도 ≥300) = » / « (`canSkip`). 숫자·바탕 탭은 아무 일도 없다.
- 긴 라벨(hold·둘째 줄·요약 버튼)은 FittedBox(scaleDown) 1줄, 44pt 미만으로 줄지 않는다.

### 6.5 요약(같은 무대, `timer.phase == complete || endedEarly`)
- 제목 `timerDone`("끝!") / `timerStopped`("여기까지 했어요"), 칩 "타바타 20·10 ×8" / "박자 60 BPM".
- 타바타: 히어로 `timerRoundsDone`(n) + 행 [운동 합][휴식 합][총(준비 제외)] (Wrap). 라운드 칩 줄(Wrap): 칩 = `timerRoundChip`("3R 12" / "3R –"); 탭 → 횟수 시트(−/+ 큰 숫자, 프리셋, `timerFillRest` "남은 라운드 모두 12회", 비우기). 같이 하기면 사람별 줄(나·상대·셋째…; 기존 `TogetherTiming.mine/theirs/more`).
- 박자: 히어로 `timerRepsDone`(count) 또는 `timerRepsOfTarget` + 행 [시간][박자].
- 심박 줄 `timerLastRest`(있을 때만).
- 버튼: **주 버튼** — 타바타 `timerLogSetsCount(n)`(아직 안 쓴 라운드 수; 다 썼으면 `timerClose`), 박자 `timerLogSets` → 콜백 후 `onLogged`(무대 닫힘). 보조: `timerAgain`(혼자일 때, restart), `timerClose`(안 적고 접기 → 카드에 "완료 · [적기]").
- 10초 미만 종료는 요약 없이 닫는다.

## 7. 타이머 시트 (`lib/timer_sheet.dart`, `showTimerSheet`) — 레인 C

Cupertino 모달 팝업(아래에서, 높이 ≤ 90%, 본문 SingleChildScrollView). 머리 `timerSheetTitle` + [완료](`doneEditing`).
- **타바타** 스위치. 켜면 칩(Wrap): `timingWorkSeconds`, `timingRestSeconds`, `timingRounds`; 칩 탭 → 값 시트(Tempo value_sheet: 제목, [−] 큰 숫자 [+](300ms 뒤 100ms 반복, 한계 hint), CupertinoPicker 휠(높이 180, noScaling), 프리셋 칩). 운동 1~600(휠 1초 단위 ≤60, 이후 5초; 프리셋 20·30·45·60), 휴식 1~600(10·15·30·60), 라운드 1~99(4·6·8·10·12). 아래 미니 띠 + `timerTotalLine`.
- **박자** 스위치. 켜면 `timingBpm`(10~120, 1 단위, 프리셋 20·30·40·60·90; 새로 켜면 60) + `timerTargetChip`/`timerNoTarget`(0=없음, 1~999, 프리셋 10·20·30·50·100 → `setup.repsPerSet` 에 쓴다; setup 이 없으면 `WorkoutSetup(name: 운동 이름, repsPerSet: n)` 를 만든다).
- **소리·진동**: `countAloud`(전역), `timerHaptics`(전역 hapticsOn). 설정 화면에도 같은 토글.
- [완료] → 이름 = `spec.applyTo(TimingSpec.removeFrom(name))`(꺼진 것은 떼고 켜진 것만). 이름이 비면: 켜진 쪽 낱말(타바타 이름은 locale 별: ko 타바타, ja タバタ, 그 밖 Tabata; 박자는 `60bpm`)만으로 둔다. 둘 다 껐는데 이름이 비면 [완료] 비활성 + `timerNameNeeded`. `renameBlock(learn: false)`. 목표는 setup 갱신.
- 돌고 있는 칸이면 읽기 전용 + `timerReadOnly`(liveRegion).
- 진입: (a) ⋯ 설정 칩 줄에 `timerSheetTitle` 칩(타이머가 없을 때 "+ 타이머", 있을 때 요약 칩). (b) 운동 이름 입력 줄이 **비었을 때** 후보 막대에 [타바타]·[박자] 칩 → locale 이름(타바타/タバタ/Tabata, `60bpm`)의 칸을 만들고 시트를 연다(입력칸에는 쓰지 않는다). (c) 카드 띠의 요약 글 탭.

## 8. 카드 띠 (`lib/timer_strip.dart`, `TimerStrip`) — 레인 C; `WorkoutTimingControls` 를 대체

- 대기: `[미니 띠 8pt(타바타: 운동/휴식 비율 막대; 박자: 점선)] [요약 13pt, Expanded, 1줄 ellipsis] [▶ 시작 알약 44pt, seal/sealTint]`. 세션 중 `[▶ 시작][같이 ▾]`. 제안 뒤 "민수 님을 기다리는 중… [취소]"(기존 문구). 글자 2.0배에서는 요약이 띠 아래 줄로 내려간다.
- 돌 때(무대 접힘): `[구간색 세로 띠 4pt][남은 수 28pt tabular][라벨 · R3/8 13pt] … [∥ 44][열기 ▸ 44]` — 띠 전체 탭 = 무대 열기. 일시정지면 회색.
- 완료·미기록: `timerDoneLine`/`timerDoneBpmLine` + `[적기 ▸](무대 요약 열기)` `[↺](reset)`.
- 같이 하기 콜백(`TogetherTiming`): 같이 ▾ → 액션시트(`togetherStart`/`togetherAlternate`), 대기·취소, 상대 초대 배너(편집기 맨 위, 기존). **혼자 시작**: 내 미시작 제안이 있으면 거둔다(clearTimer), 같이 돌던 것에 들어가 있으면 빠진다(_leaveShared) — 기존 `_togetherToggle` 분기를 그대로 쓴다.
- 시작 때: 키패드 내림(기존), 타바타 첫 시작이면 `HealthLink.authorize()`(아직 안 물었을 때만) → AlarmKit `authorizeRestAlarm()`(한 번) 을 **무대를 열기 전에** 묻는다. 운동 도중 시스템 대화상자를 띄우던 `_followHeart` 의 권한 요청은 지운다. `_audio.warmUp()` 은 편집기에 타이머 칸이 보일 때 한 번.
- 자동 열기: 같이 하는 타이머가 `follow()` 로 돌기 시작하면, 편집기 라우트가 맨 위(`ModalRoute.isCurrent`)이고 무대가 안 열려 있을 때만 연다(`_runOpen` 플래그).
- Android 심박 폴링은 앱이 resumed 일 때만(`_followTimer` 가 lifecycle 을 본다).

## 9. 같이 하기 (무대 안)
- `timer.shared`: « » 없음, 처음부터 없음, 종료 = 그만(`onLeave` = 편집기 `_leaveShared`), 그만둔 뒤 [다시 들어가기](`onRejoin`). 교대 "상대 차례". 휴식 RestLog 는 같다(`onLogRound` → `logReps` 경로). 요약 사람별 표.
- 박자 target 완료(shared) → 편집기가 `onComplete` 에서 `leaveTimer(at, count)`.
- 편집기는 파트너 소식·rebuild 마다 `link.together = _togetherFor(block, l)` 을 넣고 `link.changed()`.

## 10. 심박
- `_followTimer/_followHeart` 유지(권한 요청만 §8 로 옮김). 무대 Extra 줄. shared 면 끊지 않음 안내.

## 11. 설정
- 설정 화면 "박자 소리내어 세기" 아래 `timerHapticsSetting` 토글. NotesStore 설정 JSON `hapticsOn`(기본 true) — 레인 A 가 저장소, 레인 C 가 화면.

## 12. 테스트·수락 기준 (골든 없음 — Tempo `run_look_test` 방식)

A(단위, `test/workout_timing_test.dart`·`test/timing_spec_test.dart`·`test/shared_timer_test.dart`):
- 타바타 8×20/10 = 3+160+70 = **233초**에 complete, tail 은 243. 마지막 라운드 rest 없음. 라운드 종료 말 8번째는 완료 말과 겹치지 않게(8번째는 말하지 않거나 complete 뒤) — 지금 테스트(1·2라운드 종료) 갱신.
- 박자 target 30 @60bpm: complete 는 3 + 29 + 0.5 + 0.05 = 32.55초 뒤 첫 tick, count 30 유지, 일시정지해도 count 유지, target 없으면 영원히 work.
- 'bpm' 낱말만 → **120 유지**. "푸시업 3x10 타바타" rounds 8(기본)·`applyTo` 가 3x10 보존, "타바타 x6" 6, 끝이 숫자인 제목 왕복, `removeFrom` 빈 결과 '', `statName` 회귀.
- skip/back(구간·2초 규칙·shared 무시·말 세대·_voiceFreeAt 리셋·클릭 재배치 `_sound` 호출), end(10초 미만 reset, 이상 endedEarly + onComplete 1회, complete 큐 없음), restart, resume.
- 수명주기: paused/hidden 에 안 멈춤, detached 에 멈춤; interrupted → pause, resumed → resume; 손으로 재개한 뒤 resumed 는 무시; 인터럽션 중 reset 뒤 resumed 무시.
- 벽시계 보정(now·wallNow 주입: 단조 2초, 벽 62초 → elapsed +60초, 놓친 큐 없음).
- shared 박자 target 완료 뒤 follow() 가 다시 켜지 않는다. 햅틱 순서. count notify. level 값. zh 로케일 매핑. RestRecovery 재부착.
S(위젯, `test/run_page_test.dart`): 숫자 getSize(폭 ≤90%, 높이 ≥40%; 320×568 은 ≥30%), waterline 위/아래 픽셀 색(흰·#141414·구간색), 일시정지 회색, 두 얼굴 같은 y, 잠금(2초 미만 안 잠김·잠긴 뒤 탭 무시·Android back nudge), 길게 눌러 종료(0.5초 유지·1.1초 종료), 10초 미만 요약 없음, 스와이프 skip, **숫자·바탕 탭·세로 스와이프 뒤 running 유지**, RestLog → onLogRound(round, n), 요약 주 버튼 → 안 쓴 라운드만, 박자 요약 → onLogCount(count), shared(«» 없음·종료=onLeave·다시 들어가기·사람별 표 세 줄), 접기 = pop + 타이머 running 유지, 가로 고정 호출, takeException null at 320×568·375×667·393×852 × 1.0/1.5/2.0 × ko·en·th·es·vi, onFill 대비 4.5:1.
C(위젯, `test/timer_strip_test.dart`·`test/timer_sheet_test.dart`): 카드 세 상태(320×2.0 es 포함), 세션 중 혼자 시작 + 같이 ▾ 액션시트(기존 키 together-start/-simultaneous/-alternate 유지), 대기·취소, 다른 칸 시작 확인 시트, 시트 [완료] → 제목 재작성·목표 setup·빈 이름 처리·끄기, 값 시트 clamp·프리셋, ⋯ 칩 줄 [타이머] 칩 → 시트, 빈 입력 줄 [타바타]/[박자] 칩 → 칸 생성(locale 이름) + 시트, 제목 수정으로 spec 이 바뀌면 돌던 타이머 clear, 권한 호출 1회·무대 열기 전, 루틴 fixture 의 타바타 제목 parse, 설정 화면 진동 토글.
옮길 기존 테스트: workout_timing_test 위젯 3개(175-318: 편집기 안 타이머·외부 설정 상태·네 칸 스테퍼) → timer_strip/timer_sheet 로 재작성, `_adjustable` 눈금(567-581) → 시트 clamp, shared_timer_test '타이머 칸' 3개(365-560) → timer_strip(제안·대기) + run_page(그만·다시·RestLog), partner_groups_test '세 줄'(213-250) → run_page 요약 표. 기존 키 이름(together-*, exercise-settings-$id)은 새 위젯이 그대로 쓴다.

## 13. 범위
- 이번 판에 넣는다: §2~§11 전부(EndPulse·LastRoundBorder·BeatPulse·스와이프·잠금 nudge·접힌 카드 라이브 숫자·값 시트 휠·removeFrom·요약 심박 줄 포함).
- 1.8.1 로 미룬다: Android 포그라운드 서비스(+Play Console FGS 선언), 골든 테스트(폰트 번들), 준비 3/5/7·예고 옵션, EMOM/AMRAP/FOR TIME, 녹음 음성, 가로 레이아웃, 강제 종료 복구, Live Activity.

## 14. 레인과 파일
- **A 엔진**(lane/timer, setpad-wt/timer): `lib/workout_timing.dart`(TimingSpec·WorkoutTimer; 옛 `WorkoutTimingControls` 는 새 API 로 컴파일되게만 손댄다), `lib/run_link.dart`(새), `lib/run_page.dart`(**스텁**: `class RunPage extends StatefulWidget { const RunPage({super.key, required this.link}); final RunLink link; }` + 최소 화면), `lib/shared_timer.dart`(tail), `lib/rest_recovery.dart`, `lib/timing_audio_contract.dart`·`_native.dart`·`_web.dart`, `lib/parser.dart`(timerTokens 가 roundsPattern 참조), `lib/record_query.dart`(statName → removeFrom), `lib/notes.dart`(hapticsOn), 테스트. **arb·네이티브는 손대지 않는다.**
- **L 문구**(setpad-wt/timer-l10n, main 기준): §15 키를 9개 arb 끝에 + gen-l10n. 코드는 안 바꾼다.
- **N 네이티브**(setpad-wt/timer-native, main 기준): `ios/Runner/TimingBridge.swift`, `ios/Runner/Info.plist`, `android/.../TimingBridge.kt`, `MainActivity.kt`, `web/timing_audio.js`, `docs/timer-device-checklist.md`. Dart 는 안 바꾼다.
- **S 무대**(A+L+N 합친 뒤): `lib/run_page.dart`(스텁 교체), `lib/stage_palette.dart`, `test/run_page_test.dart`.
- **C 카드·시트·연결**(A+L+N 합친 뒤, S 와 동시): `lib/timer_strip.dart`, `lib/timer_sheet.dart`, `lib/editor.dart`(타이머 wiring 전부: TimerStrip·시트·RunLink·RunPage 열기·자동 열기·권한·warmUp·심박 lifecycle·onComplete→leave·다른 칸 시작 확인·후보 막대 칩·⋯ 칩), `lib/setup_chips.dart`(타이머 칩), `lib/settings_page.dart`(진동), `WorkoutTimingControls`·`_Stepper`·`_RepeatingKey`·`_RoundBar`·`_CountEntry` 삭제, 기존 테스트 옮기기.

## 15. 새 문구 키 (ko / en; 나머지 7개 언어는 L 이 번역) — 이미 있는 키는 재사용: timingReady·timingWork·timingRest·timingComplete·timingStart·timingPause·timingReset·timingBpm·timingWorkSeconds·timingRestSeconds·timingRounds·timingHeart·togetherStart·togetherAlternate·togetherLeave·togetherRejoin·togetherTheirTurn·togetherWith·togetherLeftRound·togetherLeftBeat·togetherMe·togetherLog·countAloud·doneEditing·cancel

| 키 | 자리표시 | ko | en |
|---|---|---|---|
| timerCollapse | | 접기 | Minimize |
| timerCollapseA11y | | 접기, 타이머는 계속 돌아요 | Minimize, the timer keeps running |
| timerPaused | | 일시정지 | Paused |
| timerResume | | 계속 | Resume |
| timerRestart | | 처음부터 | Restart |
| timerEnd | | 종료 | End |
| timerHoldEnd | | 길게 눌러 종료 | Hold to end |
| timerHoldLeave | | 길게 눌러 그만 | Hold to leave |
| timerLock | | 화면 잠금 | Lock screen |
| timerUnlock | | 잠금 해제 | Unlock |
| timerLockHint | | 두 번 탭해 잠가요 | Double-tap to lock |
| timerUnlockHint | | 두 번 탭해 풀어요 | Double-tap to unlock |
| timerLockedHint | | 자물쇠를 2초 눌러 풀어요 | Hold the lock for 2 s to unlock |
| timerLockedAnnounce | | 화면을 잠갔어요 | Screen locked |
| timerUnlockedAnnounce | | 잠금을 풀었어요 | Unlocked |
| timerSkipNext | | 다음 구간 | Next interval |
| timerSkipBack | | 이전 구간 | Previous interval |
| timerLastRound | | 마지막 라운드 | Last round |
| timerRoundShort | n,total | R {n}/{total} | R {n}/{total} |
| timerNext | items | 다음 · {items} | Next · {items} |
| timerLeftTotal | time | 전체 남은 {time} | {time} left in total |
| timerElapsed | time | 경과 {time} | Elapsed {time} |
| timerAboutLeft | time | 남은 약 {time} | About {time} left |
| timerGo | | 시작! | Go! |
| timerTarget | target | / {target}회 | / {target} |
| timerBeatLine | count(String) | {count} | Beat {count} |
| timerBeatA11y | n | {n}번째 박자 | Beat {n} |
| timerCountA11y | count,target | {count} / {target}회 | {count} of {target} |
| timerRemainingA11y | time | 이번 구간 남은 시간 {time} | {time} left in this interval |
| timerHeartShared | | 같이 할 땐 심박으로 휴식을 끊지 않아요 | Rest isn't cut by heart rate while together |
| timerRestLog | | 이번 라운드 횟수 | Reps this round |
| timerLogged | n | {n}회 적었어요 | Logged {n} |
| timerDone | | 끝! | Done! |
| timerStopped | | 여기까지 했어요 | That's all for now |
| timerRoundsDone | n (plural) | {n}라운드 | {n, plural, =1{1 round} other{{n} rounds}} |
| timerRepsDone | n | {n}회 | {n} reps |
| timerRepsOfTarget | n,target | {n} / {target}회 | {n} / {target} reps |
| timerTotal | | 총 시간 | Total |
| timerTime | | 시간 | Time |
| timerTempo | | 박자 | Tempo |
| timerRoundChip | n,reps(String) | {n}R {reps} | R{n} {reps} |
| timerRoundCountTitle | n | {n}라운드 횟수 | Round {n} reps |
| timerFillRest | n | 남은 라운드 모두 {n}회 | All remaining rounds: {n} |
| timerClear | | 비우기 | Clear |
| timerLogSets | | 세트로 적기 | Log as sets |
| timerLogSetsCount | n (plural) | {n}세트 적기 | {n, plural, =1{Log 1 set} other{Log {n} sets}} |
| timerAgain | | 다시 하기 | Again |
| timerClose | | 닫기 | Close |
| timerLastRest | from,to | 마지막 휴식 ♥ {from} → {to} | Last rest ♥ {from} → {to} |
| timerSummaryTabata | work,rest,rounds,total(String) | 운동 {work}초 · 휴식 {rest}초 × {rounds} · {total} | {work}s work · {rest}s rest × {rounds} · {total} |
| timerTargetChip | n | 목표 {n}회 | Target {n} |
| timerNoTarget | | 목표 없음 | No target |
| timerOpen | | 열기 | Open |
| timerDoneLine | rounds,time(String) | 완료 · {rounds}라운드 · {time} | Done · {rounds} rounds · {time} |
| timerDoneBpmLine | count,time(String) | 완료 · {count}회 · {time} | Done · {count} reps · {time} |
| timerLogNow | | 적기 | Log |
| timerTogether | | 같이 | Together |
| timerSwitchAsk | | 도는 타이머를 멈추고 이것을 시작할까요? | Stop the running timer and start this one? |
| timerSwitchConfirm | | 멈추고 시작 | Stop and start |
| timerUnloggedAsk | n | 적지 않은 {n}라운드가 있어요 | {n} rounds aren't logged yet |
| timerLogFirst | | 먼저 적기 | Log first |
| timerDiscardStart | | 버리고 시작 | Discard and start |
| timerActionFailed | | 요청을 못 보냈어요 · 다시 | Couldn't send · Retry |
| timerSheetTitle | | 타이머 | Timer |
| timerAddChip | | + 타이머 | + Timer |
| timerTabata | | 타바타 | Tabata |
| timerBeat | | 박자 | Metronome |
| timerTotalLine | time | 총 {time} | Total {time} |
| timerHaptics | | 진동 | Vibration |
| timerHapticsSetting | | 타이머 진동 | Timer vibration |
| timerReadOnly | | 멈춘 뒤 바꿀 수 있어요 | Stop the timer to change this |
| timerNameNeeded | | 이름을 먼저 적어요 | Add a name first |
| timerWorkTitle | | 운동 시간 | Work time |
| timerRestTitle | | 휴식 시간 | Rest time |
| timerRoundsTitle | | 라운드 | Rounds |
| timerBpmTitle | | 박자 빠르기 | Tempo (BPM) |
| timerTargetTitle | | 목표 횟수 | Target reps |
| timerSecondsValue | n | {n}초 | {n}s |
| timerMinValue | | 최솟값이에요 | That's the minimum |
| timerMaxValue | | 최댓값이에요 | That's the maximum |
