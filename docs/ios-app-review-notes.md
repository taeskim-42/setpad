# App Review 노트 (iOS) — audio 백그라운드 모드

## 한국어 요약 (사용자용)

- 아래 **영문 "Notes for Review"** 를 App Store Connect → 해당 버전 → App Review Information → Notes 에 그대로 붙인다. 근거: App Review Guidelines 2.3.1(a) "All new features, functionality, and product changes must be described with specificity in the Notes for Review section of App Store Connect (generic descriptions will be rejected)".
- 내용: 왜 `UIBackgroundModes` 에 `audio` 를 두는지(사용자가 켠 메트로놈 클릭과 녹음된 숫자·구간 음성을 잠금 화면에서도 들려 주기 위해), 심사자가 직접 확인하는 단계, 소리 없는 구간은 무음 재생으로 앱을 깨워 두지 않고 로컬 알림으로 알린다는 것.
- 붙이기 전에 실기기에서 아래 "Steps" 의 탭 순서가 지금 빌드와 같은지 한 번 확인한다(버튼 이름은 영어 UI 기준으로 적었다). 다르면 단계 문장만 고친다.
- `docs/timer-device-checklist.md` 1번(박자 run 잠금) 확인 영상을 같이 첨부하면 좋다(Guidelines "Before You Submit": "Include detailed explanations of non-obvious features ... including supporting documentation where appropriate").
- 이 문서는 App Store Connect 에 아무것도 올리지 않는다. 붙이는 것은 사용자가 한다.

---

## Notes for Review (paste as is)

```
Background audio (UIBackgroundModes: audio)

setpad is a workout log with a built-in workout timer. The user can turn an
exercise into a metronome (e.g. "Squat 60bpm") or an interval (Tabata) timer.
While the user runs one, the app plays audible content: a metronome click on
every beat and, if enabled, recorded spoken counts ("One, Two, Three...") and
recorded interval cues ("Round 2, go!", "Rest!"). People keep the phone on the
floor or in a pocket and lock it while training, so this sound must continue
on the lock screen. That is why the app declares the audio background mode.

The app only plays audio the user started, only while that timer runs, and
it mixes with music the user is playing (it does not stop other audio). It
never plays silent audio to stay awake: when a timer stops or the app is in
the background with nothing playing, it deactivates its audio session.

Silent intervals use local notifications instead: when the app goes to the
background during an interval timer, it schedules one local notification for
each upcoming interval start ("Rest", "Round 2", "Workout complete") with the
same recorded voice as its sound, and removes them when the user returns to
the app. Notification permission is requested before the first timer run,
not at launch. No Time Sensitive or Critical Alert entitlement is used.

Steps to verify the background audio:
1. Open setpad and open today's log.
2. Type the exercise "Squat 60bpm" as a new line. A timer card with a
   Start button appears under it.
3. Tap Start. Allow notifications when asked. After a 3-second count-in the
   metronome clicks once per second.
4. Lock the iPhone with the side button. The clicks continue on the lock
   screen.
5. (Optional) In Settings in the app, turn on "Count beats aloud", start
   again and lock: the recorded counts continue with the clicks.
6. Unlock and pause the timer (or hold End). The sound stops and the app no
   longer plays audio in the background.

Steps to verify the notifications for silent intervals:
1. Type "Burpee Tabata 20/10 x3" as a new line and tap Start.
2. Lock the iPhone during the first 20-second work interval.
3. When the 10-second rest begins, a notification "Rest" arrives with a
   recorded voice saying "Rest!"; then "Round 2", and so on until "Workout
   complete". (With the Ring/Silent switch on, notifications are silent, as
   on any app.)
```
