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

----


## Android

### android beta

```sh
[bundle exec] fastlane android beta
```

빌드해서 Play 내부 테스트로

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
