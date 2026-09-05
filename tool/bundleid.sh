#!/usr/bin/env bash
# iOS 번들 ID 를 바꾼다.
#
#   tool/bundleid.sh com.tskim.workoutlog   # 기존 개발 프로파일로 되돌리기
#   tool/bundleid.sh com.taeskim.setpad     # Android 와 맞춘 정식 ID
#
# **왜 스크립트인가.** pbxproj 여러 곳과 fastlane Matchfile 이 같이 움직여야
# 하는데, 한 군데만 고치면 서명이 조용히 어긋난다. Android 의 applicationId 는
# 건드리지 않는다 — 그쪽은 이미 com.taeskim.setpad 이고 스토어 등록 전까지만
# 자유롭다.
set -euo pipefail
[ $# -eq 1 ] || { echo "쓰기: $0 <bundle-id>"; exit 1; }
NEW=$1
APP=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OLD=$(grep -m1 -oE 'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;' "$APP/ios/Runner.xcodeproj/project.pbxproj" \
      | sed -E 's/PRODUCT_BUNDLE_IDENTIFIER = (.*);/\1/' | sed 's/\.RunnerTests$//')
[ "$OLD" = "$NEW" ] && { echo "이미 $NEW 다"; exit 0; }
sed -i '' "s/$OLD/$NEW/g" "$APP/ios/Runner.xcodeproj/project.pbxproj"
sed -i '' "s/$OLD/$NEW/g" "$APP/fastlane/Matchfile"
echo "· iOS 번들 ID: $OLD → $NEW"
echo "· Android applicationId 는 그대로: $(grep -m1 -oE 'applicationId = "[^"]+"' "$APP/android/app/build.gradle.kts")"
