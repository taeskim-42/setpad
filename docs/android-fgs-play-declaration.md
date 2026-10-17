# Play Console — 포그라운드 서비스 권한 선언 (Android 1.8.0~)

1.8.0 부터 Android 앱은 사용자가 시작한 운동 타이머(타바타·박자 run)나 세트 사이 휴식이 도는 동안 포그라운드 서비스(`TimingService`, 유형 **`health`**)를 띄운다. 화면을 끄거나 앱을 나가도 진행 중인 운동을 계속 기록하고(구간·라운드·경과 시간, 끝난 뒤 적을 세트), 신호음·녹음 음성이 제때 나게 하려는 것이다. targetSdk 34 이상에서 포그라운드 서비스를 쓰는 앱은 **다음 Play 출시 전에** 이 선언을 마쳐야 한다. 선언이 없으면 그 출시가 심사에서 막힌다.

## 왜 health 인가 (근거 원문)

- Android 문서, 포그라운드 서비스 유형 `health`: "Any long-running use cases to support apps in the fitness category such as exercise trackers." (https://developer.android.com/develop/background-work/services/fgs/service-types)
- Play 고객센터 FAQ: "an exercise app that tracks a user’s exercise can declare the \"health\" foreground service type." (https://support.google.com/googleplay/android-developer/answer/13392821)
- `mediaPlayback` 의 정의는 "Continue audio or video playback from the background" 이다. 이 서비스는 소리가 없는 긴 구간(세트 휴식, 박자 없는 타바타)에도 돌기 때문에 맞지 않는다. Play 정책: "Don't declare invalid or inaccurate FGS types in your app’s manifest." (https://support.google.com/googleplay/android-developer/answer/9888379)
- `health` 의 실행 조건: "At least one of the following conditions must be true: Declare the HIGH_SAMPLING_RATE_SENSORS permission in your manifest. Request and be granted at least one of the following runtime permissions: … READ_HEART_RATE …". 심박 권한을 거절한 사용자도 서비스를 쓸 수 있게 매니페스트에 `HIGH_SAMPLING_RATE_SENSORS`(일반 권한, 권한 창 없음)를 선언했다.

## 어디서

Play Console → setpad → **앱 콘텐츠(App content)** → **포그라운드 서비스 권한(Foreground service permissions)** → 시작/관리.

예전 초안(1.8.0 TestFlight 단계)의 `FOREGROUND_SERVICE_MEDIA_PLAYBACK` 선언을 이미 냈다면 그 항목은 지우고 아래로 바꾼다. 앱 번들에 그 권한이 더 이상 없다.

## 무엇을 적나

| 칸 | 값 |
|---|---|
| 권한 | `FOREGROUND_SERVICE_HEALTH` |
| 기능 유형(use case) | **Health Data Sync** (목록 설명: "Syncing of health data for apps in the fitness category, which can be across apps or to gather data collected through on-device tracking. For example, step counter, exercise tracker.") |
| 설명 (영문) | 아래 "설명" 문단 |
| 시스템이 미루면 / 중단하면 (영문) | 아래 "사용자 영향" 문단 |
| 동영상 링크 | 아래 "영상 찍기" 로 만든 YouTube(일부 공개) 링크 |

목록에 Health Data Sync 가 보이지 않으면 직접 입력 칸에 "Exercise tracker: recording an active workout" 이라고 적는다(고객센터: "if you do not see your use case listed, you can enter your use case manually").

### 설명 (그대로 붙여 넣는다)

> setpad is a workout logging app. When the user starts a workout timer (an interval/Tabata run or a metronome run for an exercise) or a rest between sets, the app records that active workout: it tracks the phase, round and elapsed time, collects the sets to log when the run ends, and (while the app is on screen, if the user allowed it) uses the heart rate from Health Connect to end a Tabata rest once the heart rate has recovered. It also sounds the interval cues and recorded spoken counts the user chose. Users put the phone down or in a pocket mid-workout, so recording must continue with the screen off or the app in the background. The foreground service runs only while a user-started timer or set rest is running, shows the notification "Recording your workout · timer running", and stops as soon as the user pauses or stops the timer or it finishes (at most 6 seconds later, so the final cue can finish). It is never started for any other purpose.

### 사용자 영향 (그대로 붙여 넣는다)

> If the system defers the start, the workout the user just started is not tracked while the screen is off: interval and rest boundaries, cues and spoken counts are missed. If the system interrupts it mid-workout, the run stops advancing in the background; when the user returns, the elapsed time is corrected but every cue and boundary in between was missed, so the user cannot follow an interval workout with the phone in a pocket.

서비스는 소리를 내는 타이머(운동 타이머 run, 세트 사이 휴식)가 도는 동안에만 켜진다. 세트 무대만 열어 둔 상태는 화면만 켜 둘 뿐 서비스를 켜지 않는다(`lib/timing_audio_mux.dart` 의 keepAlive). 알림을 누르면 앱이 열린다. Android 14+ 에서 사용자가 알림을 밀어 지워도 기록은 계속된다(알림만 숨는다).

## 영상 찍기 (30초~1분, 실기기)

Google 은 TYPE_HEALTH 영상에 대해 "Show a user initiating a health data sync, such as counting steps or recording an active workout." 이라고 적었다. 그러니 **사용자가 운동 기록(타이머)을 직접 시작하는 장면**이 먼저 나와야 한다. 실제 Android 폰에서 화면 녹화(빠른 설정 → 화면 녹화, "미디어 소리 녹음" 켬)로 찍는다. 에뮬레이터는 소리가 없어 부적합하다. 기기 언어는 영어가 좋다(심사자가 알림 문구를 읽을 수 있게).

1. 녹화를 켜고 setpad 를 연다. 오늘 기록에 `Burpee tabata 20/10 x3 60bpm` 칸(한국어 기기면 `버피 타바타 20/10 x3 60bpm`)이 있는 것을 보여 준다.
2. [▶ Start] 를 누른다 — 사용자가 운동 기록을 시작하는 장면. 라운드·남은 시간이 움직이고 신호음·숫자 음성이 나는 것을 몇 초 보여 준다.
3. 홈으로 나가 알림 창을 내려 **"Recording your workout · timer running"** 알림이 떠 있는 것을 보여 준다(한국어 기기면 "운동 기록 중 · 타이머가 돌고 있어요").
4. 앱 밖(홈 화면)에서 라운드가 바뀌는 신호음·음성이 계속 나는 것을 몇 초 들려 준다. 화면을 끄는 장면은 녹화에 안 담기므로 홈 화면에서 기록이 이어지는 것으로 보여 준다.
5. 알림을 눌러 앱으로 돌아온다 — 타이머가 실제 경과 시간 자리에서 돌고 있다.
6. [Pause] 를 누르거나 끝까지 둔다 → 알림이 사라지는 것을 보여 준다. 끝까지 두면 run 의 세트를 기록으로 적는 화면까지 보여 준다(기록하는 앱이라는 것이 드러나게).

YouTube 에 **일부 공개(Unlisted)** 로 올리고 링크를 선언에 넣는다.

## 바뀌면

- 서비스 유형을 바꾸거나(`AndroidManifest.xml` 의 `foregroundServiceType`) 다른 목적에 서비스를 쓰게 되면 이 선언을 다시 고친다.
- `HIGH_SAMPLING_RATE_SENSORS` 를 빼면 심박 권한을 거절한 Android 14+ 사용자에게서 서비스 시작이 막힌다(`startForeground` 가 SecurityException).
- Android 는 심박을 앱이 앞에 있을 때만 읽는다(백그라운드 건강 데이터 권한 `READ_HEALTH_DATA_IN_BACKGROUND` 없음). 설명에 "화면이 꺼진 동안 심박을 읽는다" 고 쓰지 않는다 — 그렇게 바꾸려면 그 권한과 Health Connect 선언이 먼저다.
- 반려되면: 반려 사유를 이 문서에 적는다. 서비스를 빼면(`TimingBridge.kt` 의 `TimingService.start/stop` 두 줄과 매니페스트의 `<service>`·권한 넷) 화면이 꺼진 동안 Android 타이머가 멈출 수 있고, 돌아오면 숫자가 제자리를 찾는다(놓친 신호는 울리지 않는다).
