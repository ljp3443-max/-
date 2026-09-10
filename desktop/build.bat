@echo off
chcp 65001 >nul
title 축구 분석기 - exe 만들기
cd /d "%~dp0"

echo ============================================
echo  축구 분석기 - 바탕화면 앱(.exe) 만들기
echo ============================================
echo.

rem ---- 파이썬 찾기 ----
set "PY="
where py >nul 2>nul && set "PY=py"
if not defined PY where python >nul 2>nul && set "PY=python"
if not defined PY goto nopy

echo [1/4] 필요한 것 설치 (pywebview, pyinstaller)
%PY% -m pip install --upgrade pip >nul
%PY% -m pip install -r requirements.txt
if errorlevel 1 goto pipfail

echo.
echo [2/4] 화면 파일 만들기 (ui\index.html)
%PY% make_ui.py
if errorlevel 1 goto uifail

echo.
echo [3/4] 하나짜리 exe 로 묶기 - 1~3분 걸립니다
%PY% -m PyInstaller --noconfirm --clean ^
  --onefile --windowed ^
  --name "축구분석기" ^
  --add-data "ui;ui" ^
  --collect-all webview ^
  --collect-all clr_loader ^
  --hidden-import clr ^
  app.py
if errorlevel 1 goto buildfail

echo.
echo [4/4] 바탕화면으로 복사
rem OneDrive 를 쓰면 바탕화면이 OneDrive 안에 있습니다. 둘 다 봅니다.
set "DESK=%USERPROFILE%\Desktop"
if not exist "%DESK%" set "DESK=%USERPROFILE%\OneDrive\Desktop"
if not exist "%DESK%" set "DESK=%USERPROFILE%\OneDrive\바탕 화면"
if not exist "%DESK%" goto nodesk
copy /y "dist\축구분석기.exe" "%DESK%\축구분석기.exe" >nul
if errorlevel 1 goto nodesk
echo    바탕화면에 두었습니다: %DESK%\축구분석기.exe
goto copied
:nodesk
echo    바탕화면을 찾지 못했습니다. dist 폴더 안의 exe 를 직접 옮기세요.
:copied

echo.
echo  ----------------------------------------
echo   끝났습니다. 바탕화면의 아이콘을 더블클릭하세요.
echo   만들어진 위치: %cd%\dist\축구분석기.exe
echo  ----------------------------------------
goto end

:nopy
echo [오류] 이 PC 에서 파이썬을 찾지 못했습니다.
echo        https://www.python.org/downloads/ 에서 설치하고,
echo        설치 화면의 "Add Python to PATH" 를 꼭 체크하세요.
goto end

:pipfail
echo [오류] 설치가 실패했습니다. 인터넷 연결을 확인하세요.
goto end

:uifail
echo [오류] 화면 파일을 만들지 못했습니다.
echo        sports-ai-analyzer-v4.html 이 이 폴더의 위(..)에 있어야 합니다.
goto end

:buildfail
echo [오류] exe 로 묶는 중 실패했습니다. 위의 메시지를 확인하세요.
goto end

:end
echo.
pause
