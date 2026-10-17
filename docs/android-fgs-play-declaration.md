# Play Console — 포그라운드 서비스 권한 선언 (Android 1.8.0~)

1.8.0 부터 Android 앱은 타이머가 도는 동안 포그라운드 서비스(`TimingService`, 유형 `mediaPlayback`)를 띄운다. 화면을 끄거나 앱을 나가도 타바타·박자 신호음과 녹음 음성이 이어지게 하려는 것으로, iOS 의 백그라운드 오디오(keep-alive)와 짝이다. targetSdk 34 이상에서 이 권한을 쓰는 앱은 **다음 Play 출시 전에** 선언을 마쳐야 한다. 선언이 없으면 그 출시가 심사에서 막힌다.

## 어디서

Play Console → setpad → **앱 콘텐츠(App content)** → **포그라운드 서비스 권한(Foreground service permissions)** → 시작/관리.

## 무엇을 적나

| 칸 | 값 |
|---|---|
| 권한 | `FOREGROUND_SERVICE_MEDIA_PLAYBACK` |
| 기능 유형 | **Media playback** (미디어 재생) |
| 설명 (영문) | 아래 문단 |
| 동영상 링크 | 아래 "영상 찍기" 로 만든 YouTube(일부 공개) 또는 Google Drive 링크 |

설명(영문, 그대로 붙여 넣는다):

> setpad plays a workout timer's audio: interval cue tones, a metronome click and recorded spoken counts and phrases ("Round 2, go!", "Rest!", "One, two, three…") during Tabata/interval runs, metronome runs and rest between sets. The user starts the timer and expects it to keep sounding when the screen turns off or the phone goes in a pocket mid-workout. The foreground service runs only while a timer is running (the user can pause or stop it at any time, and it stops when the run ends), shows an ongoing notification "Workout timer running", and is never started for any other purpose. Without it Android freezes the app in the background and the cues stop mid-workout.

서비스는 소리를 내는 타이머(운동 타이머 run, 세트 사이 휴식)가 도는 동안에만 켜진다. 세트 무대만 열어 둔 상태는 화면만 켜 둘 뿐 서비스를 켜지 않는다(`lib/timing_audio_mux.dart` 의 keepAlive).

사용자 영향 질문이 나오면: 사용자가 직접 시작한 타이머이고, 멈추거나 끝나면 서비스도 즉시 내려간다(마지막 신호음과 음성을 위해 최대 6초 더 유지). 알림을 누르면 앱이 열린다.

## 영상 찍기 (30초~1분, 실기기)

Google 은 기능이 실제로 어떻게 쓰이는지 보여 주는 짧은 영상을 요구한다. 실제 Android 폰에서 화면 녹화(빠른 설정 → 화면 녹화, **"미디어 소리 녹음" 켬**)로 찍는다. 에뮬레이터는 소리가 없어 부적합하다.

1. 녹화를 켜고 setpad 를 연다. 오늘 기록에 `버피 타바타 20/10 x3 60bpm` 칸을 두고 [▶ 시작].
2. 클릭·숫자 음성이 나는 것을 몇 초 보여 준다.
3. 홈으로 나가거나 알림 창을 내려 **"운동 타이머가 돌고 있어요" 알림**이 떠 있는 것을 보여 준다(영문 기기면 "Workout timer running").
4. 앱 밖(홈 화면)에서 신호음·음성이 계속 나는 것을 몇 초 들려 준다. 화면을 끄는 장면은 녹화에 안 담기므로 홈 화면에서 소리가 이어지는 것으로 보여 준다.
5. 알림을 눌러 앱으로 돌아온다 — 타이머가 같은 자리에서 돌고 있다.
6. [멈춤] 또는 끝까지 둔다 → 알림이 사라지는 것을 보여 준다.

YouTube 에 **일부 공개(Unlisted)** 로 올리고 링크를 선언에 넣는다.

## 바뀌면

- 서비스 유형을 바꾸거나(`AndroidManifest.xml` 의 `foregroundServiceType`) 다른 목적에 서비스를 쓰게 되면 이 선언을 다시 고친다.
- 반려되면: 반려 사유를 이 문서에 적는다. 서비스를 빼면(`TimingBridge.kt` 의 `TimingService.start/stop` 두 줄과 매니페스트의 `<service>`·권한 셋) 화면이 꺼진 동안 Android 타이머가 멈출 수 있고, 돌아오면 숫자가 제자리를 찾는다(놓친 신호는 울리지 않는다).
