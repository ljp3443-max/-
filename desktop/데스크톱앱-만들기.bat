@echo off
chcp 65001 >nul
title 축구 분석기 - 바탕화면 앱 만들기
cd /d "%~dp0"

echo ================================================
echo   축구 분석기 - 바탕화면 앱 (HTML 화면 + 파이썬 엔진)
echo ================================================
echo.

rem ---------- 1) 파이썬 찾기 ----------
set "PY="
where py >nul 2>nul && set "PY=py"
if not defined PY where python >nul 2>nul && set "PY=python"
if not defined PY goto nopy
for /f "tokens=*" %%V in ('%PY% -c "import sys;print(sys.version.split()[0])" 2^>nul') do set "PYVER=%%V"
if not defined PYVER goto nopy
echo   파이썬 %PYVER% 을 찾았습니다.

rem ---------- 2) 분석기 HTML 찾기 ----------
set "HTMLFILE="
if exist "sports-ai-analyzer-v4.html" set "HTMLFILE=sports-ai-analyzer-v4.html"
if not defined HTMLFILE for /f "delims=" %%F in ('dir /b /o-d *analyzer*.html 2^>nul') do if not defined HTMLFILE set "HTMLFILE=%%F"
if not defined HTMLFILE goto nohtml
echo   화면 파일을 찾았습니다: %HTMLFILE%
echo.

rem ---------- 3) 프로그램 파일 꺼내기 ----------
echo [1/4] 프로그램 파일을 꺼냅니다
call :wr_app "%cd%\app.py"
call :wr_eng "%cd%\engine.py"
call :wr_brg "%cd%\bridge.js"
call :wr_mk "%cd%\make_ui.py"
call :wr_req "%cd%\requirements.txt"
call :wr_rdm "%cd%\README.md"
set "MISSING="
if not exist "app.py" set "MISSING=1"
if not exist "engine.py" set "MISSING=1"
if not exist "bridge.js" set "MISSING=1"
if not exist "make_ui.py" set "MISSING=1"
if not exist "requirements.txt" set "MISSING=1"
if not exist "README.md" set "MISSING=1"
if defined MISSING goto extractfail
echo        app.py
echo        engine.py
echo        bridge.js
echo        make_ui.py
echo        requirements.txt
echo        README.md
echo.

rem ---------- 4) 무엇을 할지 고르기 ----------
echo   [1] 지금 바로 실행해 보기      - 설치 30초쯤, 창이 바로 뜹니다
echo   [2] 바탕화면 exe 만들기        - 1~3분, 아이콘이 생깁니다
echo.
set "CHOICE="
set /p CHOICE=번호를 누르고 엔터(그냥 엔터면 1): 
if "%CHOICE%"=="2" goto buildexe
goto runnow

:runnow
echo.
echo [2/4] pywebview 설치 (이미 있으면 건너뜁니다)
%PY% -c "import webview" 2>nul || %PY% -m pip install pywebview
if errorlevel 1 goto pipfail
echo.
echo [3/4] 화면 파일 만들기
%PY% make_ui.py
if errorlevel 1 goto uifail
echo.
echo [4/4] 앱을 띄웁니다. 창을 닫으면 여기로 돌아옵니다.
%PY% app.py
goto end

:buildexe
echo.
echo [2/4] 필요한 것 설치 (pywebview, pyinstaller)
%PY% -m pip install -r requirements.txt
if errorlevel 1 goto pipfail
echo.
echo [3/4] 화면 파일 만들기
%PY% make_ui.py
if errorlevel 1 goto uifail
echo.
echo [4/4] exe 로 묶는 중 - 1~3분 걸립니다. 기다려 주세요.
%PY% -m PyInstaller --noconfirm --clean --onefile --windowed --name "축구분석기" --add-data "ui;ui" --collect-all webview --collect-all clr_loader --hidden-import clr app.py
if errorlevel 1 goto buildfail

rem OneDrive 를 쓰면 바탕화면이 OneDrive 안에 있습니다. 둘 다 봅니다.
set "DESK=%USERPROFILE%\Desktop"
if not exist "%DESK%" set "DESK=%USERPROFILE%\OneDrive\Desktop"
if not exist "%DESK%" set "DESK=%USERPROFILE%\OneDrive\바탕 화면"
if not exist "%DESK%" goto nodesk
copy /y "dist\축구분석기.exe" "%DESK%\축구분석기.exe" >nul
if errorlevel 1 goto nodesk
echo.
echo   바탕화면에 두었습니다: %DESK%\축구분석기.exe
goto builddone
:nodesk
echo.
echo   바탕화면을 찾지 못했습니다. 아래 파일을 직접 옮기세요:
echo     %cd%\dist\축구분석기.exe
:builddone
echo.
echo  ------------------------------------------------
echo   끝났습니다. 아이콘을 더블클릭하면 앱이 뜹니다.
echo   키를 한 번 입력하면 다음부터는 기억합니다.
echo  ------------------------------------------------
goto end

:nopy
echo.
echo [오류] 이 PC 에서 파이썬을 찾지 못했습니다.
echo.
echo        https://www.python.org/downloads/ 에서 받아 설치하세요.
echo        설치 첫 화면의 [Add Python to PATH] 를 반드시 체크해야 합니다.
echo        설치한 뒤 이 파일을 다시 더블클릭하면 됩니다.
goto end

:nohtml
echo.
echo [오류] 분석기 화면 파일(HTML)을 찾지 못했습니다.
echo.
echo        sports-ai-analyzer-v4.html 을 이 배치 파일과 같은 폴더에 두세요.
echo        이름 뒤에 (1) 이 붙어 있어도 괜찮습니다.
echo.
echo        지금 폴더: %cd%
echo        이 폴더에 있는 파일:
dir /b
goto end

:extractfail
echo.
echo [오류] 프로그램 파일을 꺼내지 못했습니다.
echo        이 폴더에 쓰기 권한이 없을 수 있습니다.
echo        바탕화면이나 문서 폴더에 새 폴더를 만들어 옮긴 뒤 다시 실행해 보세요.
goto end

:pipfail
echo.
echo [오류] 설치에 실패했습니다. 인터넷 연결을 확인하고 다시 실행해 보세요.
goto end

:uifail
echo.
echo [오류] 화면 파일을 만들지 못했습니다. 위의 메시지를 확인하세요.
goto end

:buildfail
echo.
echo [오류] exe 로 묶는 중 실패했습니다. 위의 메시지를 확인하세요.
echo        [1] 번(바로 실행)은 exe 없이도 잘 돌아갑니다.
goto end

:wr_app
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo IiIi7LaV6rWsIOu2hOyEneq4sCDigJQg67CU7YOV7ZmU66m0IOyVsS4KCu2ZlOuptOydgCB1aS9p
>>"%B64%" echo bmRleC5odG1sICjquLDsobQgSFRNTCDqt7jrjIDroZwpLCDsl5Tsp4TsnYAgZW5naW5lLnB5Lgrs
>>"%B64%" echo nbQg7YyM7J287J2AIOuRmOydhCDrtpnsl6wg7LC9IO2VmOuCmOuhnCDrnYTsmrDripQg7JaH7J2A
>>"%B64%" echo IOq7jeuNsOq4sOyeheuLiOuLpC4KCuqwnOuwnCDspJEg7Iuk7ZaJOiAgcHl0aG9uIGFwcC5weQpl
>>"%B64%" echo eGUg66GcIOustuq4sDogICBidWlsZC5iYXQKIiIiCgpmcm9tIF9fZnV0dXJlX18gaW1wb3J0IGFu
>>"%B64%" echo bm90YXRpb25zCgppbXBvcnQgb3MKaW1wb3J0IHN5cwppbXBvcnQgdGhyZWFkaW5nCmltcG9ydCB3
>>"%B64%" echo ZWJicm93c2VyCgppbXBvcnQgZW5naW5lCgojIHB5d2VidmlldyDripQg7LC97J2EIOudhOyauCDr
>>"%B64%" echo lYzsl5Drp4wg7ZWE7JqU7ZWp64uI64ukLiDsl4bri6Tqs6Ag7ZW07IScIGltcG9ydCDrp4zsnLzr
>>"%B64%" echo oZwg7KO97Jy866m0CiMg7JeU7KeE7J2EIOuUsOuhnCDsi5ztl5jtlbQg67O8IOyImCDsl4bsnLzr
>>"%B64%" echo r4DroZwsIOyXhuycvOuptCBOb25lIOycvOuhnCDrkZDqs6AgbWFpbigpIOyXkOyEnOunjCDrlLDs
>>"%B64%" echo p5Hri4jri6QuCnRyeToKICAgIGltcG9ydCB3ZWJ2aWV3ICAjIHB5d2VidmlldwpleGNlcHQgSW1w
>>"%B64%" echo b3J0RXJyb3I6CiAgICB3ZWJ2aWV3ID0gTm9uZQoKCmRlZiByZXNvdXJjZV9kaXIoKSAtPiBzdHI6
>>"%B64%" echo CiAgICAiIiLqsJzrsJwg7KSR7JeQ64qUIOydtCDtjIzsnbwg7JiGLCBleGUg66GcIOustuydgCDr
>>"%B64%" echo kqTsl5DripQg7ZKA66awIOyehOyLnCDtj7TrjZQuIiIiCiAgICByZXR1cm4gZ2V0YXR0cihzeXMs
>>"%B64%" echo ICJfTUVJUEFTUyIsIG9zLnBhdGguZGlybmFtZShvcy5wYXRoLmFic3BhdGgoX19maWxlX18pKSkK
>>"%B64%" echo CgpkZWYgdWlfcGF0aCgpIC0+IHN0cjoKICAgIHAgPSBvcy5wYXRoLmpvaW4ocmVzb3VyY2VfZGly
>>"%B64%" echo KCksICJ1aSIsICJpbmRleC5odG1sIikKICAgIGlmIG5vdCBvcy5wYXRoLmV4aXN0cyhwKToKICAg
>>"%B64%" echo ICAgICByYWlzZSBTeXN0ZW1FeGl0KGYi7ZmU66m0IO2MjOydvOydhCDssL7sp4Ag66q77ZaI7Iq1
>>"%B64%" echo 64uI64ukOiB7cH0iKQogICAgcmV0dXJuIHAKCgpjbGFzcyBBcGk6CiAgICAiIiLtmZTrqbTsl5Ds
>>"%B64%" echo hJwgd2luZG93LnB5d2Vidmlldy5hcGkuPOydtOumhD4oLi4uKSDsnLzroZwg67aA66W064qUIOqy
>>"%B64%" echo g+uTpC4KCiAgICDrj4zroKTso7zripQg6rCS7J2AIOyghOu2gCBKU09OIOycvOuhnCDsmKTqsIDr
>>"%B64%" echo r4DroZwgZGljdCAvIGxpc3QgLyDquLDrs7jtmJXrp4wg7JSB64uI64ukLgogICAg7JiI7Jm466W8
>>"%B64%" echo IOuwluycvOuhnCDrgrTrs7TrgrTsp4Ag7JWK7Iq164uI64ukIOKAlCDrjZjsp4DrqbQg7ZmU66m0
>>"%B64%" echo IOyqvSBQcm9taXNlIOqwgCDsobDsmqntnogg7KO97Iq164uI64ukLgogICAgIiIiCgogICAgZGVm
>>"%B64%" echo IF9faW5pdF9fKHNlbGYpIC0+IE5vbmU6CiAgICAgICAgc2VsZi53aW5kb3cgPSBOb25lCgogICAg
>>"%B64%" echo IyAtLS0tIOuwlOq5peyEuOyDgSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tCiAgICBkZWYgaHR0cF9nZXQoc2VsZiwgdXJsOiBzdHIsIGhlYWRlcnM6
>>"%B64%" echo IGRpY3QgfCBOb25lID0gTm9uZSkgLT4gZGljdDoKICAgICAgICB0cnk6CiAgICAgICAgICAgIHJl
>>"%B64%" echo dHVybiBlbmdpbmUuaHR0cF9nZXQodXJsLCBoZWFkZXJzIG9yIHt9KQogICAgICAgIGV4Y2VwdCBF
>>"%B64%" echo eGNlcHRpb24gYXMgZTogICAgICAgICAgICAgICAgICAgICAjIOyXrOq4sOyEnCDrp4nsp4Ag7JWK
>>"%B64%" echo 7Jy866m0IO2ZlOuptOydtCDrqYjstqXri4jri6QKICAgICAgICAgICAgZW5naW5lLmxvZyhmImh0
>>"%B64%" echo dHBfZ2V0IOyYiOyZuDoge2Uhcn0iKQogICAgICAgICAgICByZXR1cm4geyJvayI6IEZhbHNlLCAi
>>"%B64%" echo c3RhdHVzIjogMCwgImJvZHkiOiAiIiwgImVycm9yIjogc3RyKGUpfQoKICAgIGRlZiBwcm9iZShz
>>"%B64%" echo ZWxmLCBrZXlzOiBkaWN0IHwgTm9uZSA9IE5vbmUpIC0+IGRpY3Q6CiAgICAgICAgdHJ5OgogICAg
>>"%B64%" echo ICAgICAgICByZXR1cm4geyJvayI6IFRydWUsICJyZXN1bHRzIjogZW5naW5lLnByb2JlKGtleXMg
>>"%B64%" echo b3Ige30pfQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgZW5naW5l
>>"%B64%" echo LmxvZyhmInByb2JlIOyYiOyZuDoge2Uhcn0iKQogICAgICAgICAgICByZXR1cm4geyJvayI6IEZh
>>"%B64%" echo bHNlLCAiZXJyb3IiOiBzdHIoZSksICJyZXN1bHRzIjogW119CgogICAgIyAtLS0tIOuCtCBQQyAt
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAg
>>"%B64%" echo ICBkZWYgbG9hZF9rZXlzKHNlbGYpIC0+IGRpY3Q6CiAgICAgICAgdHJ5OgogICAgICAgICAgICBy
>>"%B64%" echo ZXR1cm4geyJvayI6IFRydWUsICJrZXlzIjogZW5naW5lLmxvYWRfa2V5cygpfQogICAgICAgIGV4
>>"%B64%" echo Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgcmV0dXJuIHsib2siOiBGYWxzZSwgImVy
>>"%B64%" echo cm9yIjogc3RyKGUpLCAia2V5cyI6IHt9fQoKICAgIGRlZiBzYXZlX2tleXMoc2VsZiwga2V5czog
>>"%B64%" echo ZGljdCB8IE5vbmUgPSBOb25lKSAtPiBkaWN0OgogICAgICAgIHRyeToKICAgICAgICAgICAgcmV0
>>"%B64%" echo dXJuIGVuZ2luZS5zYXZlX2tleXMoa2V5cyBvciB7fSkKICAgICAgICBleGNlcHQgRXhjZXB0aW9u
>>"%B64%" echo IGFzIGU6CiAgICAgICAgICAgIHJldHVybiB7Im9rIjogRmFsc2UsICJlcnJvciI6IHN0cihlKX0K
>>"%B64%" echo CiAgICBkZWYgZm9yZ2V0X2tleXMoc2VsZikgLT4gZGljdDoKICAgICAgICB0cnk6CiAgICAgICAg
>>"%B64%" echo ICAgIHJldHVybiBlbmdpbmUuZm9yZ2V0X2tleXMoKQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb24g
>>"%B64%" echo YXMgZToKICAgICAgICAgICAgcmV0dXJuIHsib2siOiBGYWxzZSwgImVycm9yIjogc3RyKGUpfQoK
>>"%B64%" echo ICAgIGRlZiBhcHBfaW5mbyhzZWxmKSAtPiBkaWN0OgogICAgICAgIHRyeToKICAgICAgICAgICAg
>>"%B64%" echo cmV0dXJuIGVuZ2luZS5hcHBfaW5mbygpCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgog
>>"%B64%" echo ICAgICAgICAgICByZXR1cm4geyJlcnJvciI6IHN0cihlKX0KCiAgICBkZWYgc2F2ZV90ZXh0KHNl
>>"%B64%" echo bGYsIGZpbGVuYW1lOiBzdHIsIHRleHQ6IHN0cikgLT4gZGljdDoKICAgICAgICAiIiLrhKTsnbTt
>>"%B64%" echo i7DruIwg7KCA7J6lIOuMgO2ZlOyDgeyekC4g67iM65287Jqw7KCA7J2YIOuLpOyatOuhnOuTnCDr
>>"%B64%" echo jIDsi6Ag7JSB64uI64ukLiIiIgogICAgICAgIHRyeToKICAgICAgICAgICAgaWYgd2VidmlldyBp
>>"%B64%" echo cyBOb25lOgogICAgICAgICAgICAgICAgcmV0dXJuIHsib2siOiBGYWxzZSwgImVycm9yIjogIuyw
>>"%B64%" echo veydtCDsl4bsirXri4jri6QgKHB5d2VidmlldyDrr7jshKTsuZgpIn0KICAgICAgICAgICAgd2lu
>>"%B64%" echo ID0gc2VsZi53aW5kb3cgb3IgKHdlYnZpZXcud2luZG93c1swXSBpZiB3ZWJ2aWV3LndpbmRvd3Mg
>>"%B64%" echo ZWxzZSBOb25lKQogICAgICAgICAgICBpZiB3aW4gaXMgTm9uZToKICAgICAgICAgICAgICAgIHJl
>>"%B64%" echo dHVybiB7Im9rIjogRmFsc2UsICJlcnJvciI6ICLssL3snYQg7LC+7KeAIOuqu+2WiOyKteuLiOuL
>>"%B64%" echo pCJ9CiAgICAgICAgICAgIHBpY2tlZCA9IHdpbi5jcmVhdGVfZmlsZV9kaWFsb2coCiAgICAgICAg
>>"%B64%" echo ICAgICAgICB3ZWJ2aWV3LlNBVkVfRElBTE9HLCBzYXZlX2ZpbGVuYW1lPWZpbGVuYW1lIG9yICJi
>>"%B64%" echo cmllZmluZy50eHQiKQogICAgICAgICAgICBpZiBub3QgcGlja2VkOgogICAgICAgICAgICAgICAg
>>"%B64%" echo cmV0dXJuIHsib2siOiBGYWxzZSwgImNhbmNlbGxlZCI6IFRydWV9CiAgICAgICAgICAgIHBhdGgg
>>"%B64%" echo PSBwaWNrZWQgaWYgaXNpbnN0YW5jZShwaWNrZWQsIHN0cikgZWxzZSBwaWNrZWRbMF0KICAgICAg
>>"%B64%" echo ICAgICAgd2l0aCBvcGVuKHBhdGgsICJ3IiwgZW5jb2Rpbmc9InV0Zi04IikgYXMgZjoKICAgICAg
>>"%B64%" echo ICAgICAgICAgIGYud3JpdGUodGV4dCBvciAiIikKICAgICAgICAgICAgZW5naW5lLmxvZyhmIu2M
>>"%B64%" echo jOydvCDsoIDsnqUg4oCUIHtwYXRofSIpCiAgICAgICAgICAgIHJldHVybiB7Im9rIjogVHJ1ZSwg
>>"%B64%" echo InBhdGgiOiBwYXRofQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAg
>>"%B64%" echo ZW5naW5lLmxvZyhmInNhdmVfdGV4dCDsmIjsmbg6IHtlIXJ9IikKICAgICAgICAgICAgcmV0dXJu
>>"%B64%" echo IHsib2siOiBGYWxzZSwgImVycm9yIjogc3RyKGUpfQoKICAgIGRlZiBvcGVuX2xvZyhzZWxmKSAt
>>"%B64%" echo PiBkaWN0OgogICAgICAgIHRyeToKICAgICAgICAgICAgcGF0aCA9IGVuZ2luZS5MT0dfUEFUSCgp
>>"%B64%" echo CiAgICAgICAgICAgIGlmIG5vdCBvcy5wYXRoLmV4aXN0cyhwYXRoKToKICAgICAgICAgICAgICAg
>>"%B64%" echo IG9wZW4ocGF0aCwgImEiLCBlbmNvZGluZz0idXRmLTgiKS5jbG9zZSgpCiAgICAgICAgICAgIHdl
>>"%B64%" echo YmJyb3dzZXIub3BlbigiZmlsZTovLyIgKyBwYXRoKQogICAgICAgICAgICByZXR1cm4geyJvayI6
>>"%B64%" echo IFRydWUsICJwYXRoIjogcGF0aH0KICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAg
>>"%B64%" echo ICAgICAgIHJldHVybiB7Im9rIjogRmFsc2UsICJlcnJvciI6IHN0cihlKX0KCiAgICBkZWYgb3Bl
>>"%B64%" echo bl9leHRlcm5hbChzZWxmLCB1cmw6IHN0cikgLT4gZGljdDoKICAgICAgICAiIiLrsJTquaUg66eB
>>"%B64%" echo 7YGs64qUIOyVsSDssL3snbQg7JWE64uI6528IOq4sOuzuCDruIzrnbzsmrDsoIDsl5DshJwg7Je9
>>"%B64%" echo 64uI64ukLiIiIgogICAgICAgIHRyeToKICAgICAgICAgICAgaWYgbm90IHN0cih1cmwpLmxvd2Vy
>>"%B64%" echo KCkuc3RhcnRzd2l0aCgoImh0dHA6Ly8iLCAiaHR0cHM6Ly8iKSk6CiAgICAgICAgICAgICAgICBy
>>"%B64%" echo ZXR1cm4geyJvayI6IEZhbHNlLCAiZXJyb3IiOiAiaHR0cChzKSDso7zshozrp4wg7Je964uI64uk
>>"%B64%" echo In0KICAgICAgICAgICAgd2ViYnJvd3Nlci5vcGVuKHVybCkKICAgICAgICAgICAgcmV0dXJuIHsi
>>"%B64%" echo b2siOiBUcnVlfQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgcmV0
>>"%B64%" echo dXJuIHsib2siOiBGYWxzZSwgImVycm9yIjogc3RyKGUpfQoKCmRlZiBtYWluKCkgLT4gTm9uZToK
>>"%B64%" echo ICAgIGlmIHdlYnZpZXcgaXMgTm9uZToKICAgICAgICBwcmludCgicHl3ZWJ2aWV3IOqwgCDsl4bs
>>"%B64%" echo irXri4jri6QuIOuovOyggCDshKTsuZjtlZjshLjsmpQ6XG5cbiAgICBwaXAgaW5zdGFsbCBweXdl
>>"%B64%" echo YnZpZXdcbiIpCiAgICAgICAgcmFpc2UgU3lzdGVtRXhpdCgxKQoKICAgIGVuZ2luZS5sb2coIj0i
>>"%B64%" echo ICogNTIpCiAgICBlbmdpbmUubG9nKGYi7LaV6rWsIOu2hOyEneq4sCDrjbDsiqTtgazthrEg7Iuc
>>"%B64%" echo 7J6RIOKAlCB7ZW5naW5lLmFwcF9pbmZvKCl9IikKCiAgICBhcGkgPSBBcGkoKQogICAgd2luZG93
>>"%B64%" echo ID0gd2Vidmlldy5jcmVhdGVfd2luZG93KAogICAgICAgICJVTFRJTUFURSBTUE9SVFMgQUkgQU5B
>>"%B64%" echo TFlaRVIgdjQiLAogICAgICAgIHVybD11aV9wYXRoKCksCiAgICAgICAganNfYXBpPWFwaSwKICAg
>>"%B64%" echo ICAgICB3aWR0aD0xNDgwLCBoZWlnaHQ9MTAwMCwKICAgICAgICBtaW5fc2l6ZT0oMTEwMCwgNzIw
>>"%B64%" echo KSwKICAgICAgICBiYWNrZ3JvdW5kX2NvbG9yPSIjMDYwZDE4IiwKICAgICAgICB0ZXh0X3NlbGVj
>>"%B64%" echo dD1UcnVlLAogICAgKQogICAgYXBpLndpbmRvdyA9IHdpbmRvdwogICAgIyBndWkg66W8IOyngOyg
>>"%B64%" echo le2VmOyngCDslYrsnLzrqbQgcHl3ZWJ2aWV3IOqwgCDslYzslYTshJwg6rOg66aF64uI64ukCiAg
>>"%B64%" echo ICAjICjsnIjrj4TsmrA6IEVkZ2UgV2ViVmlldzIsIOunpTogV2ViS2l0LCDrpqzriIXsiqQ6IEdU
>>"%B64%" echo Sy9RdCkuCiAgICB3ZWJ2aWV3LnN0YXJ0KGRlYnVnPWJvb2wob3MuZW52aXJvbi5nZXQoIlVTQUlf
>>"%B64%" echo REVCVUciKSkpCiAgICBlbmdpbmUubG9nKCLsooXro4wiKQoKCmlmIF9fbmFtZV9fID09ICJfX21h
>>"%B64%" echo aW5fXyI6CiAgICBtYWluKCkK
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:wr_eng
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo IiIi7LaV6rWsIOu2hOyEneq4sCDrjbDsiqTtgazthrEg7JWx7J2YIOyXlOynhC4KCu2ZlOuptChI
>>"%B64%" echo VE1MKeydgCDqt7jrpqzquLDrp4wg7ZWY6rOgLCDrsJTquaXshLjsg4Hqs7wg7J207JW86riw7ZWY
>>"%B64%" echo 64qUIOydvOydgCDsoITrtoAg7Jes6riw7IScIO2VqeuLiOuLpC4K7ZGc7KSAIOudvOydtOu4jOuf
>>"%B64%" echo rOumrOunjCDslIHri4jri6Qg4oCUIHBpcCDroZwg65Sw66GcIOuwm+ydhCDqsoPsnbQg7JeG6rOg
>>"%B64%" echo LCBQeUluc3RhbGxlciDroZwg66y27Ja064+ECuyaqeufieydtCDtgazqsowg64qY7KeAIOyViuyK
>>"%B64%" echo teuLiOuLpC4KCuyXrOq4sOyEnCDtlZjripQg7J28CiAgKiDrhKQg6rOz7J2YIOy2leq1rCBBUEkg
>>"%B64%" echo 7Zi47LacICjsnqzsi5zrj4Qgwrcg7YOA7J6E7JWE7JuDIMK3IO2YuOyKpO2KuOuzhCDsho3rj4Qg
>>"%B64%" echo 7KCc7ZWcKQogICog6rCBIO2CpOulvCDqt7gg7YKk6rCAIOyGje2VnCDqs7Psl5Drp4wg67O064K0
>>"%B64%" echo 6riwCiAgKiDtgqTrpbwg64K0IFBDIOyViOyXkCDsoIDsnqUgKO2MjOydvCDqtoztlZwgMDYwMCkK
>>"%B64%" echo ICAqIOyGjOyKpOuzhCDsl7DqsrAg7KeE64uoCiAgKiDrrLTsiqgg7J287J20IOyeiOyXiOuKlOyn
>>"%B64%" echo gCDroZzqt7gg64Ko6riw6riwCgrruIzrnbzsmrDsoIDqsIAg7JWE64uI66+A66GcIENPUlMg6528
>>"%B64%" echo 64qUIOqyg+ydtCDslYTsmIgg7JeG7Iq164uI64ukLiDtlITroZ3si5zrj4Qg7ZWE7JqUIOyXhuyK
>>"%B64%" echo teuLiOuLpC4KIiIiCgpmcm9tIF9fZnV0dXJlX18gaW1wb3J0IGFubm90YXRpb25zCgppbXBvcnQg
>>"%B64%" echo anNvbgppbXBvcnQgb3MKaW1wb3J0IHNzbAppbXBvcnQgc3lzCmltcG9ydCB0aHJlYWRpbmcKaW1w
>>"%B64%" echo b3J0IHRpbWUKaW1wb3J0IHVybGxpYi5lcnJvcgppbXBvcnQgdXJsbGliLnBhcnNlCmltcG9ydCB1
>>"%B64%" echo cmxsaWIucmVxdWVzdAoKQVBQX05BTUUgPSAiU3BvcnRzQUlBbmFseXplciIKVkVSU0lPTiA9ICI0
>>"%B64%" echo LjAtZGVza3RvcCIKVVNFUl9BR0VOVCA9IGYie0FQUF9OQU1FfS97VkVSU0lPTn0gKCtsb2NhbCBk
>>"%B64%" echo ZXNrdG9wIGFwcCkiCgojIOydtCDslbHsnbQg66eQ7J2EIOqxuOyWtOuPhCDrkJjripQg6rOzLiDs
>>"%B64%" echo l6zquLAg7JeG64qUIOyjvOyGjOuKlCDslYTsmIgg67aA66W07KeAIOyViuyKteuLiOuLpC4KIyDt
>>"%B64%" echo mZTrqbQg7Kq9IOy9lOuTnOqwgCDslrTrlqQg7J207Jyg66Gc65OgIOyXieuase2VnCDso7zshozr
>>"%B64%" echo pbwg64SY6rKo64+EIO2CpOqwgCDsg4gg64KY6rCA7KeAIOyViuyKteuLiOuLpC4KQUxMT1dFRF9I
>>"%B64%" echo T1NUUyA9IHsKICAgICJ2My5mb290YmFsbC5hcGktc3BvcnRzLmlvIiwKICAgICJhcGkuZm9vdGJh
>>"%B64%" echo bGwtZGF0YS5vcmciLAogICAgImFwaS5vcGVubGlnYWRiLmRlIiwKICAgICJ3d3cudGhlc3BvcnRz
>>"%B64%" echo ZGIuY29tIiwKICAgICJ0aGVzcG9ydHNkYi5jb20iLAp9CgojIO2XpOuNlCDsnbTrpoQgLT4g6re4
>>"%B64%" echo IO2XpOuNlOulvCDrsJvslYTrj4Qg65CY64qUIO2YuOyKpO2KuC4KIyBmb290YmFsbC1kYXRhLm9y
>>"%B64%" echo ZyDthqDtgbDsnbQgVGhlU3BvcnRzREIg66GcIOqwgOuKlCDsnbwg65Sw7JyE6rCAIOyDneq4sOyn
>>"%B64%" echo gCDslYrqsowg7ZWp64uI64ukLgpIRUFERVJfSE9NRSA9IHsKICAgICJ4LWF1dGgtdG9rZW4iOiB7
>>"%B64%" echo ImFwaS5mb290YmFsbC1kYXRhLm9yZyJ9LAogICAgIngtYXBpc3BvcnRzLWtleSI6IHsidjMuZm9v
>>"%B64%" echo dGJhbGwuYXBpLXNwb3J0cy5pbyJ9LAogICAgIngtcmFwaWRhcGkta2V5IjogeyJ2My5mb290YmFs
>>"%B64%" echo bC5hcGktc3BvcnRzLmlvIn0sCn0KCiMg66y066OMIOuTseq4iSDquLDspIDsnLzroZwg7J6h7J2A
>>"%B64%" echo IO2YuOyKpO2KuOuzhCDstZzshowg7Zi47LacIOqwhOqyqSjstIgpLgpNSU5fSU5URVJWQUwgPSB7
>>"%B64%" echo CiAgICAiYXBpLmZvb3RiYWxsLWRhdGEub3JnIjogNi41LCAgICMg67aE64u5IDEw7ZqMCiAgICAi
>>"%B64%" echo djMuZm9vdGJhbGwuYXBpLXNwb3J0cy5pbyI6IDAuNCwKICAgICJhcGkub3BlbmxpZ2FkYi5kZSI6
>>"%B64%" echo IDAuMiwKICAgICJ3d3cudGhlc3BvcnRzZGIuY29tIjogMS4yLAogICAgInRoZXNwb3J0c2RiLmNv
>>"%B64%" echo bSI6IDEuMiwKfQoKVElNRU9VVCA9IDIwCk1BWF9SRVRSWSA9IDMKUkVUUllfU1RBVFVTID0gezQw
>>"%B64%" echo OCwgNDI1LCA0MjksIDUwMCwgNTAyLCA1MDMsIDUwNH0KCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0g7KCA7J6lIOychOy5
>>"%B64%" echo mAoKZGVmIGRhdGFfZGlyKCkgLT4gc3RyOgogICAgaWYgc3lzLnBsYXRmb3JtLnN0YXJ0c3dpdGgo
>>"%B64%" echo IndpbiIpOgogICAgICAgIGJhc2UgPSBvcy5lbnZpcm9uLmdldCgiQVBQREFUQSIpIG9yIG9zLnBh
>>"%B64%" echo dGguZXhwYW5kdXNlcigifiIpCiAgICBlbGlmIHN5cy5wbGF0Zm9ybSA9PSAiZGFyd2luIjoKICAg
>>"%B64%" echo ICAgICBiYXNlID0gb3MucGF0aC5leHBhbmR1c2VyKCJ+L0xpYnJhcnkvQXBwbGljYXRpb24gU3Vw
>>"%B64%" echo cG9ydCIpCiAgICBlbHNlOgogICAgICAgIGJhc2UgPSBvcy5lbnZpcm9uLmdldCgiWERHX0NPTkZJ
>>"%B64%" echo R19IT01FIikgb3Igb3MucGF0aC5leHBhbmR1c2VyKCJ+Ly5jb25maWciKQogICAgZCA9IG9zLnBh
>>"%B64%" echo dGguam9pbihiYXNlLCBBUFBfTkFNRSkKICAgIG9zLm1ha2VkaXJzKGQsIGV4aXN0X29rPVRydWUp
>>"%B64%" echo CiAgICByZXR1cm4gZAoKCktFWVNfUEFUSCA9IGxhbWJkYTogb3MucGF0aC5qb2luKGRhdGFfZGly
>>"%B64%" echo KCksICJrZXlzLmpzb24iKQpMT0dfUEFUSCA9IGxhbWJkYTogb3MucGF0aC5qb2luKGRhdGFfZGly
>>"%B64%" echo KCksICJhcHAubG9nIikKCgpkZWYgbG9nKG1zZzogc3RyKSAtPiBOb25lOgogICAgbGluZSA9IGYi
>>"%B64%" echo e3RpbWUuc3RyZnRpbWUoJyVZLSVtLSVkICVIOiVNOiVTJyl9ICB7bXNnfVxuIgogICAgdHJ5Ogog
>>"%B64%" echo ICAgICAgIHAgPSBMT0dfUEFUSCgpCiAgICAgICAgIyDroZzqt7jqsIAg66y07ZWc7Z6IIOyekOud
>>"%B64%" echo vOyngCDslYrrj4TroZ0gMU1CIOulvCDrhJjsnLzrqbQg7JWe67aA67aE7J2EIOuyhOumveuLiOuL
>>"%B64%" echo pC4KICAgICAgICBpZiBvcy5wYXRoLmV4aXN0cyhwKSBhbmQgb3MucGF0aC5nZXRzaXplKHApID4g
>>"%B64%" echo MV8wMDBfMDAwOgogICAgICAgICAgICB3aXRoIG9wZW4ocCwgInIiLCBlbmNvZGluZz0idXRmLTgi
>>"%B64%" echo LCBlcnJvcnM9InJlcGxhY2UiKSBhcyBmOgogICAgICAgICAgICAgICAgdGFpbCA9IGYucmVhZCgp
>>"%B64%" echo Wy0yMDBfMDAwOl0KICAgICAgICAgICAgd2l0aCBvcGVuKHAsICJ3IiwgZW5jb2Rpbmc9InV0Zi04
>>"%B64%" echo IikgYXMgZjoKICAgICAgICAgICAgICAgIGYud3JpdGUodGFpbCkKICAgICAgICB3aXRoIG9wZW4o
>>"%B64%" echo cCwgImEiLCBlbmNvZGluZz0idXRmLTgiKSBhcyBmOgogICAgICAgICAgICBmLndyaXRlKGxpbmUp
>>"%B64%" echo CiAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICBwYXNzCiAgICBwcmludChsaW5lLCBlbmQ9IiIs
>>"%B64%" echo IGZsdXNoPVRydWUpCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIOyGjeuPhCDsoJztlZwKCl9sYXN0X2NhbGw6IGRpY3Rb
>>"%B64%" echo c3RyLCBmbG9hdF0gPSB7fQpfcmF0ZV9sb2NrID0gdGhyZWFkaW5nLkxvY2soKQoKCmRlZiBfdGhy
>>"%B64%" echo b3R0bGUoaG9zdDogc3RyKSAtPiBmbG9hdDoKICAgICIiIuqwmeydgCDtmLjsiqTtirjrpbwg64SI
>>"%B64%" echo 66y0IOu5qOumrCDsl7Dri6zslYQg67aA66W07KeAIOyViuuPhOuhnSDquLDri6Trpr3ri4jri6Qu
>>"%B64%" echo IOq4sOuLpOumsCDstIjrpbwg64+M66Ck7KSN64uI64ukLiIiIgogICAgZ2FwID0gTUlOX0lOVEVS
>>"%B64%" echo VkFMLmdldChob3N0LCAwLjApCiAgICBpZiBnYXAgPD0gMDoKICAgICAgICByZXR1cm4gMC4wCiAg
>>"%B64%" echo ICB3aXRoIF9yYXRlX2xvY2s6CiAgICAgICAgcHJldiA9IF9sYXN0X2NhbGwuZ2V0KGhvc3QsIDAu
>>"%B64%" echo MCkKICAgICAgICB3YWl0ID0gcHJldiArIGdhcCAtIHRpbWUubW9ub3RvbmljKCkKICAgICAgICBp
>>"%B64%" echo ZiB3YWl0IDw9IDA6CiAgICAgICAgICAgIF9sYXN0X2NhbGxbaG9zdF0gPSB0aW1lLm1vbm90b25p
>>"%B64%" echo YygpCiAgICAgICAgICAgIHJldHVybiAwLjAKICAgICAgICBfbGFzdF9jYWxsW2hvc3RdID0gcHJl
>>"%B64%" echo diArIGdhcAogICAgdGltZS5zbGVlcCh3YWl0KQogICAgcmV0dXJuIHdhaXQKCgpkZWYgX3NzbF9j
>>"%B64%" echo dHgoKSAtPiBzc2wuU1NMQ29udGV4dDoKICAgIGN0eCA9IHNzbC5jcmVhdGVfZGVmYXVsdF9jb250
>>"%B64%" echo ZXh0KCkKICAgICMgUHlJbnN0YWxsZXIg66GcIOustuydgCBleGUg7JeQ64qUIOyduOymneyEnCDr
>>"%B64%" echo rLbsnYzsnbQg7JeG7J2EIOyImCDsnojslrQgY2VydGlmaSDqsIAg7J6I7Jy866m0IOyUgeuLiOuL
>>"%B64%" echo pC4KICAgIHRyeToKICAgICAgICBpbXBvcnQgY2VydGlmaSAgIyB0eXBlOiBpZ25vcmUKICAgICAg
>>"%B64%" echo ICBjdHgubG9hZF92ZXJpZnlfbG9jYXRpb25zKGNlcnRpZmkud2hlcmUoKSkKICAgIGV4Y2VwdCBF
>>"%B64%" echo eGNlcHRpb246CiAgICAgICAgcGFzcwogICAgcmV0dXJuIGN0eAoKCiMgLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBIVFRQCgpk
>>"%B64%" echo ZWYgY2xlYW5faGVhZGVycyhob3N0OiBzdHIsIGhlYWRlcnM6IGRpY3QgfCBOb25lKSAtPiBkaWN0
>>"%B64%" echo OgogICAgIiIi7J20IO2YuOyKpO2KuOqwgCDrsJvslYTrj4Qg65CY64qUIO2XpOuNlOunjCDrgqjq
>>"%B64%" echo uYHri4jri6QuIiIiCiAgICBvdXQgPSB7IkFjY2VwdCI6ICJhcHBsaWNhdGlvbi9qc29uIiwgIlVz
>>"%B64%" echo ZXItQWdlbnQiOiBVU0VSX0FHRU5UfQogICAgZm9yIGssIHYgaW4gKGhlYWRlcnMgb3Ige30pLml0
>>"%B64%" echo ZW1zKCk6CiAgICAgICAgaWYgdiBpbiAoTm9uZSwgIiIpOgogICAgICAgICAgICBjb250aW51ZQog
>>"%B64%" echo ICAgICAgIGhvbWUgPSBIRUFERVJfSE9NRS5nZXQoc3RyKGspLmxvd2VyKCkpCiAgICAgICAgaWYg
>>"%B64%" echo aG9tZSBpcyBub3QgTm9uZSBhbmQgaG9zdCBub3QgaW4gaG9tZToKICAgICAgICAgICAgbG9nKGYi
>>"%B64%" echo 7Zek642UIOywqOuLqDoge2t9IOuKlCB7aG9zdH0g66GcIOuztOuCtOyngCDslYrsirXri4jri6Qi
>>"%B64%" echo KQogICAgICAgICAgICBjb250aW51ZQogICAgICAgIG91dFtzdHIoayldID0gc3RyKHYpCiAgICBy
>>"%B64%" echo ZXR1cm4gb3V0CgoKZGVmIGh0dHBfZ2V0KHVybDogc3RyLCBoZWFkZXJzOiBkaWN0IHwgTm9uZSA9
>>"%B64%" echo IE5vbmUsIHRpbWVvdXQ6IGludCA9IFRJTUVPVVQpIC0+IGRpY3Q6CiAgICAiIiJHRVQg7ZWcIOuy
>>"%B64%" echo iC4g64qYIGRpY3Qg66W8IOuPjOugpOyjvOqzoCDsmIjsmbjrpbwg67CW7Jy866GcIOuCtOuztOuC
>>"%B64%" echo tOyngCDslYrsirXri4jri6QuIiIiCiAgICB0cnk6CiAgICAgICAgaG9zdCA9IHVybGxpYi5wYXJz
>>"%B64%" echo ZS51cmxwYXJzZSh1cmwpLmhvc3RuYW1lIG9yICIiCiAgICBleGNlcHQgVmFsdWVFcnJvcjoKICAg
>>"%B64%" echo ICAgICByZXR1cm4geyJvayI6IEZhbHNlLCAic3RhdHVzIjogMCwgImJvZHkiOiAiIiwgImVycm9y
>>"%B64%" echo IjogIuyjvOyGjOulvCDtlbTshJ3tlZjsp4Ag66q77ZaI7Iq164uI64ukIn0KCiAgICBpZiBub3Qg
>>"%B64%" echo dXJsLmxvd2VyKCkuc3RhcnRzd2l0aCgiaHR0cHM6Ly8iKToKICAgICAgICByZXR1cm4geyJvayI6
>>"%B64%" echo IEZhbHNlLCAic3RhdHVzIjogMCwgImJvZHkiOiAiIiwgImVycm9yIjogImh0dHBzIOunjCDtl4js
>>"%B64%" echo mqntlanri4jri6QifQogICAgaWYgaG9zdCBub3QgaW4gQUxMT1dFRF9IT1NUUzoKICAgICAgICBs
>>"%B64%" echo b2coZiLtl4jsmqnrkJjsp4Ag7JWK7J2AIO2YuOyKpO2KuCDssKjri6g6IHtob3N0fSIpCiAgICAg
>>"%B64%" echo ICAgcmV0dXJuIHsib2siOiBGYWxzZSwgInN0YXR1cyI6IDAsICJib2R5IjogIiIsCiAgICAgICAg
>>"%B64%" echo ICAgICAgICAiZXJyb3IiOiBmIu2XiOyaqeuQmOyngCDslYrsnYAg7Zi47Iqk7Yq47J6F64uI64uk
>>"%B64%" echo OiB7aG9zdH0ifQoKICAgIGhkcnMgPSBjbGVhbl9oZWFkZXJzKGhvc3QsIGhlYWRlcnMpCiAgICBj
>>"%B64%" echo dHggPSBfc3NsX2N0eCgpCiAgICBzdGFydGVkID0gdGltZS5tb25vdG9uaWMoKQogICAgbGFzdF9l
>>"%B64%" echo cnIgPSAiIgoKICAgIGZvciBhdHRlbXB0IGluIHJhbmdlKDEsIE1BWF9SRVRSWSArIDEpOgogICAg
>>"%B64%" echo ICAgIHdhaXRlZCA9IF90aHJvdHRsZShob3N0KQogICAgICAgIHRyeToKICAgICAgICAgICAgcmVx
>>"%B64%" echo ID0gdXJsbGliLnJlcXVlc3QuUmVxdWVzdCh1cmwsIGhlYWRlcnM9aGRycywgbWV0aG9kPSJHRVQi
>>"%B64%" echo KQogICAgICAgICAgICB3aXRoIHVybGxpYi5yZXF1ZXN0LnVybG9wZW4ocmVxLCB0aW1lb3V0PXRp
>>"%B64%" echo bWVvdXQsIGNvbnRleHQ9Y3R4KSBhcyByOgogICAgICAgICAgICAgICAgYm9keSA9IHIucmVhZCgp
>>"%B64%" echo LmRlY29kZSgidXRmLTgiLCBlcnJvcnM9InJlcGxhY2UiKQogICAgICAgICAgICAgICAgbXMgPSBp
>>"%B64%" echo bnQoKHRpbWUubW9ub3RvbmljKCkgLSBzdGFydGVkKSAqIDEwMDApCiAgICAgICAgICAgICAgICBs
>>"%B64%" echo b2coZiIgIHtyLnN0YXR1c30gIHt1cmx9ICAoe21zfW1zeycsIOuMgOq4sCAlLjFmcycgJSB3YWl0
>>"%B64%" echo ZWQgaWYgd2FpdGVkIGVsc2UgJyd9KSIpCiAgICAgICAgICAgICAgICByZXR1cm4geyJvayI6IFRy
>>"%B64%" echo dWUsICJzdGF0dXMiOiByLnN0YXR1cywgImJvZHkiOiBib2R5LCAiZXJyb3IiOiAiIiwKICAgICAg
>>"%B64%" echo ICAgICAgICAgICAgICAgICAgImVsYXBzZWRfbXMiOiBtcywgImF0dGVtcHRzIjogYXR0ZW1wdH0K
>>"%B64%" echo ICAgICAgICBleGNlcHQgdXJsbGliLmVycm9yLkhUVFBFcnJvciBhcyBlOgogICAgICAgICAgICBi
>>"%B64%" echo b2R5ID0gIiIKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgYm9keSA9IGUucmVhZCgp
>>"%B64%" echo LmRlY29kZSgidXRmLTgiLCBlcnJvcnM9InJlcGxhY2UiKQogICAgICAgICAgICBleGNlcHQgRXhj
>>"%B64%" echo ZXB0aW9uOgogICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBpZiBlLmNvZGUgaW4gUkVU
>>"%B64%" echo UllfU1RBVFVTIGFuZCBhdHRlbXB0IDwgTUFYX1JFVFJZOgogICAgICAgICAgICAgICAgYmFjayA9
>>"%B64%" echo IDEuNSAqIGF0dGVtcHQKICAgICAgICAgICAgICAgIGxvZyhmIiAge2UuY29kZX0gIHt1cmx9IOKA
>>"%B64%" echo lCB7YmFjazouMWZ97LSIIOuSpCDsnqzsi5zrj4QgKHthdHRlbXB0fS97TUFYX1JFVFJZfSkiKQog
>>"%B64%" echo ICAgICAgICAgICAgICAgdGltZS5zbGVlcChiYWNrKQogICAgICAgICAgICAgICAgbGFzdF9lcnIg
>>"%B64%" echo PSBmIkhUVFAge2UuY29kZX0iCiAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICBt
>>"%B64%" echo cyA9IGludCgodGltZS5tb25vdG9uaWMoKSAtIHN0YXJ0ZWQpICogMTAwMCkKICAgICAgICAgICAg
>>"%B64%" echo bG9nKGYiICB7ZS5jb2RlfSAge3VybH0gICh7bXN9bXMpIikKICAgICAgICAgICAgIyA0eHgg64qU
>>"%B64%" echo IO2ZlOuptOyXkOyEnCDshKTrqoXtlbTslbwg7ZWY66+A66GcIOuzuOusuOydhCDqt7jrjIDroZwg
>>"%B64%" echo 64SY6rmB64uI64ukLgogICAgICAgICAgICByZXR1cm4geyJvayI6IFRydWUsICJzdGF0dXMiOiBl
>>"%B64%" echo LmNvZGUsICJib2R5IjogYm9keSwgImVycm9yIjogIiIsCiAgICAgICAgICAgICAgICAgICAgImVs
>>"%B64%" echo YXBzZWRfbXMiOiBtcywgImF0dGVtcHRzIjogYXR0ZW1wdH0KICAgICAgICBleGNlcHQgKHVybGxp
>>"%B64%" echo Yi5lcnJvci5VUkxFcnJvciwgVGltZW91dEVycm9yLCBPU0Vycm9yKSBhcyBlOgogICAgICAgICAg
>>"%B64%" echo ICBsYXN0X2VyciA9IGdldGF0dHIoZSwgInJlYXNvbiIsIE5vbmUpIG9yIHN0cihlKQogICAgICAg
>>"%B64%" echo ICAgICBsYXN0X2VyciA9IHN0cihsYXN0X2VycikKICAgICAgICAgICAgaWYgYXR0ZW1wdCA8IE1B
>>"%B64%" echo WF9SRVRSWToKICAgICAgICAgICAgICAgIGJhY2sgPSAxLjUgKiBhdHRlbXB0CiAgICAgICAgICAg
>>"%B64%" echo ICAgICBsb2coZiIgIOyLpO2MqCAge3VybH0g4oCUIHtsYXN0X2Vycn0g4oCUIHtiYWNrOi4xZn3s
>>"%B64%" echo tIgg65KkIOyerOyLnOuPhCAoe2F0dGVtcHR9L3tNQVhfUkVUUll9KSIpCiAgICAgICAgICAgICAg
>>"%B64%" echo ICB0aW1lLnNsZWVwKGJhY2spCiAgICAgICAgICAgICAgICBjb250aW51ZQoKICAgIG1zID0gaW50
>>"%B64%" echo KCh0aW1lLm1vbm90b25pYygpIC0gc3RhcnRlZCkgKiAxMDAwKQogICAgbG9nKGYiICDtj6zquLAg
>>"%B64%" echo IHt1cmx9ICB7bGFzdF9lcnJ9IikKICAgIHJldHVybiB7Im9rIjogRmFsc2UsICJzdGF0dXMiOiAw
>>"%B64%" echo LCAiYm9keSI6ICIiLCAiZXJyb3IiOiBsYXN0X2VyciBvciAi7Jew6rKwIOyLpO2MqCIsCiAgICAg
>>"%B64%" echo ICAgICAgICJlbGFwc2VkX21zIjogbXMsICJhdHRlbXB0cyI6IE1BWF9SRVRSWX0KCgojIC0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0g7YKkIOyggOyepQoKZGVmIGxvYWRfa2V5cygpIC0+IGRpY3Q6CiAgICB0cnk6CiAgICAgICAg
>>"%B64%" echo d2l0aCBvcGVuKEtFWVNfUEFUSCgpLCBlbmNvZGluZz0idXRmLTgiKSBhcyBmOgogICAgICAgICAg
>>"%B64%" echo ICBkID0ganNvbi5sb2FkKGYpCiAgICAgICAgcmV0dXJuIHtrOiBzdHIodikgZm9yIGssIHYgaW4g
>>"%B64%" echo ZC5pdGVtcygpIGlmIGsgaW4gKCJhcGlLZXkiLCAiZmRLZXkiLCAidHNkYktleSIpfQogICAgZXhj
>>"%B64%" echo ZXB0IChPU0Vycm9yLCBWYWx1ZUVycm9yKToKICAgICAgICByZXR1cm4ge30KCgpkZWYgc2F2ZV9r
>>"%B64%" echo ZXlzKGtleXM6IGRpY3QpIC0+IGRpY3Q6CiAgICBrZWVwID0ge2s6IHN0cih2IG9yICIiKSBmb3Ig
>>"%B64%" echo aywgdiBpbiAoa2V5cyBvciB7fSkuaXRlbXMoKQogICAgICAgICAgICBpZiBrIGluICgiYXBpS2V5
>>"%B64%" echo IiwgImZkS2V5IiwgInRzZGJLZXkiKX0KICAgIHBhdGggPSBLRVlTX1BBVEgoKQogICAgdHJ5Ogog
>>"%B64%" echo ICAgICAgICMg64Ko7J20IOuquyDsnb3qsowg66eM65OgIOuSpOyXkCDrgrTsmqnsnYQg7JSB64uI
>>"%B64%" echo 64ukICjsiJzshJzqsIAg67CY64yA66m0IOyeoOq5kCDsl7TroKQg7J6I7Iq164uI64ukKS4KICAg
>>"%B64%" echo ICAgICBmZCA9IG9zLm9wZW4ocGF0aCwgb3MuT19XUk9OTFkgfCBvcy5PX0NSRUFUIHwgb3MuT19U
>>"%B64%" echo UlVOQywgMG82MDApCiAgICAgICAgd2l0aCBvcy5mZG9wZW4oZmQsICJ3IiwgZW5jb2Rpbmc9InV0
>>"%B64%" echo Zi04IikgYXMgZjoKICAgICAgICAgICAganNvbi5kdW1wKGtlZXAsIGYsIGVuc3VyZV9hc2NpaT1G
>>"%B64%" echo YWxzZSwgaW5kZW50PTEpCiAgICAgICAgbG9nKGYi7YKkIOyggOyepSDigJQge3N1bSgxIGZvciB2
>>"%B64%" echo IGluIGtlZXAudmFsdWVzKCkgaWYgdil96rCcIMK3IHtwYXRofSIpCiAgICAgICAgcmV0dXJuIHsi
>>"%B64%" echo b2siOiBUcnVlLCAicGF0aCI6IHBhdGh9CiAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAg
>>"%B64%" echo IGxvZyhmIu2CpCDsoIDsnqUg7Iuk7YyoOiB7ZX0iKQogICAgICAgIHJldHVybiB7Im9rIjogRmFs
>>"%B64%" echo c2UsICJlcnJvciI6IHN0cihlKX0KCgpkZWYgZm9yZ2V0X2tleXMoKSAtPiBkaWN0OgogICAgdHJ5
>>"%B64%" echo OgogICAgICAgIG9zLnJlbW92ZShLRVlTX1BBVEgoKSkKICAgICAgICBsb2coIuyggOyepeuQnCDt
>>"%B64%" echo gqQg7IKt7KCcIikKICAgIGV4Y2VwdCBGaWxlTm90Rm91bmRFcnJvcjoKICAgICAgICBwYXNzCiAg
>>"%B64%" echo ICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAgIHJldHVybiB7Im9rIjogRmFsc2UsICJlcnJv
>>"%B64%" echo ciI6IHN0cihlKX0KICAgIHJldHVybiB7Im9rIjogVHJ1ZX0KCgojIC0tLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0g7KeE64uoCgpQ
>>"%B64%" echo Uk9CRVMgPSBbCiAgICAoInByaW1hcnkiLCAiQVBJLUZvb3RiYWxsIiwgImh0dHBzOi8vdjMuZm9v
>>"%B64%" echo dGJhbGwuYXBpLXNwb3J0cy5pby9zdGF0dXMiLAogICAgIGxhbWJkYSBrOiB7IngtYXBpc3BvcnRz
>>"%B64%" echo LWtleSI6IGsuZ2V0KCJhcGlLZXkiLCAiIil9LCAiYXBpS2V5IiksCiAgICAoImZkIiwgImZvb3Ri
>>"%B64%" echo YWxsLWRhdGEub3JnIiwgImh0dHBzOi8vYXBpLmZvb3RiYWxsLWRhdGEub3JnL3Y0L2NvbXBldGl0
>>"%B64%" echo aW9ucy9QTCIsCiAgICAgbGFtYmRhIGs6IHsiWC1BdXRoLVRva2VuIjogay5nZXQoImZkS2V5Iiwg
>>"%B64%" echo IiIpfSwgImZkS2V5IiksCiAgICAoIm9sZGIiLCAiT3BlbkxpZ2FEQiIsICJodHRwczovL2FwaS5v
>>"%B64%" echo cGVubGlnYWRiLmRlL2dldGF2YWlsYWJsZWxlYWd1ZXMiLAogICAgIGxhbWJkYSBrOiB7fSwgTm9u
>>"%B64%" echo ZSksCiAgICAoImZhbGxiYWNrIiwgIlRoZVNwb3J0c0RCIiwKICAgICAiaHR0cHM6Ly93d3cudGhl
>>"%B64%" echo c3BvcnRzZGIuY29tL2FwaS92MS9qc29uLzMvYWxsX2xlYWd1ZXMucGhwIiwKICAgICBsYW1iZGEg
>>"%B64%" echo azoge30sIE5vbmUpLApdCgoKZGVmIHByb2JlKGtleXM6IGRpY3QgfCBOb25lID0gTm9uZSkgLT4g
>>"%B64%" echo bGlzdDoKICAgICIiIuuEpCDshozsiqTrpbwg7LCo66GA66GcIOuRkOuTnOugpCDrs7Tqs6Ag7Ja0
>>"%B64%" echo 65SU6rCAIOuQmOqzoCDslrTrlJTqsIAg66eJ7Z6I64qU7KeAIOyVjOugpOykjeuLiOuLpC4iIiIK
>>"%B64%" echo ICAgIGtleXMgPSBrZXlzIG9yIHt9CiAgICBvdXQgPSBbXQogICAgZm9yIHNpZCwgbmFtZSwgdXJs
>>"%B64%" echo LCBtaywgbmVlZCBpbiBQUk9CRVM6CiAgICAgICAgaWYgbmVlZCBhbmQgbm90IGtleXMuZ2V0KG5l
>>"%B64%" echo ZWQpOgogICAgICAgICAgICBvdXQuYXBwZW5kKHsiaWQiOiBzaWQsICJuYW1lIjogbmFtZSwgInN0
>>"%B64%" echo YXRlIjogInNraXAiLAogICAgICAgICAgICAgICAgICAgICAgICAiZGV0YWlsIjogIu2CpOulvCDs
>>"%B64%" echo noXroKXtlZjsp4Ag7JWK7JWEIOqxtOuEiOucgeuLiOuLpCJ9KQogICAgICAgICAgICBjb250aW51
>>"%B64%" echo ZQogICAgICAgIHIgPSBodHRwX2dldCh1cmwsIG1rKGtleXMpLCB0aW1lb3V0PTEyKQogICAgICAg
>>"%B64%" echo IGlmIG5vdCByWyJvayJdOgogICAgICAgICAgICBvdXQuYXBwZW5kKHsiaWQiOiBzaWQsICJuYW1l
>>"%B64%" echo IjogbmFtZSwgInN0YXRlIjogImZhaWwiLAogICAgICAgICAgICAgICAgICAgICAgICAiZGV0YWls
>>"%B64%" echo IjogZiLsl7DqsrAg7Iuk7YyoIOKAlCB7clsnZXJyb3InXX0ifSkKICAgICAgICBlbGlmIHJbInN0
>>"%B64%" echo YXR1cyJdID09IDIwMDoKICAgICAgICAgICAgb3V0LmFwcGVuZCh7ImlkIjogc2lkLCAibmFtZSI6
>>"%B64%" echo IG5hbWUsICJzdGF0ZSI6ICJvayIsCiAgICAgICAgICAgICAgICAgICAgICAgICJkZXRhaWwiOiBm
>>"%B64%" echo IuygleyDgSDCtyB7ci5nZXQoJ2VsYXBzZWRfbXMnLCAwKX1tcyJ9KQogICAgICAgIGVsaWYgclsi
>>"%B64%" echo c3RhdHVzIl0gaW4gKDQwMSwgNDAzKToKICAgICAgICAgICAgb3V0LmFwcGVuZCh7ImlkIjogc2lk
>>"%B64%" echo LCAibmFtZSI6IG5hbWUsICJzdGF0ZSI6ICJmYWlsIiwKICAgICAgICAgICAgICAgICAgICAgICAg
>>"%B64%" echo ImRldGFpbCI6IGYi7YKk6rCAIOqxsOu2gOuQkOyKteuLiOuLpCAoSFRUUCB7clsnc3RhdHVzJ119
>>"%B64%" echo KSJ9KQogICAgICAgIGVsaWYgclsic3RhdHVzIl0gPT0gNDI5OgogICAgICAgICAgICBvdXQuYXBw
>>"%B64%" echo ZW5kKHsiaWQiOiBzaWQsICJuYW1lIjogbmFtZSwgInN0YXRlIjogIndhcm4iLAogICAgICAgICAg
>>"%B64%" echo ICAgICAgICAgICAgICAiZGV0YWlsIjogIu2YuOy2nCDtlZzrj4Qg7LSI6rO8IOKAlCDsnqDsi5wg
>>"%B64%" echo 65KkIOuLpOyLnCJ9KQogICAgICAgIGVsc2U6CiAgICAgICAgICAgIG91dC5hcHBlbmQoeyJpZCI6
>>"%B64%" echo IHNpZCwgIm5hbWUiOiBuYW1lLCAic3RhdGUiOiAid2FybiIsCiAgICAgICAgICAgICAgICAgICAg
>>"%B64%" echo ICAgICJkZXRhaWwiOiBmIkhUVFAge3JbJ3N0YXR1cyddfSJ9KQogICAgcmV0dXJuIG91dAoKCmRl
>>"%B64%" echo ZiBhcHBfaW5mbygpIC0+IGRpY3Q6CiAgICByZXR1cm4geyJ2ZXJzaW9uIjogVkVSU0lPTiwgInB5
>>"%B64%" echo dGhvbiI6IHN5cy52ZXJzaW9uLnNwbGl0KClbMF0sCiAgICAgICAgICAgICJwbGF0Zm9ybSI6IHN5
>>"%B64%" echo cy5wbGF0Zm9ybSwgImRhdGFfZGlyIjogZGF0YV9kaXIoKSwKICAgICAgICAgICAgImxvZyI6IExP
>>"%B64%" echo R19QQVRIKCksICJrZXlzIjogS0VZU19QQVRIKCksCiAgICAgICAgICAgICJmcm96ZW4iOiBib29s
>>"%B64%" echo KGdldGF0dHIoc3lzLCAiZnJvemVuIiwgRmFsc2UpKX0K
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:wr_brg
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo LyogPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
>>"%B64%" echo PT09PT09CiAgIOuNsOyKpO2BrO2GsSDri6TrpqwgKEhUTUwg7ZmU66m0ICA8LT4gIO2MjOydtOyN
>>"%B64%" echo rCDsl5Tsp4QpCgogICDsnbQg7YyM7J287J2AIO2ZlOuptCDsvZTrk5zrpbwg6rOg7LmY7KeAIOyV
>>"%B64%" echo iuyKteuLiOuLpC4g7JWxIOyViOyXkOyEnCDsl7TroLjsnYQg65WM7JeQ66eMCiAgIGZldGNoIOul
>>"%B64%" echo vCDtjIzsnbTsjawg7Kq97Jy866GcIOuPjOugpOuGk+qzoCwg7ZmU66m07JeQ7IScIO2VhOyalCDs
>>"%B64%" echo l4bslrTsp4Qg67aA67aE7J2EIOygleumrO2VqeuLiOuLpC4KICAg6re464OlIOu4jOudvOyasOyg
>>"%B64%" echo gOuhnCDsl7TrqbQg7JWE66y0IOydvOuPhCDtlZjsp4Ag7JWK6rOgIOyYiOyghCDqt7jrjIDroZwg
>>"%B64%" echo 64+Z7J6R7ZWp64uI64ukLgoKICAg7YyM7J207I2s7J2EIOqxsOy5mOuptCBDT1JTIOqwgCDsl4bs
>>"%B64%" echo irXri4jri6QuIO2UhOuhneyLnOuPhCwgODc4NyDtj6ztirjrj4Qg7ZWE7JqUIOyXhuyKteuLiOuL
>>"%B64%" echo pC4KICAgPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
>>"%B64%" echo PT09PT09PT09ICovCihmdW5jdGlvbiAoKSB7CiAgJ3VzZSBzdHJpY3QnOwoKICAvLyDtjIzsnbTs
>>"%B64%" echo jazsnbQg64yA7IugIOu2iOufrCDspIQg6rOzLiDrgpjrqLjsp4Ag7KO87IaM64qUIOqxtOuTnOum
>>"%B64%" echo rOyngCDslYrsirXri4jri6QuCiAgdmFyIEFQSV9IT1NUUyA9IC8oXnxcLikodjNcLmZvb3RiYWxs
>>"%B64%" echo XC5hcGktc3BvcnRzXC5pb3xhcGlcLmZvb3RiYWxsLWRhdGFcLm9yZ3xhcGlcLm9wZW5saWdhZGJc
>>"%B64%" echo LmRlfHRoZXNwb3J0c2RiXC5jb20pJC9pOwoKICBmdW5jdGlvbiByZWFkeShmbikgewogICAgaWYg
>>"%B64%" echo KHdpbmRvdy5weXdlYnZpZXcgJiYgd2luZG93LnB5d2Vidmlldy5hcGkpIHsgZm4oKTsgcmV0dXJu
>>"%B64%" echo OyB9CiAgICB3aW5kb3cuYWRkRXZlbnRMaXN0ZW5lcigncHl3ZWJ2aWV3cmVhZHknLCBmbiwgeyBv
>>"%B64%" echo bmNlOiB0cnVlIH0pOwogIH0KCiAgZnVuY3Rpb24gaXNBcGlVcmwodSkgewogICAgdHJ5IHsgcmV0
>>"%B64%" echo dXJuIEFQSV9IT1NUUy50ZXN0KG5ldyBVUkwodSwgbG9jYXRpb24uaHJlZikuaG9zdG5hbWUpOyB9
>>"%B64%" echo CiAgICBjYXRjaCAoZSkgeyByZXR1cm4gZmFsc2U7IH0KICB9CgogIC8qIC0tLS0tLS0tLS0gMS4g
>>"%B64%" echo ZmV0Y2gg66W8IO2MjOydtOyNrOycvOuhnCAtLS0tLS0tLS0tICovCiAgZnVuY3Rpb24gaW5zdGFs
>>"%B64%" echo bEZldGNoKCkgewogICAgdmFyIG5hdGl2ZSA9IHdpbmRvdy5mZXRjaC5iaW5kKHdpbmRvdyk7Cgog
>>"%B64%" echo ICAgd2luZG93LmZldGNoID0gZnVuY3Rpb24gKGlucHV0LCBpbml0KSB7CiAgICAgIHZhciB1cmwg
>>"%B64%" echo PSAodHlwZW9mIGlucHV0ID09PSAnc3RyaW5nJykgPyBpbnB1dCA6IChpbnB1dCAmJiBpbnB1dC51
>>"%B64%" echo cmwpIHx8ICcnOwogICAgICBpZiAoIWlzQXBpVXJsKHVybCkpIHJldHVybiBuYXRpdmUoaW5wdXQs
>>"%B64%" echo IGluaXQpOwoKICAgICAgaW5pdCA9IGluaXQgfHwge307CiAgICAgIHZhciBoZWFkZXJzID0ge307
>>"%B64%" echo CiAgICAgIHZhciBoID0gaW5pdC5oZWFkZXJzOwogICAgICBpZiAoaCkgewogICAgICAgIGlmICh0
>>"%B64%" echo eXBlb2YgaC5mb3JFYWNoID09PSAnZnVuY3Rpb24nICYmICFBcnJheS5pc0FycmF5KGgpKSBoLmZv
>>"%B64%" echo ckVhY2goZnVuY3Rpb24gKHYsIGspIHsgaGVhZGVyc1trXSA9IHY7IH0pOwogICAgICAgIGVsc2Ug
>>"%B64%" echo aWYgKEFycmF5LmlzQXJyYXkoaCkpIGguZm9yRWFjaChmdW5jdGlvbiAocCkgeyBoZWFkZXJzW3Bb
>>"%B64%" echo MF1dID0gcFsxXTsgfSk7CiAgICAgICAgZWxzZSBPYmplY3Qua2V5cyhoKS5mb3JFYWNoKGZ1bmN0
>>"%B64%" echo aW9uIChrKSB7IGhlYWRlcnNba10gPSBoW2tdOyB9KTsKICAgICAgfQoKICAgICAgcmV0dXJuIHdp
>>"%B64%" echo bmRvdy5weXdlYnZpZXcuYXBpLmh0dHBfZ2V0KHVybCwgaGVhZGVycykudGhlbihmdW5jdGlvbiAo
>>"%B64%" echo cikgewogICAgICAgIGlmICghciB8fCAhci5vaykgewogICAgICAgICAgLy8g7ZmU66m0IOy9lOuT
>>"%B64%" echo nOuKlCAi64Sk7Yq47JuM7YGsIOyLpO2MqCLrpbwgVHlwZUVycm9yIOuhnCDslYzslYTrtIXri4jr
>>"%B64%" echo i6QuIOuqqOyWkeydhCDrp57strAg7KSN64uI64ukLgogICAgICAgICAgdGhyb3cgbmV3IFR5cGVF
>>"%B64%" echo cnJvcigociAmJiByLmVycm9yKSB8fCAn7YyM7J207I2sIOyXlOynhOydtCDsnZHri7XtlZjsp4Ag
>>"%B64%" echo 7JWK7JWY7Iq164uI64ukJyk7CiAgICAgICAgfQogICAgICAgIHJldHVybiBuZXcgUmVzcG9uc2Uo
>>"%B64%" echo ci5ib2R5LCB7CiAgICAgICAgICBzdGF0dXM6IHIuc3RhdHVzIHx8IDIwMCwKICAgICAgICAgIGhl
>>"%B64%" echo YWRlcnM6IHsgJ0NvbnRlbnQtVHlwZSc6ICdhcHBsaWNhdGlvbi9qc29uOyBjaGFyc2V0PXV0Zi04
>>"%B64%" echo JyB9CiAgICAgICAgfSk7CiAgICAgIH0pOwogICAgfTsKICB9CgogIC8qIC0tLS0tLS0tLS0gMi4g
>>"%B64%" echo 7ZmU66m07JeQ7IScIO2VhOyalCDsl4bslrTsp4Qg6rKDIOy5mOyasOq4sCAtLS0tLS0tLS0tICov
>>"%B64%" echo CiAgZnVuY3Rpb24gdGlkeVVpKCkgewogICAgdmFyICQgPSBmdW5jdGlvbiAoaWQpIHsgcmV0dXJu
>>"%B64%" echo IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKGlkKTsgfTsKCiAgICAvLyDtlITroZ3si5wg7Lm4IOKA
>>"%B64%" echo lCDrjbDsiqTtgazthrHsl5DshJzripQg7J2Y66+46rCAIOyXhuyKteuLiOuLpC4KICAgIHZhciBw
>>"%B64%" echo cm94eSA9ICQoJ2ZkUHJveHknKTsKICAgIGlmIChwcm94eSkgewogICAgICBwcm94eS52YWx1ZSA9
>>"%B64%" echo ICcnOwogICAgICB2YXIgbGFiID0gZG9jdW1lbnQucXVlcnlTZWxlY3RvcignbGFiZWxbZm9yPSJm
>>"%B64%" echo ZFByb3h5Il0nKTsKICAgICAgaWYgKGxhYikgbGFiLmhpZGRlbiA9IHRydWU7CiAgICAgIHByb3h5
>>"%B64%" echo LmhpZGRlbiA9IHRydWU7CiAgICB9CgogICAgLy8gZm9vdGJhbGwtZGF0YS5vcmcg7Lm4IOyVhOue
>>"%B64%" echo mOydmCBDT1JTwrftlITroZ3si5wg7ISk66qFIOusuOuLqOydhCDqsbfslrTrg4Xri4jri6QuCiAg
>>"%B64%" echo ICB2YXIgcm93ID0gJCgnZmRLZXknKSAmJiAkKCdmZEtleScpLmNsb3Nlc3QoJy5zcmMtcm93Jyk7
>>"%B64%" echo CiAgICBpZiAocm93KSB7CiAgICAgIHJvdy5xdWVyeVNlbGVjdG9yQWxsKCcuc21hbGwnKS5mb3JF
>>"%B64%" echo YWNoKGZ1bmN0aW9uIChlbCkgewogICAgICAgIGlmICgvQ09SU3ztlITroZ3si5x8ODc4Ny8udGVz
>>"%B64%" echo dChlbC50ZXh0Q29udGVudCkpIGVsLmhpZGRlbiA9IHRydWU7CiAgICAgIH0pOwogICAgICB2YXIg
>>"%B64%" echo bm90ZSA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoJ2RpdicpOwogICAgICBub3RlLmNsYXNzTmFt
>>"%B64%" echo ZSA9ICdzbWFsbCc7CiAgICAgIG5vdGUuc3R5bGUubWFyZ2luVG9wID0gJzZweCc7CiAgICAgIG5v
>>"%B64%" echo dGUuaW5uZXJIVE1MID0gJ+ydtCDslbHsnYAgPGI+7YyM7J207I2s7J20IOuMgOyLoCDtmLjstpw8
>>"%B64%" echo L2I+7ZWY66+A66GcIENPUlMg6rCAIOyXhuyKteuLiOuLpC4gJwogICAgICAgICsgJ+2UhOuhneyL
>>"%B64%" echo nOulvCDrnYTsmrgg7ZWE7JqU64+ELCDso7zshozrpbwg7J6F66Cl7ZWgIO2VhOyalOuPhCDsl4bs
>>"%B64%" echo irXri4jri6QuICcKICAgICAgICArICfthqDtgbDsnYAgZm9vdGJhbGwtZGF0YS5vcmcg66Gc66eM
>>"%B64%" echo IOyghOyGoeuQqeuLiOuLpC4nOwogICAgICByb3cuYXBwZW5kQ2hpbGQobm90ZSk7CiAgICB9Cgog
>>"%B64%" echo ICAgLy8g7KeE64uoIOuyhO2KvCDigJQg7ZSE66Gd7Iuc6rCAIOyVhOuLiOudvCDrhKQg7IaM7Iqk
>>"%B64%" echo 66W8IOyghOu2gCDrkZDrk5zroKQg67SF64uI64ukLgogICAgZG9jdW1lbnQucXVlcnlTZWxlY3Rv
>>"%B64%" echo ckFsbCgnYnV0dG9uJykuZm9yRWFjaChmdW5jdGlvbiAoYikgewogICAgICBpZiAoL+2UhOuhneyL
>>"%B64%" echo nCDsp4Tri6gvLnRlc3QoYi50ZXh0Q29udGVudCkpIHsKICAgICAgICBiLnRleHRDb250ZW50ID0g
>>"%B64%" echo J/CflI4g7IaM7IqkIOyXsOqysCDsp4Tri6gnOwogICAgICAgIGIuc2V0QXR0cmlidXRlKCdvbmNs
>>"%B64%" echo aWNrJywgJ2Rlc2t0b3BQcm9iZSgpJyk7CiAgICAgIH0KICAgIH0pOwoKICAgIC8vIO2CpCDsoIDs
>>"%B64%" echo nqUg7JWI64K066W8IOyCrOyLpOyXkCDrp57qsowg6rOg7Lmp64uI64ukLgogICAgdmFyIHY0ID0g
>>"%B64%" echo ZG9jdW1lbnQucXVlcnlTZWxlY3RvcignLnY0LW5vdGUnKTsKICAgIGlmICh2NCkgewogICAgICB2
>>"%B64%" echo NC5pbm5lckhUTUwgPSAn7J6F66Cl7ZWcIO2CpOuKlCA8Yj7rgrQgUEMg7JWI7JeQ66eMPC9iPiDs
>>"%B64%" echo oIDsnqXrkKnri4jri6Qg4oCUICcKICAgICAgICArICc8Y29kZSBpZD0ia2V5c1BhdGgiPuKApjwv
>>"%B64%" echo Y29kZT4gKOuCmOunjCDsnb3snYQg7IiYIOyeiOuKlCDqtoztlZwpLiAnCiAgICAgICAgKyAn6rCB
>>"%B64%" echo IO2CpOuKlCDqt7gg7YKk6rCAIOyGje2VnCDshJzruYTsiqTroZzrp4wg7KCE7Iah65CY66mwLCDt
>>"%B64%" echo jIzsnbTsjawg7JeU7KeE7J20IOuLpOuluCDqs7PsnLzroZzripQg67O064K07KeAIOyViuyKteuL
>>"%B64%" echo iOuLpC48YnI+JwogICAgICAgICsgJzxidXR0b24gY2xhc3M9ImJ0biBidG4tc2Vjb25kYXJ5IiBz
>>"%B64%" echo dHlsZT0ibWFyZ2luLXRvcDo4cHgiIG9uY2xpY2s9ImRlc2t0b3BGb3JnZXRLZXlzKCkiPuyggOye
>>"%B64%" echo peuQnCDtgqQg7KeA7Jqw6riwPC9idXR0b24+ICcKICAgICAgICArICc8YnV0dG9uIGNsYXNzPSJi
>>"%B64%" echo dG4gYnRuLXNlY29uZGFyeSIgc3R5bGU9Im1hcmdpbi10b3A6OHB4IiBvbmNsaWNrPSJ3aW5kb3cu
>>"%B64%" echo cHl3ZWJ2aWV3LmFwaS5vcGVuX2xvZygpIj7quLDroZ0g7YyM7J28IOyXtOq4sDwvYnV0dG9uPic7
>>"%B64%" echo CiAgICB9CgogICAgLy8g7JWxIOyViOydtOudvOuKlCDtkZzsi5wuCiAgICB2YXIgYmFkZ2UgPSBk
>>"%B64%" echo b2N1bWVudC5xdWVyeVNlbGVjdG9yKCcudmVyc2lvbi1iYWRnZScpOwogICAgaWYgKGJhZGdlKSBi
>>"%B64%" echo YWRnZS50ZXh0Q29udGVudCA9ICd2NC4wIMK3IOuNsOyKpO2BrO2GsSDCtyDwn5CNIFB5dGhvbiDs
>>"%B64%" echo l5Tsp4QnOwoKICAgIHZhciBzdCA9ICQoJ2ZkU3RhdHVzJyk7CiAgICBpZiAoc3QpIHN0LnRleHRD
>>"%B64%" echo b250ZW50ID0gJ+2UhOuhneyLnCDsl4bsnbQg7YyM7J207I2s7J20IOyngeygkSDtmLjstpztlanr
>>"%B64%" echo i4jri6QnOwogICAgdmFyIGRvdCA9ICQoJ2ZkRG90Jyk7CiAgICBpZiAoZG90KSBkb3QuY2xhc3NO
>>"%B64%" echo YW1lID0gJ2RvdCc7CiAgfQoKICAvKiAtLS0tLS0tLS0tIDMuIO2CpOulvCDrgrQgUEMg7JeQIOq4
>>"%B64%" echo sOyWteyLnO2CpOq4sCAtLS0tLS0tLS0tICovCiAgdmFyIEtFWV9JRFMgPSBbJ2FwaUtleScsICdm
>>"%B64%" echo ZEtleScsICd0c2RiS2V5J107CgogIGZ1bmN0aW9uIGNvbGxlY3RLZXlzKCkgewogICAgdmFyIG91
>>"%B64%" echo dCA9IHt9OwogICAgS0VZX0lEUy5mb3JFYWNoKGZ1bmN0aW9uIChpZCkgewogICAgICB2YXIgZWwg
>>"%B64%" echo PSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChpZCk7CiAgICAgIG91dFtpZF0gPSBlbCA/IGVsLnZh
>>"%B64%" echo bHVlLnRyaW0oKSA6ICcnOwogICAgfSk7CiAgICByZXR1cm4gb3V0OwogIH0KCiAgZnVuY3Rpb24g
>>"%B64%" echo aW5zdGFsbEtleVN0b3JlKCkgewogICAgd2luZG93LnB5d2Vidmlldy5hcGkubG9hZF9rZXlzKCku
>>"%B64%" echo dGhlbihmdW5jdGlvbiAocikgewogICAgICBpZiAoIXIgfHwgIXIub2spIHJldHVybjsKICAgICAg
>>"%B64%" echo dmFyIHNhdmVkID0gci5rZXlzIHx8IHt9LCBmaWxsZWQgPSAwOwogICAgICBLRVlfSURTLmZvckVh
>>"%B64%" echo Y2goZnVuY3Rpb24gKGlkKSB7CiAgICAgICAgdmFyIGVsID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5
>>"%B64%" echo SWQoaWQpOwogICAgICAgIGlmIChlbCAmJiBzYXZlZFtpZF0gJiYgIWVsLnZhbHVlKSB7IGVsLnZh
>>"%B64%" echo bHVlID0gc2F2ZWRbaWRdOyBmaWxsZWQrKzsgfQogICAgICB9KTsKICAgICAgaWYgKGZpbGxlZCkg
>>"%B64%" echo ewogICAgICAgIHZhciBzID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2FwaVN0YXR1cycpOwog
>>"%B64%" echo ICAgICAgIGlmIChzICYmIHNhdmVkLmFwaUtleSkgcy50ZXh0Q29udGVudCA9ICfsoIDsnqXrkJwg
>>"%B64%" echo 7YKk66W8IOu2iOufrOyZlOyKteuLiOuLpCDCtyDsl7DqsrAg7ZmV7J247J2EIOuIjOufrOuztOyE
>>"%B64%" echo uOyalCc7CiAgICAgIH0KICAgIH0pOwoKICAgIHZhciB0aW1lciA9IG51bGw7CiAgICBLRVlfSURT
>>"%B64%" echo LmZvckVhY2goZnVuY3Rpb24gKGlkKSB7CiAgICAgIHZhciBlbCA9IGRvY3VtZW50LmdldEVsZW1l
>>"%B64%" echo bnRCeUlkKGlkKTsKICAgICAgaWYgKCFlbCkgcmV0dXJuOwogICAgICBlbC5hZGRFdmVudExpc3Rl
>>"%B64%" echo bmVyKCdpbnB1dCcsIGZ1bmN0aW9uICgpIHsKICAgICAgICBjbGVhclRpbWVvdXQodGltZXIpOwog
>>"%B64%" echo ICAgICAgIHRpbWVyID0gc2V0VGltZW91dChmdW5jdGlvbiAoKSB7IHdpbmRvdy5weXdlYnZpZXcu
>>"%B64%" echo YXBpLnNhdmVfa2V5cyhjb2xsZWN0S2V5cygpKTsgfSwgODAwKTsKICAgICAgfSk7CiAgICB9KTsK
>>"%B64%" echo CiAgICB3aW5kb3cucHl3ZWJ2aWV3LmFwaS5hcHBfaW5mbygpLnRoZW4oZnVuY3Rpb24gKGluZm8p
>>"%B64%" echo IHsKICAgICAgdmFyIGVsID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2tleXNQYXRoJyk7CiAg
>>"%B64%" echo ICAgIGlmIChlbCAmJiBpbmZvICYmIGluZm8ua2V5cykgZWwudGV4dENvbnRlbnQgPSBpbmZvLmtl
>>"%B64%" echo eXM7CiAgICB9KTsKICB9CgogIC8qIC0tLS0tLS0tLS0gNC4g7ZmU66m07JeQ7IScIOu2gOultOuK
>>"%B64%" echo lCDsp4Tri6jCt+ygleumrCDtlajsiJggLS0tLS0tLS0tLSAqLwogIHdpbmRvdy5kZXNrdG9wUHJv
>>"%B64%" echo YmUgPSBmdW5jdGlvbiAoKSB7CiAgICB2YXIgYm94ID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQo
>>"%B64%" echo J2ZkRGlhZycpOwogICAgaWYgKCFib3gpIHJldHVybjsKICAgIGJveC5oaWRkZW4gPSBmYWxzZTsK
>>"%B64%" echo ICAgIGJveC50ZXh0Q29udGVudCA9ICfrhKQg7IaM7Iqk66W8IOywqOuhgOuhnCDtmZXsnbjtlZjr
>>"%B64%" echo ipQg7KSR4oCmJzsKICAgIHdpbmRvdy5weXdlYnZpZXcuYXBpLnByb2JlKGNvbGxlY3RLZXlzKCkp
>>"%B64%" echo LnRoZW4oZnVuY3Rpb24gKHIpIHsKICAgICAgaWYgKCFyIHx8ICFyLm9rKSB7IGJveC50ZXh0Q29u
>>"%B64%" echo dGVudCA9ICfsp4Tri6gg7Iuk7YyoOiAnICsgKChyICYmIHIuZXJyb3IpIHx8ICfslYwg7IiYIOyX
>>"%B64%" echo huydjCcpOyByZXR1cm47IH0KICAgICAgdmFyIG1hcmsgPSB7IG9rOiAn4pyFJywgd2FybjogJ+Ka
>>"%B64%" echo oO+4jycsIGZhaWw6ICfinYwnLCBza2lwOiAnwrcnIH07CiAgICAgIGJveC50ZXh0Q29udGVudCA9
>>"%B64%" echo IHIucmVzdWx0cy5tYXAoZnVuY3Rpb24gKHgpIHsKICAgICAgICByZXR1cm4gKG1hcmtbeC5zdGF0
>>"%B64%" echo ZV0gfHwgJ8K3JykgKyAnICcgKyB4Lm5hbWUgKyAnIOKAlCAnICsgeC5kZXRhaWw7CiAgICAgIH0p
>>"%B64%" echo LmpvaW4oJ1xuJyk7CiAgICB9KTsKICB9OwoKICB3aW5kb3cuZGVza3RvcEZvcmdldEtleXMgPSBm
>>"%B64%" echo dW5jdGlvbiAoKSB7CiAgICB3aW5kb3cucHl3ZWJ2aWV3LmFwaS5mb3JnZXRfa2V5cygpLnRoZW4o
>>"%B64%" echo ZnVuY3Rpb24gKCkgewogICAgICBLRVlfSURTLmZvckVhY2goZnVuY3Rpb24gKGlkKSB7CiAgICAg
>>"%B64%" echo ICAgdmFyIGVsID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoaWQpOwogICAgICAgIGlmIChlbCkg
>>"%B64%" echo ZWwudmFsdWUgPSAnJzsKICAgICAgfSk7CiAgICAgIHZhciBzID0gZG9jdW1lbnQuZ2V0RWxlbWVu
>>"%B64%" echo dEJ5SWQoJ2FwaVN0YXR1cycpOwogICAgICBpZiAocykgcy50ZXh0Q29udGVudCA9ICfsoIDsnqXr
>>"%B64%" echo kJwg7YKk66W8IOyngOyboOyKteuLiOuLpCc7CiAgICB9KTsKICB9OwoKICAvKiAtLS0tLS0tLS0t
>>"%B64%" echo IOyLpO2WiSAtLS0tLS0tLS0tICovCiAgcmVhZHkoZnVuY3Rpb24gKCkgewogICAgdHJ5IHsKICAg
>>"%B64%" echo ICAgaW5zdGFsbEZldGNoKCk7CiAgICAgIHRpZHlVaSgpOwogICAgICBpbnN0YWxsS2V5U3RvcmUo
>>"%B64%" echo KTsKICAgICAgZG9jdW1lbnQuZG9jdW1lbnRFbGVtZW50LnNldEF0dHJpYnV0ZSgnZGF0YS1kZXNr
>>"%B64%" echo dG9wJywgJzEnKTsKICAgICAgY29uc29sZS5sb2coJ+uNsOyKpO2BrO2GsSDri6Trpqwg7Jew6rKw
>>"%B64%" echo 65CoIOKAlCBBUEkg7Zi47Lac7J2AIO2MjOydtOyNrOydtCDrjIDsi6Dtlanri4jri6QnKTsKICAg
>>"%B64%" echo IH0gY2F0Y2ggKGUpIHsKICAgICAgY29uc29sZS5lcnJvcign642w7Iqk7YGs7YaxIOuLpOumrCDs
>>"%B64%" echo hKTsuZgg7Iuk7YyoOicsIGUpOwogICAgfQogIH0pOwp9KSgpOwo=
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:wr_mk
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo IiIidWkvaW5kZXguaHRtbCDsnYQg64uk7IucIOunjOuTreuLiOuLpC4KCuybkOuzuCBIVE1MKC4u
>>"%B64%" echo L3Nwb3J0cy1haS1hbmFseXplci12NC5odG1sKeydgCDshpDrjIDsp4Ag7JWK7Iq164uI64ukLiDs
>>"%B64%" echo l6zquLDshJzripQg6re4IO2MjOydvOydhArqt7jrjIDroZwg7J297Ja0IGJyaWRnZS5qcyDrp4wg
>>"%B64%" echo PC9ib2R5PiDslZ7sl5Ag64G87JuMIOuEo+yKteuLiOuLpC4g7JuQ67O47J2EIOqzoOy5mOuptCDs
>>"%B64%" echo nbQg7Iqk7YGs66a97Yq466W8CuuLpOyLnCDrj4zrpqzquLDrp4wg7ZWY66m0IO2ZlOuptOydtCDr
>>"%B64%" echo lLDrnbzsmLXri4jri6QuCgogICAgcHl0aG9uIG1ha2VfdWkucHkKIiIiCmZyb20gX19mdXR1cmVf
>>"%B64%" echo XyBpbXBvcnQgYW5ub3RhdGlvbnMKCmltcG9ydCBvcwppbXBvcnQgc3lzCgpIRVJFID0gb3MucGF0
>>"%B64%" echo aC5kaXJuYW1lKG9zLnBhdGguYWJzcGF0aChfX2ZpbGVfXykpCkJSSURHRSA9IG9zLnBhdGguam9p
>>"%B64%" echo bihIRVJFLCAiYnJpZGdlLmpzIikKT1VUID0gb3MucGF0aC5qb2luKEhFUkUsICJ1aSIsICJpbmRl
>>"%B64%" echo eC5odG1sIikKCk1BUksgPSAiPCEtLSBkZXNrdG9wLWJyaWRnZSAtLT4iCgoKZGVmIGZpbmRfc291
>>"%B64%" echo cmNlKCkgLT4gc3RyIHwgTm9uZToKICAgICIiIuybkOuzuCBIVE1MIOydhCDssL7sirXri4jri6Qu
>>"%B64%" echo CgogICAg6rCZ7J2AIO2PtOuNlOyXkCDrkZDqs6Ag7JOw64qUIOqyveyasOyZgCwg7KCA7J6l7IaM
>>"%B64%" echo 7LKY65+8IO2VnCDri6jqs4Qg7JyE7JeQIOuRkOuKlCDqsr3smrDqsIAg65GYIOuLpAogICAg7J6I
>>"%B64%" echo 7Iq164uI64ukLiDruIzrnbzsmrDsoIDqsIAg7J2066aEIOuSpOyXkCAoMSkg7J2EIOu2meyXrCDr
>>"%B64%" echo hpPslZjsnYQg7IiY64+EIOyeiOyWtCDqt7jqsoPrj4Qg67SF64uI64ukLgogICAgIiIiCiAgICBp
>>"%B64%" echo bXBvcnQgZ2xvYgogICAgZm9yIGQgaW4gKEhFUkUsIG9zLnBhdGguam9pbihIRVJFLCAiLi4iKSk6
>>"%B64%" echo CiAgICAgICAgZXhhY3QgPSBvcy5wYXRoLmpvaW4oZCwgInNwb3J0cy1haS1hbmFseXplci12NC5o
>>"%B64%" echo dG1sIikKICAgICAgICBpZiBvcy5wYXRoLmV4aXN0cyhleGFjdCk6CiAgICAgICAgICAgIHJldHVy
>>"%B64%" echo biBleGFjdAogICAgZm9yIGQgaW4gKEhFUkUsIG9zLnBhdGguam9pbihIRVJFLCAiLi4iKSk6CiAg
>>"%B64%" echo ICAgICAgaGl0cyA9IHNvcnRlZChnbG9iLmdsb2Iob3MucGF0aC5qb2luKGQsICIqYW5hbHl6ZXIq
>>"%B64%" echo Lmh0bWwiKSkpCiAgICAgICAgaGl0cyA9IFtoIGZvciBoIGluIGhpdHMgaWYgb3MucGF0aC5hYnNw
>>"%B64%" echo YXRoKGgpICE9IG9zLnBhdGguYWJzcGF0aChPVVQpXQogICAgICAgIGlmIGhpdHM6CiAgICAgICAg
>>"%B64%" echo ICAgIHJldHVybiBoaXRzWzBdCiAgICByZXR1cm4gTm9uZQoKCmRlZiBtYWluKCkgLT4gaW50Ogog
>>"%B64%" echo ICAgU1JDID0gZmluZF9zb3VyY2UoKQogICAgaWYgU1JDIGlzIE5vbmU6CiAgICAgICAgcHJpbnQo
>>"%B64%" echo IuybkOuzuCBIVE1MIOydhCDssL7sp4Ag66q77ZaI7Iq164uI64ukLiIpCiAgICAgICAgcHJpbnQo
>>"%B64%" echo IiAgc3BvcnRzLWFpLWFuYWx5emVyLXY0Lmh0bWwg7J2EIOydtCDtj7TrjZTrgpgg67CU66GcIOyc
>>"%B64%" echo hCDtj7TrjZTsl5Ag65GQ7IS47JqULiIpCiAgICAgICAgcHJpbnQoZiIgIOywvuyVhOuzuCDqs7M6
>>"%B64%" echo IHtIRVJFfSAg6re466as6rOgICB7b3MucGF0aC5hYnNwYXRoKG9zLnBhdGguam9pbihIRVJFLCAn
>>"%B64%" echo Li4nKSl9IikKICAgICAgICByZXR1cm4gMQogICAgcHJpbnQoZiLsm5Drs7g6IHtTUkN9IikKICAg
>>"%B64%" echo IGh0bWwgPSBvcGVuKFNSQywgZW5jb2Rpbmc9InV0Zi04IikucmVhZCgpCiAgICBicmlkZ2UgPSBv
>>"%B64%" echo cGVuKEJSSURHRSwgZW5jb2Rpbmc9InV0Zi04IikucmVhZCgpCgogICAgaWYgTUFSSyBpbiBodG1s
>>"%B64%" echo OgogICAgICAgIHByaW50KCLsm5Drs7jsl5Ag7J2066+4IOuLpOumrOqwgCDrk6TslrQg7J6I7Iq1
>>"%B64%" echo 64uI64ukLiDsm5Drs7jsnYAg7Iic7IiY7ZWcIOyDge2DnOuhnCDrkZDshLjsmpQuIikKICAgICAg
>>"%B64%" echo ICByZXR1cm4gMQogICAgaWYgIjwvYm9keT4iIG5vdCBpbiBodG1sOgogICAgICAgIHByaW50KCI8
>>"%B64%" echo L2JvZHk+IOulvCDssL7sp4Ag66q77ZW0IOuBvOybjCDrhKPsnYQg7J6Q66as6rCAIOyXhuyKteuL
>>"%B64%" echo iOuLpC4iKQogICAgICAgIHJldHVybiAxCgogICAgYmxvY2sgPSBmIlxue01BUkt9XG48c2NyaXB0
>>"%B64%" echo Plxue2JyaWRnZX1cbjwvc2NyaXB0PlxuIgogICAgaHRtbCA9IGh0bWwucmVwbGFjZSgiPC9ib2R5
>>"%B64%" echo PiIsIGJsb2NrICsgIjwvYm9keT4iLCAxKQoKICAgIG9zLm1ha2VkaXJzKG9zLnBhdGguZGlybmFt
>>"%B64%" echo ZShPVVQpLCBleGlzdF9vaz1UcnVlKQogICAgd2l0aCBvcGVuKE9VVCwgInciLCBlbmNvZGluZz0i
>>"%B64%" echo dXRmLTgiKSBhcyBmOgogICAgICAgIGYud3JpdGUoaHRtbCkKICAgIHByaW50KGYi66eM65Ok7JeI
>>"%B64%" echo 7Iq164uI64ukOiB7T1VUfSAgKHtsZW4oaHRtbCk6LH0g7J6QKSIpCiAgICByZXR1cm4gMAoKCmlm
>>"%B64%" echo IF9fbmFtZV9fID09ICJfX21haW5fXyI6CiAgICBzeXMuZXhpdChtYWluKCkpCg==
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:wr_req
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo IyDtmZTrqbQoSFRNTCnsnYQg7LC97JeQIOudhOyasOqzoCDtjIzsnbTsjazqs7wg7J207Ja0IOyj
>>"%B64%" echo vOuKlCDrj4TqtawuCiMg7JyI64+E7Jqw7JeQ7ISc64qUIHB5dGhvbm5ldCDsnYQg7ZWo6ruYIOuB
>>"%B64%" echo jOyWtOyYteuLiOuLpChFZGdlIFdlYlZpZXcyIOuwseyXlOuTnOyaqSkuCnB5d2Vidmlldz49NS4w
>>"%B64%" echo CgojIGV4ZSDroZwg66y27J2EIOuVjOunjCDtlYTsmpTtlanri4jri6QuIOqwnOuwnCDspJHsl5Dr
>>"%B64%" echo ipQg7JeG7Ja064+EIOuQqeuLiOuLpC4KcHlpbnN0YWxsZXI+PTYuMAoKIyDsl5Tsp4QoZW5naW5l
>>"%B64%" echo LnB5KeydgCDtkZzspIAg65287J2067iM65+s66as66eMIOyUgeuLiOuLpC4g7Jes6riw7JeQIOuN
>>"%B64%" echo lCDrhKPsnYQg6rKD7J20IOyXhuyKteuLiOuLpC4K
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:wr_rdm
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo IyDstpXqtawg67aE7ISd6riwIOKAlCDrsJTtg5XtmZTrqbQg7JWxCgpIVE1MIO2ZlOuptOydgCDq
>>"%B64%" echo t7jrjIDroZwg65GQ6rOgLCBBUEkg7KCR7IaN7J2EIO2MjOydtOyNrOydtCDrp6HripQg6rWs7KGw
>>"%B64%" echo 7J6F64uI64ukLgoKYGBgCiAgIHVpL2luZGV4Lmh0bWwgICAgICAgICAg4oaQIO2ZlOuptCAo6riw
>>"%B64%" echo 7KG0IEhUTUwgKyBicmlkZ2UuanMpCiAgICAgICAg4pSCICB3aW5kb3cucHl3ZWJ2aWV3LmFwaS5o
>>"%B64%" echo dHRwX2dldCguLi4pCiAgICAgICAg4pa8CiAgIGFwcC5weSAgIChweXdlYnZpZXcg7LC9KQogICAg
>>"%B64%" echo ICAgIOKUggogICAgICAgIOKWvAogICBlbmdpbmUucHkgICAgICAgICAgICAgIOKGkCDsi6TsoJwg
>>"%B64%" echo QVBJIO2YuOy2nCDCtyDtgqQg67O06rSAIMK3IOyerOyLnOuPhCDCtyDsp4Tri6gKICAgICAgICDi
>>"%B64%" echo lIIKICAgICAgICDilrwKICAgQVBJLUZvb3RiYWxsIMK3IGZvb3RiYWxsLWRhdGEub3JnIMK3IE9w
>>"%B64%" echo ZW5MaWdhREIgwrcgVGhlU3BvcnRzREIKYGBgCgojIyDsmZwg7J2066CH6rKMIOunjOuTnOuKlOqw
>>"%B64%" echo gAoK67iM65287Jqw7KCA66GcIEhUTUwg7J2EIOyXtOuptCBmb290YmFsbC1kYXRhLm9yZyDqsIAg
>>"%B64%" echo KipDT1JTIOuhnCDrp4ntnpnri4jri6QuKiog67iM65287Jqw7KCA6rCACuyVhOuLiOudvCDtjIzs
>>"%B64%" echo nbTsjazsnbQg7JqU7LKt7J2EIOuztOuCtOuptCBDT1JTIOudvOuKlCDqsJzrhZAg7J6Q7LK06rCA
>>"%B64%" echo IOyXhuyKteuLiOuLpC4g6re4656Y7IScIOydtCDqtazsobDsl5DshJzripQKCiogYGZkLXByb3h5
>>"%B64%" echo YCDrpbwg652E7Jq4IO2VhOyalOqwgCDsl4bsirXri4jri6QKKiA4Nzg3IO2PrO2KuOulvCDsl7Qg
>>"%B64%" echo 7ZWE7JqU6rCAIOyXhuyKteuLiOuLpAoqIO2UhOuhneyLnCDso7zshozrpbwg7J6F66Cl7ZWgIOy5
>>"%B64%" echo uOuPhCDsl4bsirXri4jri6QgKOyVseyXkOyEnCDsnpDrj5nsnLzroZwg7Iio6rmB64uI64ukKQoK
>>"%B64%" echo IyMg7YyM7J28Cgp8IO2MjOydvCB8IO2VmOuKlCDsnbwgfAp8LS0tfC0tLXwKfCBgZW5naW5lLnB5
>>"%B64%" echo YCB8IOyXlOynhC4gSFRUUCDtmLjstpwsIO2CpCDsoIDsnqUsIOyGjeuPhCDsoJztlZwsIOyerOyL
>>"%B64%" echo nOuPhCwg7KeE64uoLiAqKu2RnOykgCDrnbzsnbTruIzrn6zrpqzrp4wqKiDslIHri4jri6QgfAp8
>>"%B64%" echo IGBhcHAucHlgIHwgcHl3ZWJ2aWV3IOywveydhCDrnYTsmrDqs6AgYGVuZ2luZWAg7J2EIO2ZlOup
>>"%B64%" echo tOyXkCDrhbjstpztlZjripQg6ruN642w6riwIHwKfCBgYnJpZGdlLmpzYCB8IO2ZlOuptCDsqr0g
>>"%B64%" echo 64uk66asLiBgZmV0Y2hgIOulvCDtjIzsnbTsjazsnLzroZwg64+M66as6rOgIO2VhOyalCDsl4bs
>>"%B64%" echo lrTsp4QgVUkg66W8IOygleumrCB8CnwgYG1ha2VfdWkucHlgIHwgYC4uL3Nwb3J0cy1haS1hbmFs
>>"%B64%" echo eXplci12NC5odG1sYCArIGBicmlkZ2UuanNgIOKGkiBgdWkvaW5kZXguaHRtbGAgfAp8IGBidWls
>>"%B64%" echo ZC5iYXRgIHwgUHlJbnN0YWxsZXIg66GcIGDstpXqtazrtoTshJ3quLAuZXhlYCDrpbwg66eM65Ok
>>"%B64%" echo 7Ja0IOuwlO2Dle2ZlOuptOyXkCDrkaHri4jri6QgfAp8IGDsi6Ttlokt6rCc67Cc7JqpLmJhdGAg
>>"%B64%" echo fCBleGUg7JeG7J20IOuwlOuhnCDsi6TtlokgKOyImOygle2VmOuptOyEnCDrs7wg65WMKSB8Cgrs
>>"%B64%" echo m5Drs7ggSFRNTCDsnYAgKirqsbTrk5zrpqzsp4Ag7JWK7Iq164uI64ukLioqIO2ZlOuptOydhCDq
>>"%B64%" echo s6DsuZjroKTrqbQgYC4uL3Nwb3J0cy1haS1hbmFseXplci12NC5odG1sYArsnYQg6rOg7LmY6rOg
>>"%B64%" echo IGBweXRob24gbWFrZV91aS5weWAg66W8IOuLpOyLnCDrj4zrpqzrqbQg65Cp64uI64ukLgoKIyMg
>>"%B64%" echo 66eM65Oc64qUIOuylSAo7JyI64+E7JqwKSDigJQg7YyM7J28IOuRkCDqsJzrqbQg65Cp64uI64uk
>>"%B64%" echo Cgpg642w7Iqk7YGs7Yax7JWxLeunjOuTpOq4sC5iYXRgIOqzvCBgc3BvcnRzLWFpLWFuYWx5emVy
>>"%B64%" echo LXY0Lmh0bWxgIOydhCDtlZwg7Y+0642U7JeQIOuRkOqzoArrsLDsuZgg7YyM7J287J2EIOuNlOu4
>>"%B64%" echo lO2BtOumre2VmOyEuOyalC4g64KY66i47KeAIO2MjOydtOyNrCDtjIzsnbzsnYAg67Cw7LmYIO2M
>>"%B64%" echo jOydvCDslYjsl5Ag65Ok7Ja0IOyeiOyWtArsiqTsiqTroZwg6rq864OF64uI64ukLiDsi6Ttlont
>>"%B64%" echo lZjrqbQg65GQIOqwgOyngCDspJHsl5Ag6rOg66W06rKMIO2VqeuLiOuLpC4KCiAgICBbMV0g7KeA
>>"%B64%" echo 6riIIOuwlOuhnCDsi6TtlontlbQg67O06riwICAgICAgLSDshKTsuZggMzDstIjsr6QsIOywveyd
>>"%B64%" echo tCDrsJTroZwg65y564uI64ukCiAgICBbMl0g67CU7YOV7ZmU66m0IGV4ZSDrp4zrk6TquLAgICAg
>>"%B64%" echo ICAgIC0gMX4z67aELCDslYTsnbTsvZjsnbQg7IOd6rmB64uI64ukCgrrqLzsoIAgWzFdIOuhnCDs
>>"%B64%" echo npgg64+E64qU7KeAIOuztOqzoCwg66eI7J2M7JeQIOuTpOuptCBbMl0g66GcIGV4ZSDrpbwg66eM
>>"%B64%" echo 65Oc64qUIO2OuOydtCDsoovsirXri4jri6QuCgojIyDsoIDsnqXshozsl5DshJwg7KeB7KCRIOyT
>>"%B64%" echo uCDrlYwKCjEuIO2MjOydtOyNrCDshKTsuZgg4oCUIDxodHRwczovL3d3dy5weXRob24ub3JnL2Rv
>>"%B64%" echo d25sb2Fkcy8+CiAgIOyEpOy5mCDtmZTrqbTsl5DshJwgKioiQWRkIFB5dGhvbiB0byBQQVRIIioq
>>"%B64%" echo IOulvCDrsJjrk5zsi5wg7LK07YGsCjIuIOydtCDtj7TrjZTsl5DshJwgYGJ1aWxkLmJhdGAg642U
>>"%B64%" echo 67iU7YG066atCjMuIDF+M+u2hCDrkqQg67CU7YOV7ZmU66m07JeQIGDstpXqtazrtoTshJ3quLAu
>>"%B64%" echo ZXhlYCDqsIAg7IOd6rmB64uI64ukCjQuIOuNlOu4lO2BtOumrQoK66eM65Ok7KeAIOyViuqzoCDq
>>"%B64%" echo t7jrg6Ug7I2oIOuztOugpOuptCBg7Iuk7ZaJLeqwnOuwnOyaqS5iYXRgIOydhCDrjZTruJTtgbTr
>>"%B64%" echo pq3tlZjshLjsmpQuCgo+IOyciOuPhOyasCAxMMK3MTEg7J2AIEVkZ2UgV2ViVmlldzIg65+w7YOA
>>"%B64%" echo 7J6E7J20IOq4sOuzuOycvOuhnCDrk6TslrQg7J6I7Ja0IOuUsOuhnCDrsJvsnYQg6rKD7J20IOyX
>>"%B64%" echo huyKteuLiOuLpC4KPiDslYTso7wg7Jik656Y65CcIOyciOuPhOyasOudvOuptCBNaWNyb3NvZnQg
>>"%B64%" echo 7JeQ7IScICJFZGdlIFdlYlZpZXcyIFJ1bnRpbWUiIOydhCDtlZwg67KIIOyEpOy5mO2VmOuptCDr
>>"%B64%" echo kKnri4jri6QuCgojIyDtgqTripQg7Ja065SU7JeQIOyggOyepeuQmOuCmAoKYCVBUFBEQVRBJVxT
>>"%B64%" echo cG9ydHNBSUFuYWx5emVyXGtleXMuanNvbmAg4oCUIOuCtCDqs4TsoJXrp4wg7J297J2EIOyImCDs
>>"%B64%" echo nojripQg6raM7ZWcKDA2MDAp7Jy866GcIOyggOyepe2VqeuLiOuLpC4K7JWxIOyViOydmCAqKuyg
>>"%B64%" echo gOyepeuQnCDtgqQg7KeA7Jqw6riwKiog67KE7Yq87Jy866GcIOyWuOygnOuToCDsp4Dsmrgg7IiY
>>"%B64%" echo IOyeiOyKteuLiOuLpC4KCuqwgSDtgqTripQg6re4IO2CpOqwgCDsho3tlZwg7ISc67mE7Iqk66Gc
>>"%B64%" echo 66eMIOqwkeuLiOuLpC4gYGVuZ2luZS5weWAg6rCAIO2XpOuNlOulvCDrs7TrgrTquLAg7KCE7JeQ
>>"%B64%" echo IO2ZleyduO2VtOyEnCwK7JiI66W8IOuTpOyWtCBmb290YmFsbC1kYXRhLm9yZyDthqDtgbDsnbQg
>>"%B64%" echo VGhlU3BvcnRzREIg66GcIOqwgOuKlCDsnbzsnYAg7IOd6riw7KeAIOyViuyKteuLiOuLpC4KCiMj
>>"%B64%" echo IOustOyKqCDsnbzsnbQg7J6I7JeI64qU7KeAIOuztOugpOuptAoKYCVBUFBEQVRBJVxTcG9ydHNB
>>"%B64%" echo SUFuYWx5emVyXGFwcC5sb2dgIOKAlCDslbEg7JWI7J2YICoq6riw66GdIO2MjOydvCDsl7TquLAq
>>"%B64%" echo KiDrsoTtirzsnLzroZzrj4Qg7Je066a964uI64ukLgrslrTripAg7KO87IaM66W8IOu2iOuggOqz
>>"%B64%" echo oCDrqocg67KI7Ke47JeQIOyEseqzte2WiOuKlOyngCwg66y07JeH7J20IOuqhyDstIgg6riw64uk
>>"%B64%" echo 66C464qU7KeA6rCAIOuCqOyKteuLiOuLpC4K
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:end
echo.
pause
