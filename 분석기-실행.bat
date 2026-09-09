@echo off
chcp 65001 >nul
title 축구 분석기 실행
cd /d "%~dp0"

echo ============================================
echo  축구 분석기 - 프록시와 함께 실행
echo ============================================
echo.

rem ---- 프록시 스크립트 찾기 (이름이 조금 달라도 찾습니다) ----
set PROXYJS=
set PROXYPY=
if exist "fd-proxy.js" set PROXYJS=fd-proxy.js
if not defined PROXYJS for /f "delims=" %%F in ('dir /b /o-d fd-proxy*.js 2^>nul') do if not defined PROXYJS set PROXYJS=%%F
if exist "fd-proxy.py" set PROXYPY=fd-proxy.py
if not defined PROXYPY for /f "delims=" %%F in ('dir /b /o-d fd-proxy*.py 2^>nul') do if not defined PROXYPY set PROXYPY=%%F

rem ---- 분석기 HTML 찾기 (다운로드 중복으로 (1) 이 붙어도 찾습니다) ----
set HTMLFILE=
if exist "sports-ai-analyzer-v4.html" set HTMLFILE=sports-ai-analyzer-v4.html
if not defined HTMLFILE for /f "delims=" %%F in ('dir /b /o-d *analyzer*.html 2^>nul') do if not defined HTMLFILE set HTMLFILE=%%F

rem ---- 무엇으로 프록시를 띄울지 정하기 ----
set RUNTIME=
if defined PROXYJS where node >nul 2>nul && set RUNTIME=node
if not defined RUNTIME if defined PROXYPY where py >nul 2>nul && set RUNTIME=py
if not defined RUNTIME if defined PROXYPY where python >nul 2>nul && set RUNTIME=python
if not defined RUNTIME goto noruntime

echo [1/3] 프록시를 켭니다  (%RUNTIME%)
if "%RUNTIME%"=="node" start "fd-proxy" /min cmd /c node "%PROXYJS%"
if "%RUNTIME%"=="py" start "fd-proxy" /min cmd /c py "%PROXYPY%"
if "%RUNTIME%"=="python" start "fd-proxy" /min cmd /c python "%PROXYPY%"

echo [2/3] 준비될 때까지 3초 기다립니다
ping -n 4 127.0.0.1 >nul

if not defined HTMLFILE goto nohtml
echo [3/3] 분석기를 엽니다  (%HTMLFILE%)
start "" "%HTMLFILE%"

echo.
echo  ----------------------------------------
echo   준비가 끝났습니다.
echo.
echo   * 프록시는 [fd-proxy] 라는 최소화된 창에서 돌고 있습니다.
echo     작업표시줄에서 볼 수 있고, 그 창을 닫으면 프록시가 꺼집니다.
echo.
echo   * 분석기에서 프록시 주소는 입력하지 않아도 됩니다.
echo     앱이 알아서 찾아 채웁니다.
echo.
echo   * 잘 됐는지 보려면 브라우저 주소창에:
echo       http://127.0.0.1:8787/__ping
echo  ----------------------------------------
goto end

:nohtml
echo.
echo [오류] 분석기 HTML 파일을 찾지 못했습니다.
echo        sports-ai-analyzer-v4.html 을 이 폴더에 함께 두세요.
echo.
echo        지금 폴더: %cd%
echo        이 폴더에 있는 파일:
dir /b
goto end

:noruntime
echo.
echo [오류] 프록시를 띄울 수 없습니다.
echo.
if not defined PROXYJS if not defined PROXYPY echo   - fd-proxy.js 또는 fd-proxy.py 가 이 폴더에 없습니다.
if defined PROXYJS echo   - fd-proxy.js 는 있는데 Node.js 를 찾지 못했습니다.
if defined PROXYPY echo   - fd-proxy.py 는 있는데 Python 을 찾지 못했습니다.
echo.
echo        지금 폴더: %cd%
echo        이 폴더에 있는 파일:
dir /b
echo.
echo   프록시 없이 분석기만 쓰셔도 됩니다.
echo   football-data.org 토큰 칸을 비워 두면 나머지 세 소스로 정상 동작합니다.
if defined HTMLFILE echo.
if defined HTMLFILE echo   분석기만 열려면 아무 키나 누르세요.
if defined HTMLFILE pause >nul
if defined HTMLFILE start "" "%HTMLFILE%"

:end
echo.
pause
