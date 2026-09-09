@echo off
chcp 65001 >nul
title football-data.org 프록시
cd /d "%~dp0"

echo ============================================
echo  football-data.org 로컬 프록시
echo ============================================
echo.

if not exist "fd-proxy.js" if not exist "fd-proxy.py" goto nofile

where node >nul 2>nul
if %errorlevel%==0 goto usenode
where py >nul 2>nul
if %errorlevel%==0 goto usepy
where python >nul 2>nul
if %errorlevel%==0 goto usepython
goto noruntime

:usenode
if not exist "fd-proxy.js" goto usepy2
echo Node.js 를 찾았습니다. fd-proxy.js 로 실행합니다.
echo 이 창을 닫지 마세요. 끄려면 Ctrl+C.
echo.
node fd-proxy.js
goto end

:usepy2
where py >nul 2>nul
if %errorlevel%==0 goto usepy
goto usepython

:usepy
if not exist "fd-proxy.py" goto noruntime
echo Python 을 찾았습니다. fd-proxy.py 로 실행합니다.
echo 이 창을 닫지 마세요. 끄려면 Ctrl+C.
echo.
py fd-proxy.py
goto end

:usepython
if not exist "fd-proxy.py" goto noruntime
echo Python 을 찾았습니다. fd-proxy.py 로 실행합니다.
echo 이 창을 닫지 마세요. 끄려면 Ctrl+C.
echo.
python fd-proxy.py
goto end

:nofile
echo [오류] fd-proxy.js 와 fd-proxy.py 를 찾지 못했습니다.
echo        이 .bat 파일을 프록시 스크립트와 같은 폴더에 두세요.
echo        지금 폴더: %cd%
goto end

:noruntime
echo [오류] 이 PC에서 Node.js 와 Python 을 둘 다 찾지 못했습니다.
echo        프록시를 띄우려면 둘 중 하나가 필요합니다.
echo.
echo          Node.js : https://nodejs.org        (LTS 버전, 기본 설정으로 설치)
echo          Python  : https://www.python.org/downloads/
echo                    설치 화면에서 "Add python.exe to PATH" 를 반드시 체크
echo.
echo        설치 후 이 파일을 다시 더블클릭하세요.
echo.
echo        설치가 어려우면 football-data.org 없이도 분석기는 정상 동작합니다.
echo        분석기에서 football-data.org 토큰 칸을 비워 두면 나머지 세 소스로 분석합니다.

:end
echo.
echo ============================================
echo  프록시가 종료되었습니다. 창을 닫으셔도 됩니다.
echo ============================================
pause
