#!/bin/zsh
# Real iOS Korean keyboard check for setpad's text inputs.
#
# Widget tests can only replay what we think the keyboard sends; this taps the simulator's
# actual 2-set software keyboard through XCUITest (no Mac focus is taken) and prints what
# each field ended up holding. It is how the 1.5.1 bug ("아메리카노" → "아아아메메메리리리카노")
# was reproduced and how the fix was checked (2026-10-07). Run it after touching any input.
#
#   tool/ime_check/run.sh                      # all scenarios against a fresh debug build
#   tool/ime_check/run.sh testSetpadBackspace  # some scenarios
#   API_BASE=http://127.0.0.1:3998 tool/ime_check/run.sh testSetpadJudge
#
# API_BASE defaults to an unreachable address so production is never touched; point it at a
# local gymdojo (scripts/e2e-server.mjs with UPSTAGE_API_KEY) to see the meal/exercise judge.
# Needs Xcode, an iOS simulator runtime and the xcodeproj gem (comes with CocoaPods).
# Uses its own simulator "setpad-ime" (Korean keyboard, hardware keyboard off) and a host
# project in $TMPDIR; your own simulators are not touched. IMERESULT lines are the output;
# screenshots go to $TMPDIR/setpad-ime/shots.
set -e
HERE=${0:A:h}
ROOT=${HERE:h:h}
WORK=${TMPDIR:-/tmp}/setpad-ime
HOST=$WORK/host
SHOTS=$WORK/shots
API_BASE=${API_BASE:-http://127.0.0.1:9}
TESTS=(${@:-testRepro testSetpadAfterFinish testSetpadBackspace testSetpadMemo testSetpadJudge testSetpadMealMode})
mkdir -p $WORK $SHOTS

# 1. The simulator: Korean first, software keyboard.
UDID=$(xcrun simctl list devices | sed -n 's/.*setpad-ime (\([0-9A-F-]*\)).*/\1/p' | head -1)
if [[ -z $UDID ]]; then
  RUNTIME=$(xcrun simctl list runtimes | sed -n 's/.*\(com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]*\).*/\1/p' | tail -1)
  UDID=$(xcrun simctl create setpad-ime com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro $RUNTIME)
  xcrun simctl boot $UDID
  xcrun simctl spawn $UDID defaults write -g AppleKeyboards -array 'ko_KR@sw=Korean;hw=Automatic' 'en_US@sw=QWERTY;hw=Automatic'
  xcrun simctl spawn $UDID defaults write -g AppleKeyboardsExpanded -int 1
  xcrun simctl spawn $UDID defaults write -g AppleLanguages -array ko-KR en-US
  xcrun simctl spawn $UDID defaults write -g AppleLocale -string ko_KR
  xcrun simctl spawn $UDID defaults write com.apple.Preferences KeyboardsCurrentAndNext -array 'ko_KR@sw=Korean;hw=Automatic' 'en_US@sw=QWERTY;hw=Automatic'
  # A fresh device shows the slide-to-type intro over the first keyboard and eats the taps.
  xcrun simctl spawn $UDID defaults write com.apple.keyboard.preferences DidShowContinuousPathIntroduction -bool true
  defaults write com.apple.iphonesimulator DevicePreferences -dict-add $UDID '<dict><key>ConnectHardwareKeyboard</key><false/></dict>'
  xcrun simctl shutdown $UDID
fi

# 2. The host project that carries the UI test bundle (setpad's own project stays untouched).
if [[ ! -d $HOST/ios/Runner.xcodeproj ]]; then
  (cd $WORK && flutter create --platforms ios --org dev.setpad --project-name ime_host host >/dev/null)
  mkdir -p $HOST/ios/ImeUITests
  ruby $HERE/add_ui_target.rb $HOST/ios/Runner.xcodeproj ImeUITests.swift
fi
cp $HERE/host_main.dart $HOST/lib/main.dart
cp $HERE/ImeUITests.swift $HOST/ios/ImeUITests/ImeUITests.swift
(cd $HOST && flutter build ios --simulator --debug >/dev/null)

# 3. setpad itself.
(cd $ROOT && flutter build ios --simulator --debug --dart-define=API_BASE=$API_BASE >/dev/null)
APP=$ROOT/build/ios/iphonesimulator/Runner.app

for T in $TESTS; do
  # xcodebuild may shut the simulator down after a run; boot and reinstall for a fresh app.
  xcrun simctl boot $UDID 2>/dev/null || true
  xcrun simctl bootstatus $UDID -b >/dev/null
  xcrun simctl uninstall $UDID com.tskim.workoutlog >/dev/null 2>&1 || true
  xcrun simctl install $UDID $APP
  echo "== $T"
  (cd $HOST/ios && TEST_RUNNER_SHOTS=$SHOTS xcodebuild test -project Runner.xcodeproj -scheme ImeUITests \
    -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath $WORK/dd -only-testing:ImeUITests/ImeUITests/$T 2>&1 \
    | grep -E 'IMERESULT [a-z]+[0-9]|IMERESULT out|error:|TEST (SUCCEEDED|FAILED)' | grep -v 'IMERESULT tree') || true
done
