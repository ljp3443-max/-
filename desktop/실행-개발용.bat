@echo off
chcp 65001 >nul
title 축구 분석기 - 바로 실행 (exe 없이)
cd /d "%~dp0"

set "PY="
where py >nul 2>nul && set "PY=py"
if not defined PY where python >nul 2>nul && set "PY=python"
if not defined PY (
  echo [오류] 파이썬을 찾지 못했습니다. https://www.python.org/downloads/
  echo        설치할 때 "Add Python to PATH" 를 체크하세요.
  pause & exit /b 1
)

%PY% -c "import webview" 2>nul || (
  echo pywebview 를 설치합니다...
  %PY% -m pip install pywebview
)

echo 화면 파일 갱신...
%PY% make_ui.py

echo 앱을 띄웁니다.
%PY% app.py
pause
