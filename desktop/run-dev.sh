#!/bin/sh
# 맥·리눅스에서 exe 없이 그냥 실행할 때.
cd "$(dirname "$0")" || exit 1
python3 -c 'import webview' 2>/dev/null || python3 -m pip install pywebview || exit 1
python3 make_ui.py || exit 1
exec python3 app.py
