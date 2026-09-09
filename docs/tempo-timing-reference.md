# Tempo의 클릭·음성 순서

참조한 앱은 외부 메트로놈 제품이 아니라 `/Users/ts/dev/healthopia`의 Tempo다.

`lib/1_application/timer/bpm_timer_controller.dart`의 `_startBpm`은 클릭을 먼저 재생하고, `min(60000 / bpm / 2, 1000)`밀리초 뒤 숫자를 재생한다. Tempo는 미리 녹음한 숫자 파일을 사용한다. Setpad는 기존 시스템 음성을 유지하면서 이 간격을 따른다.

- 60 BPM: 클릭 → 약 500ms → 숫자.
- 120 BPM: 클릭 → 약 250ms → 숫자.
- 느린 박자의 음성 대기 시간은 최대 1초.
- iOS는 오디오 재생 위치, Android는 playback head, 웹은 오디오 시계를 기준으로 대기 시간을 구한다.
- 준비·휴식 알림음이 남아 있으면 끝난 뒤 읽는다.
- 일시정지·구간 변경·백그라운드 전환 시 대기 중 음성을 취소한다.
- 빠른 BPM에서 이전 음성이 끝나지 않으면 새 음성을 쌓지 않는다. TTS가 다음 클릭까지 길어질 가능성은 있어, 녹음 파일을 사용하는 Tempo와 음성 길이·질감까지 같지는 않다.

검증: `flutter test test/workout_timing_test.dart`, `node --test test/timing_audio_web_test.js`. 자동 테스트는 명령 순서·반 박자 간격·취소를 확인하며, 실제 스피커와 Bluetooth 지연을 측정하는 청취 검증은 아니다.
