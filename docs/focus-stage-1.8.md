# 세트 무대("운동 화면") — 1.8.0 (v2, 비평 반영)

작성 2026-10-17. 사용자 요청: "tempo에 있는 ui/ux를 가져오면 되는거 아닌가..? 운동할때는 어차피 그 운동에만 집중하니까" → "구현까지 쭈우욱 밀어라잉".
입력: 타이머 무대 명세 `docs/timer-redesign-1.8.md`, 구현 `lib/run_page.dart`·`stage_palette.dart`·`timer_sheet.dart`(Tempo 이식), 비평 scratchpad `focus-critics.md`(41건).
**기반: 브랜치 release/1.8.0(UX·루틴·같이 하기·타이머가 다 합쳐진 뒤).** 표기: 🟩 사실 / 🟦 결정. 이 문서가 레인 K(코어)·W(문구)·U(무대)·E(편집기 연결)의 계약이다.

## 0. 한 줄
무게·횟수 세트를 하는 동안 **그 운동 하나만** 어두운 무대에 크게 띄운다. 다음 세트가 히어로 숫자, 큰 바 [했어요] 한 번 → 휴식 카운트다운(Tempo 수위·휴식색·끝 3초 플래시) → 끝 소리(앞)·알림(뒤·잠금) → 다음 세트. 세트는 지금 문서에 그대로 쌓인다(무대는 문서의 다른 보기).

## 1. 원칙
1. 무대는 문서를 바꾸는 다른 창이다. 세트는 편집기 컨트롤러로 쓴다(같이 하기 문서 push·저장 그대로). 무대를 접으면 문서 그대로.
2. 숫자를 지어내지 않는다. 제안은 계획·지난번·내 마지막·제목 설정에서만 오고, 없으면 사람이 정한다(휠). 무게 0 은 저장하지 않는다(맨몸 = value null).
3. 화면·숫자 탭은 세트를 쓰지 않는다. 쓰는 것은 큰 바 [했어요] 하나. 잘못 누르면 [되돌리기](세트와 시작된 휴식을 함께 되돌림).
4. 무대는 늘 어둡다(`stage_palette`). 무대가 열려 있는 동안 화면은 켜 둔다.
5. 남의 세트(`theirs` = author != null)는 보이기만 하고 고치지도, 제안 근거로 쓰지도 않는다.
6. 타이머 칸(타바타·bpm)은 무대 목록에 들어가되, 그 칸에서는 [▶ 타이머 시작] 으로 타이머 무대(RunPage)를 연다.

## 2. 흐름
```
편집기 내비 막대 [▶](운동 화면, 운동이 하나라도 있고 대신 적기 편집기가 아닐 때) ─>
  세트 무대: 시작 칸 = 커서가 든 칸 → 계획 ○ 가 남은 첫 칸 → 마지막 칸
  할 세트(LIFT): 히어로 "80 kg × 5" · "지난번 이 자리 80 × 5" · 조절기 · 오늘 세트 줄 · [✓ 했어요]
  [했어요] ─> 세트 기록(계획 세트 id 면 그 세트를 값대로 해냄, 아니면 새 세트) ─> 휴식 시작(무게·횟수 세트만; 시간·거리 세트는 [휴식 시작] 작은 단추)
             바는 1초 동안 눌리지 않는다(두 번 탭 방지). 위 오른쪽 [되돌리기] 칩(5초, 보조기기면 15초).
  휴식(REST, 휴식을 시작한 칸을 볼 때): 수위(휴식색) 빠짐 · 히어로 남은 초 · "다음 · 4세트 80 × 5" · [−15][바로 다음 세트][+15] · ♥ 줄
       끝 3·2·1초 띠 + 흰 플래시, 0초 끝 소리(complete ding) + 햅틱 ─> LIFT
  « » / 좌우 스와이프: 앞·뒤 칸. 휴식은 계속 돈다. 휴식을 시작한 칸이 아니면 LIFT 로 보이고 맨 위에 알약 "휴식 1:12"(탭=그 칸으로) — 슈퍼세트: 벤치 휴식 중 로우를 적으면 새 휴식이 로우에서 시작.
  계획(또는 setup.totalSets/totalReps)이 끝나면 LIFT 라벨이 "계획 끝" 이고 히어로는 한 세트 더 제안, 큰 바는 그대로 [했어요], 그 위에 [다음 운동: 스쿼트 →] 가 크게.
  [이 운동 끝] ─> 운동 요약: 세트 칩·세트 수·볼륨·최고·지난번 비교 · [다음 운동 →] [한 세트 더] [접기]
  [접기 ▾] ─> 문서로. 휴식이 돌면 편집기 위 띠 "휴식 0:42 · 열기"(44pt). 편집기를 닫으면 휴식은 조용히 멈춘다(알림도 취소).
  같이 하는 타이머가 세트 무대 위에서 돌기 시작하면 맨 위에 띠 "같이 하는 타이머 · 열기"(탭=타이머 무대).
```

## 3. 순수 함수 (레인 K: `lib/focus.dart`)
```dart
enum FocusSource { planned, lastTime, lastSet, setup, none }
class FocusSuggestion { final LoggedSet values; final FocusSource source; final String? plannedId; final LoggedSet? lastTimeSame; }
FocusSuggestion nextSet(ExerciseBlock block, Iterable<Note> earlier, {required String key, String weightUnit = 'kg'});
```
- `earlier` = 지금 노트가 아닌 내 기록들(날짜로 자르지 않는다). `key` = `exerciseKey(block.exercise)`(매개변수 이름은 key — record_query 의 최상위 `exerciseKey` 를 가리지 않게).
- 순서: **planned**(이 칸에서 `!theirs && !done` 인 첫 세트, plannedId = 그 id) → **lastTime**(earlier 에서 같은 key 의 가장 최근 노트, 그 노트의 그 운동 내 해낸 세트들 중 k번째 — k = 오늘 이 칸의 내 해낸 세트 수, 지난번 세트 수를 넘으면 마지막) → **lastSet**(이 칸의 `!theirs && done` 마지막 세트 복사 — `myLast` 를 쓰지 않는다) → **setup**(제목 설정 `setup.weight/unit/repsPerSet`) → **none**(values: value null, reps null).
- 🟦 트레이드오프(결정): lastTime 이 lastSet 보다 앞이라 피라미드·워밍업이 지난번 순서를 따른다. 오늘 무게를 올렸으면 다음 세트도 조절기 한 번.
- `lastTimeSame` = lastTime 의 k번째 세트(LIFT 의 "지난번 이 자리" 줄; source 와 상관없이 있으면 채운다).
- 끝 판정 `planDone(block)`: 계획 ○ 가 있었다면 다 해냄, 없으면 `setup.totalSets` 가 있으면 내 해낸 세트 수 ≥ totalSets, `setup.totalReps` 가 있으면 completedReps ≥ totalReps, 그 밖엔 false.
- `kindOf(LoggedSet)`: value null → reps(맨몸), unit kind weight/duration/distance.
- 조절 폭: weight 는 `unitById[unit].step`(kg 2.5, lb 5), duration s 10·min 1, distance km 0.5·m 50·mi 0.5, 횟수 1. 0 아래로 안 감. 무게가 0 이 되면 value null(맨몸)로.
- [했어요] 켜짐: weight·맨몸 → reps ≥ 1; duration·distance → value > 0.
- `stats(sets)`(요약): 세트 수, weight 면 볼륨 = Σ(무게×reps) — 단위는 첫 무게 세트의 단위, 다른 무게 단위는 환산(1 kg = 2.20462 lb), 맨몸 세트는 볼륨에 0·횟수 합에 더함; duration 은 Σ시간, distance 는 Σ거리, 맨몸만이면 Σreps. `best` = 가장 무거운 무게(같으면 많은 횟수); 맨몸은 가장 많은 횟수; duration/distance 는 가장 긴 것.

## 4. 오디오 하나를 나눠 쓰기 (레인 K: `lib/timing_audio_mux.dart`)
🟩 네이티브 `configure(active,bpm,cue,phase)` 의 active 는 하나다: 화면 켜 둠(iOS isIdleTimerDisabled, Android FLAG_KEEP_SCREEN_ON)·세션이 이것을 따른다(무음 keep-alive 루프는 2026-10-17 에 지웠다 — 애플 2.5.4). 두 객체가 따로 보내면 서로 끈다.
🟦 `TimingAudioMux` 가 진짜 `TimingAudio` 하나를 쥐고 **포트**를 나눠 준다: `mux.port('workout')`, `mux.port('rest')`, `mux.port('stage')`. 각 포트는 `TimingAudio` 를 구현한다.
- 포트의 configure(active, bpm, cue, phase) 는 그 포트의 상태만 바꾸고, mux 가 합쳐 한 번 보낸다: `active = 어느 포트든 active`, `bpm/phase = workout 포트가 active 일 때 그 값`, `cue = 이번 호출의 cue`. 명령은 mux 의 직렬 체인 하나로 나간다.
- speak 는 그대로 넘긴다. onInterrupted/onResumed 는 workout 포트에만 전한다(휴식은 인터럽션에도 시계를 그대로 센다).
- 포트 dispose 는 그 포트를 inactive 로 하고 합친 상태를 보낼 뿐 진짜 audio 를 닫지 않는다. 진짜 audio 는 mux 주인(편집기)이 마지막에 닫는다. warmUp 은 넘긴다.
- 편집기는 `WorkoutTimer(audio: mux.port('workout'))`, `RestTimer(audio: mux.port('rest'))`, 무대가 열리면 `port('stage').configure(active: true)`(화면 켜 둠), 닫히면 false. **네이티브는 바꾸지 않는다.**

## 5. 휴식 타이머 (레인 K: `lib/rest_timer.dart`)
```dart
class RestTimer extends ChangeNotifier with WidgetsBindingObserver {
  RestTimer({required TimingAudio audio, bool Function()? muted, Duration Function()? now, DateTime Function()? wallNow,
             void Function(TimerHaptic)? haptic, RestNotifier? notifier});
  Object? owner;                  // 휴식을 시작한 칸
  bool get running; Duration get length; Duration get remaining; double get level; // 1→0
  bool haptics;
  VoidCallback? onDone;
  void start(Object owner, Duration length); // 이미 돌면 새로
  void add(Duration delta);       // ±15초; 남은 최소 5초, length 최대 10분
  void skip();                    // 바로 끝: onDone, 소리 없음
  void stop();                    // 조용히: onDone 없음
}
abstract class RestNotifier { Future<void> schedule(DateTime at, String title, String body); Future<void> cancel(); }
```
- 단조 시계 + 벽시계 보정(WorkoutTimer 규칙 그대로: 1초 미만은 모으고 1시간 넘으면 버림). 백그라운드에서 멈추지 않는다.
- 소리: 돌기 시작하면 `configure(active:true)`. 남은 3·2·1초 `configure(active:true, cue:'ready')`. **0초는 한 번에 `configure(active:false, cue:'complete')`**(끝 소리를 자르지 않는다). stop/skip 은 `configure(active:false)`(cue 없음). `muted()`(= 타이머가 도는 중)면 cue 를 보내지 않는다(active 는 보낸다). 햅틱: 0초 heavy 두 번(150ms), 3·2·1 tick.
- 알림: 앱이 paused/hidden 이 될 때 휴식이 돌면 `notifier.schedule(끝 시각, focusRestOverTitle, focusNextUp(다음 세트))`; resumed·skip·stop·add·start 때 cancel(필요하면 다시 schedule). 구현은 `flutter_local_notifications` 의 zonedSchedule(lib/agent_alarm.dart 와 같은 플러그인 초기화 재사용; Android 는 inexactAllowWhileIdle — 정확 알람 권한을 새로 쓰지 않는다). 권한은 무대를 **처음 열 때 한 번** 묻는다(이미 허락·거절이면 묻지 않음).
- 휴식 길이: 칸의 운동 key 별 저장값(`NotesStore.restByExercise`, 최대 200개, 오래된 것부터 버림) → 없으면 `NotesStore.restSeconds`(기본 90, 15~600, 설정 화면에서만 바꿈). ±15·값 시트는 **그 운동의 값만** 바꾼다.
- 심박: 편집기 `_followTimer` 의 듣기 조건을 `wantsHeart || 세트 무대 휴식 중` 으로 넓힌다. LIFT 에 들어가면 `beginRound()`, [했어요] 에서 `beginRest()`. 휴식 중 신선하면 "♥ 132 → 107", 회복하면 줄이 "심박이 돌아왔어요 · 바로 다음 세트" 로 바뀌고 햅틱 heavy 한 번(소리 없음 — 3·2·1 과 헷갈리지 않게). 휴식은 사람이 끝낸다. 권한은 새로 묻지 않는다.

## 6. 무대 링크 (레인 K: `lib/focus_link.dart`) — 편집기(E)가 채우고 무대(U)가 읽는다
```dart
class FocusLink extends ChangeNotifier {
  FocusLink({required this.rest});
  final RestTimer rest;
  List<ExerciseBlock> blocks = const [];        // 문서 순서(타이머 칸 포함)
  String? currentId;                            // 보는 칸의 id (사라지면 가까운 칸, 없으면 무대 닫힘)
  String weightUnit = 'kg';
  RestRecovery? recovery;
  bool sharedTimerRunning = false;              // 같이 하는 타이머가 돈다(맨 위 띠)
  FocusSuggestion Function(ExerciseBlock b)? suggest;
  ({DateTime at, List<LoggedSet> sets})? Function(ExerciseBlock b)? lastTime;   // 요약 비교
  Duration Function(ExerciseBlock b)? restFor;  void Function(ExerciseBlock b, Duration d)? onRestChanged;
  /// 쓰는 순간 plannedId 로 자리를 다시 찾는다. 그 세트가 없거나 이미 해냈거나 남의 것이면 새 세트로. 쓴 세트 id 를 돌려준다.
  String? Function(ExerciseBlock b, String? plannedId, LoggedSet values)? onLog;
  /// 방금 쓴 것을 되돌린다: 새 세트면 지움, 계획이면 옛 값·○ 로.
  void Function(ExerciseBlock b, String setId)? onUndo;
  void Function(ExerciseBlock b)? onStartTimer;  // 타이머 칸: 타이머 무대 열기
  VoidCallback? onOpenSharedTimer;
  void changed() => notifyListeners();
}
```
- 무대는 칸 id 별 조절 값(draft)을 든다. `suggest` 는 그 칸에 처음 들어갈 때·[했어요]·되돌리기 직후·휴식 끝에만 다시 읽는다. `changed()` 는 칩 줄·칸 목록·띠만 새로 그린다(조절 값을 덮지 않는다).

## 7. 무대 화면 (레인 U: `lib/focus_page.dart`)
- 열기: `FocusPage.open(context, link)` — `CupertinoPageRoute(fullscreenDialog: true)`. 세로 고정·복원은 타이머 무대의 열린 무대 수 세기를 같이 쓴다. `AnnotatedRegion(light, nav #141414)`.
- 공용 부품: `run_page.dart` 안의 수위(물·두 겹 글자·clip)·끝 플래시·잠금 단추·큰 바·둥근 단추·길게 반복 키·접기 단추·글자 상한을 **같은 파일 안에서 공개 이름으로** 바꿔 쓴다(파일 이동 없음 — run_page_test 전부 통과가 수락 기준). 이름 바꾸기는 레인 K 가 한다.
- 레이아웃(세로):
```
[접기 ▾] [운동 2/5]   (휴식 알약 "휴식 1:12" — 다른 칸에서 휴식이 돌 때)        [되돌리기 칩]
벤치프레스 (title1 32, FittedBox 1줄)
[3세트 · 계획 | 지난번 이 자리 | 지난 세트와 같이 | 설정대로 | 무게와 횟수를 정해요 | 계획 끝] (20pt; REST 면 "휴식")
───────── 히어로(Expanded, 두 겹 글자) ─────────
 LIFT: "80" + " kg × 5"(같은 기준선, FittedBox) / 맨몸 "12회" / 시간 "1:00" / 거리 "5 km" / none "— × —"
       아래 13pt "지난번 이 자리 80 × 5"(lastTimeSame 이 있을 때)
 REST: 남은 초(수위 휴식색), 아래 "다음 · 4세트 80 × 5"
──────────────────────────────────────
 LIFT: 무게(또는 시간·거리) [− 56][80 kg][+ 56]  횟수 [− 56][5회][+ 56]   (값 칸 탭 = 휠 시트; 길게 = 반복; 맨몸은 무게 칸 '맨몸')
 REST: [−15 56][휴식 1:30 (탭=휠 시트)][+15 56] · ♥ 줄
 오늘 세트: ①60×10 ②80×5 ③… (가로 스크롤 칩, 지금 자리 테두리, 남의 세트 흐리게·탭 무시)
 [« 56] [✓ 했어요 | 바로 다음 세트 — 바 88 흰 바탕] [» 56]        (none 이면 큰 바가 [무게·횟수 정하기] → 휠 시트)
 [🔒 56] [이 운동 끝 / 다음 운동: 스쿼트 →]                       (잠기면 이 자리에 "자물쇠를 2초 눌러 풀어요")
```
- 휠 시트(직접 입력): 시스템 자판 없음. 무게는 단위 폭 격자의 CupertinoPicker(0~500kg / 0~1100lb, 0 = 맨몸), 횟수 0~100, 시간·거리는 그 단위 격자. 프리셋 칩: 지난번 이 자리·오늘 마지막·설정값. `timer_sheet.dart` 의 값 시트(ValueSheet)를 소수 폭을 받게 넓혀 재사용하거나 같은 꼴로 만든다.
- 타이머 칸을 보면: 히어로 자리에 그 칸의 타이머 요약(`TimingSpec.summary`)과 큰 바 [▶ 타이머 시작](onStartTimer).
- 요약: 제목 `focusSummaryTitle(name)`, 세트 칩, 행 [세트][볼륨|총 시간|총 거리|횟수][최고], 지난번 줄 + 차이 알약(+120kg / 같아요 / −40kg; 맨몸은 횟수 차이), 버튼 [다음 운동 →](마지막 칸이면 없음) [한 세트 더](LIFT 로) [접기].
- 잠금: 길게 2초, 잠긴 동안 조작 0.35·IgnorePointer, 탭은 nudge(아래 줄 안내 300ms 밝아짐), Android 뒤로 nudge. 스와이프: 좌우 ≥300 = » / «. 숫자·바탕 탭은 아무 일도 없다.
- 끝 플래시(EndPulse): REST 의 3·2·1초. reduce motion 이면 없음.
- 접근성: 히어로 container 라벨(`focusHeroA11y` "3세트, 80킬로그램 5회" / `focusRestA11y`), 상태 라벨 liveRegion(상태 바뀔 때만), 조절 단추 시맨틱(`focusWeightUp(step)` 등), 잠금 announce, 라벨 글자 1.5 상한, 히어로 noScaling.
- 넘침 0: 320×568·375×667·393×852 × 1.0/1.5/2.0 × ko·en·th·es·vi.

## 8. 편집기 연결 (레인 E: `lib/editor.dart`, `lib/main.dart`, `lib/settings_page.dart`/`settings_list.dart`, `lib/notes.dart`)
- RoutineEditor 에 `Iterable<Note> Function()? history`(지금 노트가 아닌 내 기록 — main.dart 의 EditorPage 가 store 로 넘김), `restSeconds`, `restFor/onRestChanged`(NotesStore 경유) 매개변수를 더한다. 대신 적기 편집기에는 null(무대 [▶] 없음).
- 편집기 상태가 `TimingAudioMux` 하나를 만들고 WorkoutTimer·RestTimer·무대 포트에 나눠 준다(지금 WorkoutTimer 를 만드는 자리). RestTimer 의 muted = `_workoutTimer.running`. 편집기 dispose 때 RestTimer stop(알림 cancel)·dispose, 마지막에 mux 의 진짜 audio dispose.
- 내비 막대 [▶](시맨틱 `focusOpen`, 44pt, ⋯ 왼쪽; main.dart 의 노트 페이지 막대): 키패드 내림(`_timingKeyboardHidden`) + 무대 열기(시작 칸 규칙 §2). 무대가 열리면 stage 포트 active, 닫히면 inactive.
- `FocusLink` 채우기: blocks, currentId, suggest(`nextSet(block, history(), key: exerciseKey(block.exercise))`), lastTime, restFor/onRestChanged, onLog(컨트롤러에 `String? logFocusSet(ExerciseBlock b, String? plannedId, LoggedSet values)` 를 더한다 — plannedId 로 찾아 `updateSet`+해냄, 아니면 새 세트; `theirs` 규칙·같이 하기 문서 push·저장 경로 그대로), onUndo(새 세트는 지우기·계획은 옛 값·○; UX 레인의 세트 되돌리기 줄은 이 경로에서 띄우지 않는다), onStartTimer(기존 `_startTimer(block)`), onOpenSharedTimer. 파트너 소식·rebuild 마다 `changed()` 는 post-frame 으로 한 번(build 안에서 notify 하지 않는다 — RunLink 의 `_linkNotify` 방식).
- 심박: §5 대로 `_followTimer` 조건을 넓히고 LIFT/REST 에서 beginRound/beginRest(무대가 링크 콜백 `onLift(block)`/`onRested(block)` 로 알린다 — 필요한 콜백은 FocusLink 에 더하기만).
- 휴식 띠: 무대를 접었는데 휴식이 돌면 편집기 위(파트너 배너 아래) "휴식 0:42 · 열기"(44pt, 탭=무대 열기, 끝나면 사라짐).
- 같이 하는 타이머: 세트 무대가 맨 위일 때 타이머가 돌기 시작하면 `link.sharedTimerRunning = true`(무대 맨 위 띠, 탭=onOpenSharedTimer=타이머 무대를 세트 무대 위로 연다).
- 설정 화면 "타이머 진동" 아래 "세트 사이 휴식 기본"(`focusRestDefault`, 값 1:30, 탭=휠 시트 15~600). NotesStore `restSeconds`(JSON 'restSeconds', 기본 90), `restByExercise`(JSON 'restByExercise', {key: seconds}).
- 알림 권한: 무대를 처음 열 때 한 번(NotesStore 플래그 'focusNotifyAsked'); 거절이면 알림 없이 소리만.

## 9. 문구 키 (레인 W, ko / en; 나머지 7개 언어 번역; 이미 있는 timer* 키 재사용: timerCollapse·timerCollapseA11y·timerLock·timerUnlock·timerLockHint·timerUnlockHint·timerLockedHint·timerLockedAnnounce·timerUnlockedAnnounce·timerSkipNext/Back 대신 아래 focus 키)
| 키 | 자리표시 | ko | en |
|---|---|---|---|
| focusOpen | | 운동 화면 | Workout view |
| focusExerciseOf | n,total(int) | 운동 {n}/{total} | Exercise {n}/{total} |
| focusPrevExercise | | 앞 운동 | Previous exercise |
| focusNextExerciseA11y | | 다음 운동 | Next exercise |
| focusSetLabel | n(int) | {n}세트 | Set {n} |
| focusPlanned | | 계획 | Planned |
| focusLastTimeSame | | 지난번 이 자리 | Same as last time |
| focusSameAsLast | | 지난 세트와 같이 | Same as last set |
| focusFromSetup | | 설정대로 | From your setup |
| focusPickValues | | 무게와 횟수를 정해요 | Set the weight and reps |
| focusPickButton | | 무게·횟수 정하기 | Set weight and reps |
| focusPlanDone | | 계획 끝 | Plan done |
| focusLastTimeLine | set(String) | 지난번 이 자리 {set} | Last time here: {set} |
| focusBodyweight | | 맨몸 | Bodyweight |
| focusDone | | 했어요 | Done |
| focusNextSetNow | | 바로 다음 세트 | Next set now |
| focusStartRest | | 휴식 시작 | Start rest |
| focusNextUp | set(String) | 다음 · {set} | Next · {set} |
| focusRestLength | time(String) | 휴식 {time} | Rest {time} |
| focusRestPillA11y | time(String) | 다른 운동의 휴식 {time} 남음 | {time} of rest left on another exercise |
| focusRestLess | | 휴식 15초 줄이기 | 15 s less rest |
| focusRestMore | | 휴식 15초 늘리기 | 15 s more rest |
| focusWeightUp | step(String) | {step} 올리기 | Add {step} |
| focusWeightDown | step(String) | {step} 내리기 | Remove {step} |
| focusRepsUp | | 횟수 하나 올리기 | One more rep |
| focusRepsDown | | 횟수 하나 내리기 | One fewer rep |
| focusTodaySets | | 오늘 세트 | Today's sets |
| focusExerciseDone | | 이 운동 끝 | Finish exercise |
| focusNextExercise | name(String) | 다음 운동: {name} | Next: {name} |
| focusOneMore | | 한 세트 더 | One more set |
| focusSummaryTitle | name(String) | {name} 끝! | {name} done! |
| focusSets | | 세트 | Sets |
| focusVolume | | 볼륨 | Volume |
| focusTotalTime | | 총 시간 | Total time |
| focusTotalDistance | | 총 거리 | Total distance |
| focusTotalReps | | 횟수 | Reps |
| focusBest | | 최고 | Best |
| focusLastTime | when(String),value(String) | 지난번 · {when} · {value} | Last time · {when} · {value} |
| focusSame | | 같아요 | Same |
| focusUndo | | 되돌리기 | Undo |
| focusLogged | set(String) | {set} 적었어요 | Logged {set} |
| focusHeartBack | | 심박이 돌아왔어요 · 바로 다음 세트 | Heart rate is back · next set |
| focusRestPill | time(String) | 휴식 {time} · 열기 | Rest {time} · Open |
| focusSharedTimer | | 같이 하는 타이머 · 열기 | Shared timer · Open |
| focusStartTimer | | 타이머 시작 | Start timer |
| focusHeroA11y | set(String) | {set} | {set} |
| focusRestA11y | time(String) | 휴식 남은 시간 {time} | {time} of rest left |
| focusRestDefault | | 세트 사이 휴식 기본 | Default rest between sets |
| focusRestTitle | | 휴식 시간 | Rest time |
| focusWeightTitle | | 무게 | Weight |
| focusRepsTitle | | 횟수 | Reps |
| focusRestOverTitle | | 휴식 끝 | Rest's over |

## 10. 테스트·수락 기준
K: nextSet 다섯 갈래·순서·k번째·남의 세트 무시·setup 은 lastTime/none 만 덮지 않고 자기 갈래·planDone 세 가지·조절 폭·0→맨몸·켜짐 조건, stats(단위 섞임 환산·맨몸·시간·거리), mux(두 포트 합치기: 한쪽 inactive 가 다른 쪽 active 를 끄지 않음, bpm 은 workout 만, cue 는 호출자 것, 인터럽션은 workout 만, 포트 dispose 가 진짜를 안 닫음, 직렬 순서), RestTimer(3·2·1·0 큐 — 0초는 active:false+complete 한 번, ±15 하한·상한, skip/stop, muted 면 cue 없음, 벽시계 보정, 백그라운드 안 멈춤, 알림 schedule/cancel 시점), run_page 공개 이름 바꾸기 뒤 run_page_test 전부 통과.
U: LIFT 제안 표시 다섯 가지와 라벨, "지난번 이 자리" 줄, 조절기(단위 폭·0→맨몸·길게 반복), 휠 시트 → 값 반영, [했어요] → onLog(plannedId) → 1초 동안 바 무시 → 되돌리기(세트+휴식) → onUndo, REST 전환·수위 픽셀·남은 초·[바로 다음 세트]·±15·끝 플래시, 0초 → LIFT·suggest 다시 읽음, 다른 칸에서 LIFT+휴식 알약, « »·스와이프, changed() 가 조절 값을 안 덮음, 남의 세트 흐림·탭 무시, 타이머 칸 [타이머 시작], 계획 끝 → [다음 운동], 요약 행·지난번 차이, 잠금·nudge, 접기 = pop + 휴식 계속, 숫자·바탕 탭 뒤 아무 일 없음, 넘침 0(§7).
E: [▶] 보임 조건(대신 적기 없음)·시작 칸 규칙, logFocusSet(plannedId 로 다시 찾기 — 제안 뒤 상대 세트가 앞에 끼어도 같은 계획 세트가 해냄)·새 세트·theirs 거부, onUndo, 휴식 띠(접은 뒤 보임·탭=열기·끝나면 사라짐), 편집기 닫으면 RestTimer 멈춤·알림 취소, mux 로 타이머와 휴식이 서로 화면 켜 둠을 끄지 않음, 같이 하는 타이머 띠, 설정 휴식 기본(저장·휠 시트), restByExercise 저장·상한, 심박 조건 넓힘(beginRound/beginRest 순서·타이머 notify 가 와도 끊기지 않음), 알림 권한 한 번.

## 11. 범위 밖(이번 판)
세트 사이 RPE·메모(문서에서), 운동 추가(문서에서), 워치 앱, 휴식 끝 음성, 가로 레이아웃, 노트 밖(목록 화면)에서 휴식 이어 가기.
