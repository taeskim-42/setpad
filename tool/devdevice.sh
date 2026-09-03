#!/usr/bin/env bash
# setpad 를 **실기기에** 띄운다. 짐도조 로컬 서버가 없으면 같이 띄운다.
#
#   sdev                 # 어디서든. 붙어 있는 기기
#   sdev <device-id>
#   sdev --no-server     # 짐도조 서버는 건드리지 않는다
#
# 전역으로 부르려면 한 번만:
#
#   ln -sf ~/dev/setpad/tool/devdevice.sh ~/.local/bin/sdev
#
# **왜 스크립트가 필요한가.** setpad 자체는 서버가 없지만, 짐도조와 붙일 때
# 기기는 맥의 localhost 에 못 닿는다. 맥의 LAN 주소를 알아야 하고 그 주소는
# 망이 바뀔 때마다 달라진다 — 사람이 외울 값이 아니다. 지금은 API_BASE 를
# 넘기기만 하고 앱이 쓰지 않는다. 붙이는 날 이 스크립트는 그대로 둔다.
#
# 기기와 맥이 같은 와이파이에 있어야 한다.
set -euo pipefail

SELF=${BASH_SOURCE[0]}
while [ -L "$SELF" ]; do
  DIR=$(cd -P "$(dirname "$SELF")" && pwd)
  SELF=$(readlink "$SELF")
  [[ $SELF != /* ]] && SELF=$DIR/$SELF
done
APP=$(cd -P "$(dirname "$SELF")/.." && pwd)
cd "$APP"

SERVER=1; DEVICE=""
for a in "$@"; do
  case "$a" in
    --no-server) SERVER=0 ;;
    *) DEVICE=$a ;;
  esac
done

listening() { lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }

# 1. 짐도조 로컬 서버 — gdev 가 알아서 판단한다(떠 있으면 그대로 둔다).
if [ "$SERVER" = 1 ]; then
  if listening 3100; then
    echo "· 짐도조 이미 떠 있음 (3100)"
  elif command -v gdev >/dev/null 2>&1; then
    echo "· 짐도조 띄우는 중…"
    nohup gdev > /tmp/gymdojo-web.log 2>&1 &
    for _ in $(seq 1 60); do listening 3100 && break; sleep 1; done
    listening 3100 && echo "· 짐도조 떴다" || echo "  (안 떴다 — /tmp/gymdojo-web.log)"
  fi
fi

# 2. 기기에 띄우기
IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
[ -n "$IP" ] || { echo "맥의 LAN 주소를 못 찾았다 — 와이파이에 붙어 있나?" >&2; exit 1; }
echo "· 짐도조: http://$IP:3100  (로컬 — 운영 아님)"
echo "· setpad 를 기기에 띄운다"
exec flutter run --debug ${DEVICE:+-d "$DEVICE"} --dart-define=API_BASE="http://$IP:3100"
