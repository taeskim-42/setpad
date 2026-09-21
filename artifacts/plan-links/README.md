# 공동 루틴 초대 링크

- `ios-share-sheet-and-open-prompt.png` — iPhone 17e 시뮬레이터. 네이티브 채널(`setpad/share`)로 띄운 공유 시트에 초대 문구와 링크가 올라가 있다. 위의 확인창은 `setpad://plan/<토큰>` 을 열 때 iOS 가 묻는 것이다(웹 안내 화면의 "앱에서 열기" 가 이 주소를 부른다). 시뮬레이터에서는 이 버튼을 누를 수 없어 그 뒤는 확인하지 못했다.
- `android-link-opens-plans.png` — Android 에뮬레이터. `setpad://plan/<토큰>` 인텐트가 앱을 열어 공동 루틴 화면으로 간다. 로그인 전이라 로그인 안내가 뜨고, 토큰은 들고 있다가 로그인 뒤에 참여한다.

서버와의 참여 흐름(링크 발급 → 토큰 참여 → 재사용 거부 → 안내 화면)은 `integration/plan_server_test.dart` 가 격리된 실제 서버로 검증한다.
