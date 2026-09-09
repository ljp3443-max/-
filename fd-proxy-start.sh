#!/bin/sh
# macOS / Linux 용 실행기.  터미널에서:  sh fd-proxy-start.sh
cd "$(dirname "$0")" || exit 1
if command -v node >/dev/null 2>&1 && [ -f fd-proxy.js ]; then
  echo "Node.js 로 실행합니다. 끄려면 Ctrl+C."; exec node fd-proxy.js
fi
if command -v python3 >/dev/null 2>&1 && [ -f fd-proxy.py ]; then
  echo "Python 으로 실행합니다. 끄려면 Ctrl+C."; exec python3 fd-proxy.py
fi
echo "[오류] Node.js 와 Python 을 둘 다 찾지 못했습니다."
echo "       둘 중 하나를 설치하거나, football-data.org 없이 사용하세요."
