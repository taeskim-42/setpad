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

> setpad is a workout logging app. The foreground service runs only while a workout timer the user started is running: an interval/Tabata run, a metronome run for an exercise, or a rest between sets. With the screen off or the app in the background, the service keeps that active workout timed on the device: it times the work and rest intervals and rounds, plays the interval cues, metronome clicks and recorded spoken counts the user chose, and keeps the elapsed time and rounds so the sets can be logged to the workout record when the run ends. It reads no heart rate or other sensor data in the background; heart rate from Health Connect (only if the user allowed it) is read only while the app is on screen, to end a Tabata rest once the heart rate has recovered. Users put the phone down or in a pocket mid-workout, so the timing and cues must continue with the screen off. The service shows the notification "Recording your workout · timer running" and stops as soon as the user pauses or stops the timer or it finishes (at most 6 seconds later, so the final cue can finish). It is never started for any other purpose. The manifest declares HIGH_SAMPLING_RATE_SENSORS only because Android lists it as one of the prerequisites for the health foreground service type; the app does not read motion sensors.

### 사용자 영향 (그대로 붙여 넣는다)

> If the system defers the start, the workout the user just started is not tracked while the screen is off: interval and rest boundaries, cues and spoken counts are missed. If the system interrupts it mid-workout, the run stops advancing in the background; when the user returns, the elapsed time is corrected but every cue and boundary in between was missed, so the user cannot follow an interval workout with the phone in a pocket.

서비스는 소리를 내는 타이머(운동 타이머 run, 세트 사이 휴식)가 도는 동안에만 켜진다. 세트 무대만 열어 둔 상태는 화면만 켜 둘 뿐 서비스를 켜지 않는다(`lib/timing_audio_mux.dart` 의 keepAlive). 알림을 누르면 앱이 열린다. Android 14+ 에서 사용자가 알림을 밀어 지워도 기록은 계속된다(알림만 숨는다).

## 정한 것과 근거

공식 문서가 직접 답하지 않는 두 가지를 아래처럼 정했다(2026-10-17). 반려되면 맨 아래 "반려되면" 대로 바꾼다.

### 1. `HIGH_SAMPLING_RATE_SENSORS` 를 둘 것인가

- 🟩 Android 문서(health 실행 조건): "At least one of the following conditions must be true: Declare the HIGH_SAMPLING_RATE_SENSORS permission in your manifest. Request and be granted at least one of the following runtime permissions: BODY_SENSORS on API 35 and lower / READ_HEART_RATE / READ_SKIN_TEMPERATURE / READ_OXYGEN_SATURATION / ACTIVITY_RECOGNITION" (https://developer.android.com/develop/background-work/services/fgs/service-types)
- 🟩 Android 문서(권한 자체, 2026-10-17 확인): "Allows an app to access sensor data with a sampling rate greater than 200 Hz. Protection level: normal" (https://developer.android.com/reference/android/Manifest.permission#HIGH_SAMPLING_RATE_SENSORS)
- 🟩 Play 권한 정책: "You may only request permissions and APIs that access sensitive information that are necessary to implement current features or services in your app that are promoted in your Google Play listing." (https://support.google.com/googleplay/android-developer/answer/9888170)
- 내가 2026-10-17 에 읽은 그 정책 페이지 본문에는 `HIGH_SAMPLING_RATE_SENSORS` 라는 말이 없다. 이 권한을 health 서비스 조건으로만 선언하는 것을 허용하거나 막는 Play 문장은 찾지 못했다.
- 🟦 **정함: 둔다.** Android 문서가 health 유형의 실행 조건으로 이 선언을 첫 번째 선택지로 적어 두었으므로 Google 이 정한 경로다. 위 설명의 마지막 문장으로 이유를 Play 에 밝힌다. 모든 사용자에게 성립하는 조건은 이것뿐이다. 앱은 이 권한으로 센서를 읽지 않는다 — 이 점이 위 정책 문장과 부딪힐 수 있다는 것이 남은 위험이다.
- 대안 (a): 매니페스트에서 빼고, 심박(`READ_HEART_RATE`)을 허용한 사용자에게만 health 서비스로 시작한다. 거절한 사용자는 서비스 없이 돈다 — 화면이 꺼지면 타이머 소리가 멈출 수 있고, Android 17 에서는 백그라운드 소리 자체가 막힌다(🟩 "must have a visible activity or must be running a foreground service that is not of type SHORT_SERVICE", https://developer.android.com/about/versions/17/changes/bg-audio). 타이머를 쓰려면 심박 권한을 줘야 하는 셈이 된다. 코드: `TimingService.launch` 앞의 권한 확인 + 매니페스트 한 줄.

### 2. health 하나인가, health + mediaPlayback 인가

- 🟩 Play 의 TYPE_HEALTH 용도: "Health Data Sync — Syncing of health data for apps in the fitness category, which can be across apps or to gather data collected through on-device tracking. For example, step counter, exercise tracker." 영상: "Show a user initiating a health data sync, such as counting steps or recording an active workout."
- 🟩 Play FAQ: "an exercise app that tracks a user’s exercise can declare the \"health\" foreground service type. You may also choose multiple foreground service types if applicable to your app." (https://support.google.com/googleplay/android-developer/answer/13392821)
- 🟩 Android 17 백그라운드 소리: "If you're not leveraging the media3 library, you will need to manually start a mediaPlayback FGS." 같은 페이지는 조건을 "a foreground service that is not of type SHORT_SERVICE" 로 적는다(https://developer.android.com/about/versions/17/changes/bg-audio).
- 사실: Android 의 이 서비스는 백그라운드에서 건강 데이터를 모으거나 동기화하지 않는다. 하는 일은 사용자가 시작한 운동 타이머의 구간 시간을 재고 신호음·박자 클릭·녹음 음성을 내는 것이다. 심박은 앱이 앞에 있을 때만 읽는다. 목표 없는 박자 run 은 사용자가 멈출 때까지 클릭이 이어진다.
- 위험: 심사자가 영상(클릭·음성이 나는 타바타·박자)을 보고 "Health Data Sync" 가 부정확하다고 볼 수 있다. 반대로 mediaPlayback 만으로는 소리 없는 긴 구간(세트 휴식, 박자 없는 타바타)이 "Continue audio or video playback" 에 맞지 않는다. 내가 읽은 Google 문서에는 타이머·메트로놈 예시가 어느 유형에도 없다.
- 🟦 **정함: health 하나.** Google 이 운동 앱에 직접 가리킨 유형이 health 이고, 한 유형이면 영상·설명도 하나다. 설명 문단은 "기록" 보다 백그라운드에서 실제로 하는 일(구간 시간 재기, 신호 내기)을 앞에 쓴다.
- 대안 (b): `foregroundServiceType="health|mediaPlayback"`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` 권한, `startForeground` 에 두 유형 비트. Play 선언은 유형마다 설명·영상을 따로 낸다(mediaPlayback 영상은 사용자가 박자 run 을 시작하고 홈에서 클릭·세는 말이 이어지는 장면).
- 반려되면: 반려 문장을 이 문서에 그대로 적고, 그 문장이 가리키는 쪽으로 (b) 또는 mediaPlayback 하나로 바꾼다. 코드 변경은 매니페스트 유형·권한과 `TimingService` 의 유형 상수뿐이다.

## 영상 찍기 (30초~1분, 실기기)

Google 은 TYPE_HEALTH 영상에 대해 "Show a user initiating a health data sync, such as counting steps or recording an active workout." 이라고 적었다. 그러니 **사용자가 운동 기록(타이머)을 직접 시작하는 장면**이 먼저 나와야 한다. 실제 Android 폰에서 화면 녹화(빠른 설정 → 화면 녹화, "미디어 소리 녹음" 켬)로 찍는다. 에뮬레이터는 소리가 없어 부적합하다. 기기 언어는 영어가 좋다(심사자가 알림 문구를 읽을 수 있게).

1. 녹화를 켜고 setpad 를 연다. 오늘 기록에 `Burpee tabata 20/10 x3 60bpm` 칸(한국어 기기면 `버피 타바타 20/10 x3 60bpm`)이 있는 것을 보여 준다.
2. [▶ Start] 를 누른다 — 사용자가 운동 기록을 시작하는 장면. 라운드·남은 시간이 움직이고 신호음·박자 클릭·라운드 음성이 나는 것을 몇 초 보여 준다(숫자 음성은 기본이 꺼짐이다 — 보여 주려면 녹화 전에 앱 설정의 'Count beats aloud' 를 켠다).
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
