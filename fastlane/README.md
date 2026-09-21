fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios setup

```sh
[bundle exec] fastlane ios setup
```

Apple Developer 포털에 App ID 를 등록한다 (한 번만)

### ios profile

```sh
[bundle exec] fastlane ios profile
```

배포 프로파일을 다시 만든다 (기능을 켠 뒤에 한 번)

### ios dev

```sh
[bundle exec] fastlane ios dev
```

기기 실행용 개발 프로파일

### ios dist

```sh
[bundle exec] fastlane ios dist
```

배포용 프로파일만 받아 둔다

### ios beta

```sh
[bundle exec] fastlane ios beta
```

빌드해서 TestFlight 로

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

등록 정보와 스크린샷을 올린다 (빌드는 안 만든다)

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

스크린샷만 올린다

### ios submit

```sh
[bundle exec] fastlane ios submit
```

TestFlight 에 올라간 빌드를 심사에 제출 (승인 시 자동 출시)

### ios review_state

```sh
[bundle exec] fastlane ios review_state
```

열려 있는 심사 제출을 보여 주고, CANCEL=1 이면 취소한다 (새 빌드로 바꿔 낼 때)

### ios release

```sh
[bundle exec] fastlane ios release
```

원커맨드 출시 — 등록정보·스크린샷 올리고 심사 제출

----


## Android

### android beta

```sh
[bundle exec] fastlane android beta
```

빌드해서 Play 내부 테스트로

### android metadata

```sh
[bundle exec] fastlane android metadata
```

스토어 등록정보(제목·설명)만 올린다. AAB·이미지는 안 건드린다

### android images

```sh
[bundle exec] fastlane android images
```

스크린샷·그래픽만 올린다. 문구·AAB 는 안 건드린다

### android production

```sh
[bundle exec] fastlane android production
```

프로덕션 트랙에 올린다 — 구글 심사 통과 시 자동 출시

### android promote

```sh
[bundle exec] fastlane android promote
```

내부 테스트의 최신 빌드를 운영으로 승급한다 (VALIDATE_ONLY=1 이면 Play 에 검증만 묻는다)

### android status

```sh
[bundle exec] fastlane android status
```

트랙별 현재 버전코드

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
