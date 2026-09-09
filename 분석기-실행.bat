@echo off
chcp 65001 >nul
title 축구 분석기 실행
cd /d "%~dp0"

echo ============================================
echo  축구 분석기 - 프록시와 함께 실행
echo ============================================
echo.

set RUNTIME=
where node >nul 2>nul
if %errorlevel%==0 if exist "fd-proxy.js" set RUNTIME=node
if defined RUNTIME goto found
where py >nul 2>nul
if %errorlevel%==0 if exist "fd-proxy.py" set RUNTIME=py
if defined RUNTIME goto found
where python >nul 2>nul
if %errorlevel%==0 if exist "fd-proxy.py" set RUNTIME=python
if defined RUNTIME goto found
goto noruntime

:found
echo [1/3] 프록시를 켭니다 ... (%RUNTIME%)
if "%RUNTIME%"=="node" start "fd-proxy" /min cmd /c node fd-proxy.js
if "%RUNTIME%"=="py" start "fd-proxy" /min cmd /c py fd-proxy.py
if "%RUNTIME%"=="python" start "fd-proxy" /min cmd /c python fd-proxy.py

echo [2/3] 준비될 때까지 잠시 기다립니다 ...
ping -n 4 127.0.0.1 >nul

echo [3/3] 분석기를 엽니다 ...
if not exist "sports-ai-analyzer-v4.html" goto nohtml
start "" "sports-ai-analyzer-v4.html"

echo.
echo  준비 완료.
echo  - 프록시는 최소화된 [fd-proxy] 창에서 돌고 있습니다.
echo  - 다 쓰신 뒤에는 그 창을 닫으면 프록시가 꺼집니다.
echo  - 확인: 브라우저에서 http://127.0.0.1:8787/__ping
echo.
goto end

:nohtml
echo.
echo [오류] sports-ai-analyzer-v4.html 을 찾지 못했습니다.
echo        이 파일을 분석기 HTML 과 같은 폴더에 두세요.
echo        지금 폴더: %cd%
goto end

:noruntime
echo [오류] 실행에 필요한 것을 찾지 못했습니다.
echo.
echo   - Node.js 가 있다면 fd-proxy.js 가 이 폴더에 있어야 합니다.
echo   - Python 이 있다면 fd-proxy.py 가 이 폴더에 있어야 합니다.
echo.
echo   지금 폴더: %cd%
echo   이 폴더의 파일 목록:
dir /b
echo.
echo   둘 다 없다면 프록시 없이 분석기만 열어도 됩니다.
echo   football-data.org 토큰 칸을 비워 두면 나머지 세 소스로 동작합니다.

:end
echo.
pause
