@echo off
chcp 65001 >nul
title 축구 분석기 실행
cd /d "%~dp0"

echo ============================================
echo  축구 분석기 - 프록시와 함께 실행
echo ============================================
echo.

set "WORK=%TEMP%\fd-proxy"
if not exist "%WORK%" mkdir "%WORK%" >nul 2>nul

rem ---- 1) 이 폴더에서 프록시 파일 찾기 ----
set "PROXYJS="
set "PROXYPY="
if exist "fd-proxy.js" set "PROXYJS=%cd%\fd-proxy.js"
if not defined PROXYJS for /f "delims=" %%F in ('dir /b /o-d fd-proxy*.js 2^>nul') do if not defined PROXYJS set "PROXYJS=%cd%\%%F"
if exist "fd-proxy.py" set "PROXYPY=%cd%\fd-proxy.py"
if not defined PROXYPY for /f "delims=" %%F in ('dir /b /o-d fd-proxy*.py 2^>nul') do if not defined PROXYPY set "PROXYPY=%cd%\%%F"

rem ---- 2) 폴더에 없으면 이 배치 파일 안에 들어 있는 사본을 꺼냅니다 ----
if not defined PROXYJS echo [준비] 폴더에 프록시 파일이 없어 내장된 사본을 꺼냅니다.
if not defined PROXYJS call :writejs "%WORK%\fd-proxy.js"
if not defined PROXYJS if exist "%WORK%\fd-proxy.js" set "PROXYJS=%WORK%\fd-proxy.js"
if not defined PROXYPY call :writepy "%WORK%\fd-proxy.py"
if not defined PROXYPY if exist "%WORK%\fd-proxy.py" set "PROXYPY=%WORK%\fd-proxy.py"

rem ---- 3) 분석기 HTML 찾기 (다운로드 중복으로 (1) 이 붙어도 찾습니다) ----
set "HTMLFILE="
if exist "sports-ai-analyzer-v4.html" set "HTMLFILE=sports-ai-analyzer-v4.html"
if not defined HTMLFILE for /f "delims=" %%F in ('dir /b /o-d *analyzer*.html 2^>nul') do if not defined HTMLFILE set "HTMLFILE=%%F"

rem ---- 4) 실행할 런타임 정하기 ----
set "RUNTIME="
if defined PROXYJS where node >nul 2>nul && set "RUNTIME=node"
if not defined RUNTIME if defined PROXYPY where py >nul 2>nul && set "RUNTIME=py"
if not defined RUNTIME if defined PROXYPY where python >nul 2>nul && set "RUNTIME=python"
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
echo   * 잘 되는지 보려면 브라우저 주소창에:
echo       http://127.0.0.1:8787/__ping
echo  ----------------------------------------
goto end

:nohtml
echo.
echo [오류] 분석기 HTML 파일을 찾지 못했습니다.
echo        sports-ai-analyzer-v4.html 을 이 폴더에 함께 두세요.
echo        프록시는 켜져 있으니, HTML 을 넣고 다시 실행하면 됩니다.
echo.
echo        지금 폴더: %cd%
echo        이 폴더에 있는 파일:
dir /b
goto end

:noruntime
echo.
echo [오류] 프록시를 띄울 수 없습니다.
echo.
echo        프록시 파일은 이 배치 파일 안에 들어 있어서 따로 받을 필요가 없습니다.
echo        그런데 이 PC 에서 Node.js 도 Python 도 찾지 못했습니다.
echo.
echo        확인 방법 - 이 창에서 아래를 직접 쳐 보세요:
echo            node -v
echo            python --version
echo        둘 다 오류가 나면 둘 중 하나를 설치하면 됩니다.
echo            Node.js:  https://nodejs.org  (LTS)
echo.
echo        지금 폴더: %cd%
echo        이 폴더에 있는 파일:
dir /b
echo.
echo   프록시 없이 분석기만 써도 됩니다.
echo   football-data.org 토큰 칸을 비워 두면 나머지 세 소스로 정상 동작합니다.
if defined HTMLFILE echo.
if defined HTMLFILE echo   분석기만 열려면 아무 키나 누르세요.
if defined HTMLFILE pause >nul
if defined HTMLFILE start "" "%HTMLFILE%"
goto end

:writejs
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo Ly8gZm9vdGJhbGwtZGF0YS5vcmcg66Gc7LusIENPUlMg7ZSE66Gd7IucCi8vIC0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCi8vIGZvb3Ri
>>"%B64%" echo YWxsLWRhdGEub3Jn64qUIOyEnOuyhOyaqSBBUEnrnbwg67iM65287Jqw7KCA7JeQ7IScIOyngeyg
>>"%B64%" echo kSDrtoDrpbTrqbQgQ09SU+uhnCDrp4ntnpnri4jri6QuCi8vIOydtCDsiqTtgazrpr3tirjrpbwg
>>"%B64%" echo 64K0IFBD7JeQ7IScIOudhOyasOuptCDruIzrnbzsmrDsoIDripQgbG9jYWxob3N066W8IOu2gOul
>>"%B64%" echo tOqzoCwKLy8g7Iuk7KCcIOyalOyyreydgCDsnbQg7ZSE66Gc6re4656o7J20IOuMgOyLoCDrs7Tr
>>"%B64%" echo g4Xri4jri6QuIO2GoO2BsOydgCDrgrQgUEMg67CW7Jy866GcIOuCmOqwgOyngCDslYrsirXri4jr
>>"%B64%" echo i6QuCi8vCi8vIOyLpO2WiTogIG5vZGUgZmQtcHJveHkuanMKLy8g7ZmV7J24OiAg67iM65287Jqw
>>"%B64%" echo 7KCAIOyjvOyGjOywveyXkCBodHRwOi8vMTI3LjAuMC4xOjg3ODcvX19waW5nCi8vIOu2hOyEneq4
>>"%B64%" echo sCAi7ZSE66Gd7IucIOyjvOyGjCIg7Lm47JeQOiAgaHR0cDovLzEyNy4wLjAuMTo4Nzg3Ci8vIO2P
>>"%B64%" echo rO2KuCDrsJTqvrjquLA6ICBQT1JUPTkwMDAgbm9kZSBmZC1wcm94eS5qcyAgICjsnIjrj4TsmrA6
>>"%B64%" echo IHNldCBQT1JUPTkwMDAgJiYgbm9kZSBmZC1wcm94eS5qcykKLy8g64GE6riwOiAg7J20IOywveyX
>>"%B64%" echo kOyEnCBDdHJsK0MKLy8gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0KY29uc3QgaHR0cCA9IHJlcXVpcmUoJ2h0dHAnKTsKY29uc3QgaHR0
>>"%B64%" echo cHMgPSByZXF1aXJlKCdodHRwcycpOwoKY29uc3QgUE9SVCA9IE51bWJlcihwcm9jZXNzLmVudi5Q
>>"%B64%" echo T1JUIHx8IDg3ODcpOwpjb25zdCBVUFNUUkVBTSA9ICdhcGkuZm9vdGJhbGwtZGF0YS5vcmcnOwoK
>>"%B64%" echo Y29uc3QgQ09SUyA9IHsKICAnQWNjZXNzLUNvbnRyb2wtQWxsb3ctT3JpZ2luJzogJyonLAogICdB
>>"%B64%" echo Y2Nlc3MtQ29udHJvbC1BbGxvdy1IZWFkZXJzJzogJ1gtQXV0aC1Ub2tlbiwgQ29udGVudC1UeXBl
>>"%B64%" echo JywKICAnQWNjZXNzLUNvbnRyb2wtQWxsb3ctTWV0aG9kcyc6ICdHRVQsIE9QVElPTlMnLAogICdB
>>"%B64%" echo Y2Nlc3MtQ29udHJvbC1NYXgtQWdlJzogJzg2NDAwJwp9OwoKZnVuY3Rpb24gaGFuZGxlcihyZXEs
>>"%B64%" echo IHJlcykgewogIC8vIOu4jOudvOyasOyggOuKlCBYLUF1dGgtVG9rZW4g6rCZ7J2AIOy7pOyKpO2F
>>"%B64%" echo gCDtl6TrjZQg65WM66y47JeQIOuovOyggCBPUFRJT05T66W8IOuztOuDheuLiOuLpC4KICBpZiAo
>>"%B64%" echo cmVxLm1ldGhvZCA9PT0gJ09QVElPTlMnKSB7IHJlcy53cml0ZUhlYWQoMjA0LCBDT1JTKTsgcmV0
>>"%B64%" echo dXJuIHJlcy5lbmQoKTsgfQoKICAvLyDtlITroZ3si5zqsIAg7IK07JWEIOyeiOuKlOyngCDtmZXs
>>"%B64%" echo nbjtlZjripQg7Jqp64+ELiDthqDtgbDsnbQg7ZWE7JqUIOyXhuyKteuLiOuLpC4KICBpZiAocmVx
>>"%B64%" echo LnVybCA9PT0gJy9fX3BpbmcnKSB7CiAgICByZXMud3JpdGVIZWFkKDIwMCwgeyAuLi5DT1JTLCAn
>>"%B64%" echo Q29udGVudC1UeXBlJzogJ2FwcGxpY2F0aW9uL2pzb247IGNoYXJzZXQ9dXRmLTgnIH0pOwogICAg
>>"%B64%" echo cmV0dXJuIHJlcy5lbmQoSlNPTi5zdHJpbmdpZnkoeyBvazogdHJ1ZSwgcHJveHk6ICdmZC1wcm94
>>"%B64%" echo eScsIHVwc3RyZWFtOiBVUFNUUkVBTSwgcG9ydDogUE9SVCB9KSk7CiAgfQoKICBpZiAocmVxLm1l
>>"%B64%" echo dGhvZCAhPT0gJ0dFVCcpIHsKICAgIHJlcy53cml0ZUhlYWQoNDA1LCB7IC4uLkNPUlMsICdDb250
>>"%B64%" echo ZW50LVR5cGUnOiAnYXBwbGljYXRpb24vanNvbicgfSk7CiAgICByZXR1cm4gcmVzLmVuZChKU09O
>>"%B64%" echo LnN0cmluZ2lmeSh7IG1lc3NhZ2U6ICdHRVTrp4wg7KeA7JuQ7ZWp64uI64ukLicgfSkpOwogIH0K
>>"%B64%" echo CiAgY29uc3QgdG9rZW4gPSByZXEuaGVhZGVyc1sneC1hdXRoLXRva2VuJ10gfHwgJyc7CiAgY29u
>>"%B64%" echo c3Qgc3RhcnRlZCA9IERhdGUubm93KCk7CiAgY29uc3QgdXBzdHJlYW0gPSBodHRwcy5yZXF1ZXN0
>>"%B64%" echo KHsKICAgIGhvc3RuYW1lOiBVUFNUUkVBTSwgcGF0aDogcmVxLnVybCwgbWV0aG9kOiAnR0VUJywK
>>"%B64%" echo ICAgIGhlYWRlcnM6IHsgJ1gtQXV0aC1Ub2tlbic6IHRva2VuLCAnQWNjZXB0JzogJ2FwcGxpY2F0
>>"%B64%" echo aW9uL2pzb24nIH0KICB9LCByID0+IHsKICAgIGNvbnNvbGUubG9nKGAgICR7ci5zdGF0dXNDb2Rl
>>"%B64%" echo fSAgJHtyZXEudXJsfSAgKCR7RGF0ZS5ub3coKSAtIHN0YXJ0ZWR9bXMpYCk7CiAgICByZXMud3Jp
>>"%B64%" echo dGVIZWFkKHIuc3RhdHVzQ29kZSB8fCA1MDIsIHsgLi4uQ09SUywgJ0NvbnRlbnQtVHlwZSc6ICdh
>>"%B64%" echo cHBsaWNhdGlvbi9qc29uOyBjaGFyc2V0PXV0Zi04JyB9KTsKICAgIHIucGlwZShyZXMpOwogIH0p
>>"%B64%" echo OwoKICB1cHN0cmVhbS5vbignZXJyb3InLCBlID0+IHsKICAgIGNvbnNvbGUubG9nKGAgIOyLpO2M
>>"%B64%" echo qCAgJHtyZXEudXJsfSAgJHtlLm1lc3NhZ2V9YCk7CiAgICByZXMud3JpdGVIZWFkKDUwMiwgeyAu
>>"%B64%" echo Li5DT1JTLCAnQ29udGVudC1UeXBlJzogJ2FwcGxpY2F0aW9uL2pzb24nIH0pOwogICAgcmVzLmVu
>>"%B64%" echo ZChKU09OLnN0cmluZ2lmeSh7IG1lc3NhZ2U6ICd1cHN0cmVhbSDsl7DqsrAg7Iuk7YyoOiAnICsg
>>"%B64%" echo ZS5tZXNzYWdlIH0pKTsKICB9KTsKICB1cHN0cmVhbS5lbmQoKTsKfQoKLy8gbG9jYWxob3N0IOqw
>>"%B64%" echo gCA6OjEoSVB2NinroZwg66i87KCAIO2VtOyEneuQmOuKlCBQQ+qwgCDsnojsirXri4jri6QuIElQ
>>"%B64%" echo djTsl5Drp4wg67CU7J2465Sp7ZWY66m0Ci8vIOq3uOufsCDtmZjqsr3sl5DshJwg7Jew6rKw7J20
>>"%B64%" echo IOyLpO2MqO2VmOuvgOuhnCDrkZAg7KO87IaMIOuqqOuRkOyXkOyEnCDrsJvsirXri4jri6QuCmxl
>>"%B64%" echo dCB1cCA9IDAsIGRvbmUgPSAwOwpjb25zdCBob3N0cyA9IFsnMTI3LjAuMC4xJywgJzo6MSddOwpo
>>"%B64%" echo b3N0cy5mb3JFYWNoKGhvc3QgPT4gewogIGNvbnN0IHMgPSBodHRwLmNyZWF0ZVNlcnZlcihoYW5k
>>"%B64%" echo bGVyKTsKICBzLm9uKCdlcnJvcicsIGUgPT4gewogICAgZG9uZSsrOwogICAgaWYgKGUuY29kZSA9
>>"%B64%" echo PT0gJ0VBRERSSU5VU0UnKSB7CiAgICAgIGNvbnNvbGUuZXJyb3IoYFxuW+yYpOulmF0g7Y+s7Yq4
>>"%B64%" echo ICR7UE9SVH3snYQg7J2066+4IOuLpOuluCDtlITroZzqt7jrnqjsnbQg7JOw6rOgIOyeiOyKteuL
>>"%B64%" echo iOuLpC5gKTsKICAgICAgY29uc29sZS5lcnJvcihgICAgICAgIOuLpOuluCDtj6ztirjroZw6IFBP
>>"%B64%" echo UlQ9OTAwMCBub2RlIGZkLXByb3h5LmpzYCk7CiAgICAgIGNvbnNvbGUuZXJyb3IoYCAgICAgICAo
>>"%B64%" echo 7JyI64+E7JqwKSBzZXQgUE9SVD05MDAwICYmIG5vZGUgZmQtcHJveHkuanNgKTsKICAgICAgcHJv
>>"%B64%" echo Y2Vzcy5leGl0KDEpOwogICAgfQogICAgLy8gSVB2NuulvCDrqrsg7JOw64qUIFBD64qUIOyhsOya
>>"%B64%" echo qe2eiCDrhJjslrTqsJHri4jri6QgKElQdjTroZwg7Lap67aE7ZWp64uI64ukKS4KICAgIGlmICgh
>>"%B64%" echo WydFQUZOT1NVUFBPUlQnLCAnRUFERFJOT1RBVkFJTCcsICdFSU5WQUwnXS5pbmNsdWRlcyhlLmNv
>>"%B64%" echo ZGUpKQogICAgICBjb25zb2xlLmVycm9yKGAgICR7aG9zdH0g67CU7J2465SpIOyLpO2MqDogJHtl
>>"%B64%" echo LmNvZGV9YCk7CiAgICBmaW5pc2goKTsKICB9KTsKICBzLmxpc3RlbihQT1JULCBob3N0LCAoKSA9
>>"%B64%" echo PiB7IHVwKys7IGRvbmUrKzsgZmluaXNoKCk7IH0pOwp9KTsKCmZ1bmN0aW9uIGZpbmlzaCgpIHsK
>>"%B64%" echo ICBpZiAoZG9uZSA8IGhvc3RzLmxlbmd0aCkgcmV0dXJuOwogIGlmICghdXApIHsgY29uc29sZS5l
>>"%B64%" echo cnJvcignXG5b7Jik66WYXSDslrTrlqQg7KO87IaM7JeQ64+EIOuwlOyduOuUqe2VmOyngCDrqrvt
>>"%B64%" echo lojsirXri4jri6QuJyk7IHByb2Nlc3MuZXhpdCgxKTsgfQogIGNvbnNvbGUubG9nKCdmb290YmFs
>>"%B64%" echo bC1kYXRhLm9yZyDtlITroZ3si5wg7Iuk7ZaJIOykkScpOwogIGNvbnNvbGUubG9nKGAgIGh0dHA6
>>"%B64%" echo Ly8xMjcuMC4wLjE6JHtQT1JUfSAgLT4gIGh0dHBzOi8vJHtVUFNUUkVBTX1gKTsKICBjb25zb2xl
>>"%B64%" echo LmxvZyhgICDsgrTslYTsnojripTsp4Ag7ZmV7J24OiAgaHR0cDovLzEyNy4wLjAuMToke1BPUlR9
>>"%B64%" echo L19fcGluZ2ApOwogIGNvbnNvbGUubG9nKCcgIOu2hOyEneq4sOydmCAi7ZSE66Gd7IucIOyjvOyG
>>"%B64%" echo jCIg7Lm47JeQIOychCDso7zshozrpbwg64Sj7Jy87IS47JqULiDrgYTroKTrqbQgQ3RybCtDLlxu
>>"%B64%" echo Jyk7Cn0K
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:writepy
setlocal
set "OUT=%~1"
set "B64=%~1.b64"
if exist "%B64%" del "%B64%" >nul 2>nul
>>"%B64%" echo IyBmb290YmFsbC1kYXRhLm9yZyDroZzsu6wgQ09SUyDtlITroZ3si5wgKO2MjOydtOyNrCDtkZzs
>>"%B64%" echo pIAg65287J2067iM65+s66as66eMIOyCrOyaqSkKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIGZvb3RiYWxsLWRhdGEub3Jn64qU
>>"%B64%" echo IOyEnOuyhOyaqSBBUEnrnbwg67iM65287Jqw7KCA7JeQ7IScIOyngeygkSDrtoDrpbTrqbQgQ09S
>>"%B64%" echo U+uhnCDrp4ntnpnri4jri6QuCiMg7J20IOyKpO2BrOumve2KuOulvCDrgrQgUEPsl5DshJwg652E
>>"%B64%" echo 7Jqw66m0IOu4jOudvOyasOyggOuKlCBsb2NhbGhvc3Trpbwg67aA66W06rOgLAojIOyLpOygnCDs
>>"%B64%" echo mpTssq3snYAg7J20IO2UhOuhnOq3uOueqOydtCDrjIDsi6Ag67O064OF64uI64ukLiDthqDtgbDs
>>"%B64%" echo nYAg64K0IFBDIOuwluycvOuhnCDrgpjqsIDsp4Ag7JWK7Iq164uI64ukLgojCiMg7Iuk7ZaJOiAg
>>"%B64%" echo cHl0aG9uIGZkLXByb3h5LnB5ICAgICAgICAo7JyI64+E7Jqw7JeQ7ISc64qUIHB5IGZkLXByb3h5
>>"%B64%" echo LnB5KQojIO2ZleyduDogIOu4jOudvOyasOyggCDso7zshozssL3sl5AgaHR0cDovLzEyNy4wLjAu
>>"%B64%" echo MTo4Nzg3L19fcGluZwojIOu2hOyEneq4sCAi7ZSE66Gd7IucIOyjvOyGjCIg7Lm47JeQOiAgaHR0
>>"%B64%" echo cDovLzEyNy4wLjAuMTo4Nzg3CiMg7Y+s7Yq4IOuwlOq+uOq4sDogIFBPUlQ9OTAwMCBweXRob24g
>>"%B64%" echo ZmQtcHJveHkucHkKIyDrgYTquLA6ICDsnbQg7LC97JeQ7IScIEN0cmwrQwojIC0tLS0tLS0tLS0t
>>"%B64%" echo LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCmltcG9ydCBo
>>"%B64%" echo dHRwLnNlcnZlciwgdXJsbGliLnJlcXVlc3QsIHVybGxpYi5lcnJvciwganNvbiwgb3MsIHNvY2tl
>>"%B64%" echo dCwgc3lzLCB0aHJlYWRpbmcsIHRpbWUKClBPUlQgPSBpbnQob3MuZW52aXJvbi5nZXQoJ1BPUlQn
>>"%B64%" echo LCA4Nzg3KSkKVVBTVFJFQU0gPSAnaHR0cHM6Ly9hcGkuZm9vdGJhbGwtZGF0YS5vcmcnClVQU1RS
>>"%B64%" echo RUFNX0hPU1QgPSAnYXBpLmZvb3RiYWxsLWRhdGEub3JnJwoKY2xhc3MgSGFuZGxlcihodHRwLnNl
>>"%B64%" echo cnZlci5CYXNlSFRUUFJlcXVlc3RIYW5kbGVyKToKICAgIHByb3RvY29sX3ZlcnNpb24gPSAnSFRU
>>"%B64%" echo UC8xLjEnCgogICAgZGVmIF9jb3JzKHNlbGYpOgogICAgICAgIHNlbGYuc2VuZF9oZWFkZXIoJ0Fj
>>"%B64%" echo Y2Vzcy1Db250cm9sLUFsbG93LU9yaWdpbicsICcqJykKICAgICAgICBzZWxmLnNlbmRfaGVhZGVy
>>"%B64%" echo KCdBY2Nlc3MtQ29udHJvbC1BbGxvdy1IZWFkZXJzJywgJ1gtQXV0aC1Ub2tlbiwgQ29udGVudC1U
>>"%B64%" echo eXBlJykKICAgICAgICBzZWxmLnNlbmRfaGVhZGVyKCdBY2Nlc3MtQ29udHJvbC1BbGxvdy1NZXRo
>>"%B64%" echo b2RzJywgJ0dFVCwgT1BUSU9OUycpCiAgICAgICAgc2VsZi5zZW5kX2hlYWRlcignQWNjZXNzLUNv
>>"%B64%" echo bnRyb2wtTWF4LUFnZScsICc4NjQwMCcpCgogICAgZGVmIF9zZW5kKHNlbGYsIGNvZGUsIGJvZHkp
>>"%B64%" echo OgogICAgICAgIHNlbGYuc2VuZF9yZXNwb25zZShjb2RlKQogICAgICAgIHNlbGYuX2NvcnMoKQog
>>"%B64%" echo ICAgICAgIHNlbGYuc2VuZF9oZWFkZXIoJ0NvbnRlbnQtVHlwZScsICdhcHBsaWNhdGlvbi9qc29u
>>"%B64%" echo OyBjaGFyc2V0PXV0Zi04JykKICAgICAgICBzZWxmLnNlbmRfaGVhZGVyKCdDb250ZW50LUxlbmd0
>>"%B64%" echo aCcsIHN0cihsZW4oYm9keSkpKQogICAgICAgIHNlbGYuZW5kX2hlYWRlcnMoKQogICAgICAgIHNl
>>"%B64%" echo bGYud2ZpbGUud3JpdGUoYm9keSkKCiAgICAjIOu4jOudvOyasOyggOuKlCBYLUF1dGgtVG9rZW4g
>>"%B64%" echo 6rCZ7J2AIOy7pOyKpO2FgCDtl6TrjZQg65WM66y47JeQIOuovOyggCBPUFRJT05T66W8IOuztOuD
>>"%B64%" echo heuLiOuLpC4KICAgIGRlZiBkb19PUFRJT05TKHNlbGYpOgogICAgICAgIHNlbGYuc2VuZF9yZXNw
>>"%B64%" echo b25zZSgyMDQpOyBzZWxmLl9jb3JzKCkKICAgICAgICBzZWxmLnNlbmRfaGVhZGVyKCdDb250ZW50
>>"%B64%" echo LUxlbmd0aCcsICcwJyk7IHNlbGYuZW5kX2hlYWRlcnMoKQoKICAgIGRlZiBkb19HRVQoc2VsZik6
>>"%B64%" echo CiAgICAgICAgIyDtlITroZ3si5zqsIAg7IK07JWEIOyeiOuKlOyngCDtmZXsnbjtlZjripQg7Jqp
>>"%B64%" echo 64+ELiDthqDtgbDsnbQg7ZWE7JqUIOyXhuyKteuLiOuLpC4KICAgICAgICBpZiBzZWxmLnBhdGgg
>>"%B64%" echo PT0gJy9fX3BpbmcnOgogICAgICAgICAgICByZXR1cm4gc2VsZi5fc2VuZCgyMDAsIGpzb24uZHVt
>>"%B64%" echo cHMoCiAgICAgICAgICAgICAgICB7J29rJzogVHJ1ZSwgJ3Byb3h5JzogJ2ZkLXByb3h5JywgJ3Vw
>>"%B64%" echo c3RyZWFtJzogVVBTVFJFQU1fSE9TVCwgJ3BvcnQnOiBQT1JUfSkuZW5jb2RlKCkpCgogICAgICAg
>>"%B64%" echo IHN0YXJ0ZWQgPSB0aW1lLnRpbWUoKQogICAgICAgIHJlcSA9IHVybGxpYi5yZXF1ZXN0LlJlcXVl
>>"%B64%" echo c3QoCiAgICAgICAgICAgIFVQU1RSRUFNICsgc2VsZi5wYXRoLAogICAgICAgICAgICBoZWFkZXJz
>>"%B64%" echo PXsnWC1BdXRoLVRva2VuJzogc2VsZi5oZWFkZXJzLmdldCgnWC1BdXRoLVRva2VuJywgJycpLAog
>>"%B64%" echo ICAgICAgICAgICAgICAgICAgICAnQWNjZXB0JzogJ2FwcGxpY2F0aW9uL2pzb24nfSkKICAgICAg
>>"%B64%" echo ICB0cnk6CiAgICAgICAgICAgIHdpdGggdXJsbGliLnJlcXVlc3QudXJsb3BlbihyZXEsIHRpbWVv
>>"%B64%" echo dXQ9MzApIGFzIHI6CiAgICAgICAgICAgICAgICBib2R5LCBjb2RlID0gci5yZWFkKCksIHIuc3Rh
>>"%B64%" echo dHVzCiAgICAgICAgZXhjZXB0IHVybGxpYi5lcnJvci5IVFRQRXJyb3IgYXMgZToKICAgICAgICAg
>>"%B64%" echo ICAgYm9keSwgY29kZSA9IGUucmVhZCgpLCBlLmNvZGUKICAgICAgICBleGNlcHQgRXhjZXB0aW9u
>>"%B64%" echo IGFzIGU6CiAgICAgICAgICAgIGJvZHksIGNvZGUgPSBqc29uLmR1bXBzKHsnbWVzc2FnZSc6ICd1
>>"%B64%" echo cHN0cmVhbSDsl7DqsrAg7Iuk7YyoOiAlcycgJSBlfSkuZW5jb2RlKCksIDUwMgogICAgICAgIHBy
>>"%B64%" echo aW50KCcgICVzICAlcyAgKCVkbXMpJyAlIChjb2RlLCBzZWxmLnBhdGgsICh0aW1lLnRpbWUoKSAt
>>"%B64%" echo IHN0YXJ0ZWQpICogMTAwMCkpCiAgICAgICAgc2VsZi5fc2VuZChjb2RlLCBib2R5KQoKICAgIGRl
>>"%B64%" echo ZiBsb2dfbWVzc2FnZShzZWxmLCAqYXJncyk6CiAgICAgICAgcGFzcwoKY2xhc3MgVjZTZXJ2ZXIo
>>"%B64%" echo aHR0cC5zZXJ2ZXIuVGhyZWFkaW5nSFRUUFNlcnZlcik6CiAgICBhZGRyZXNzX2ZhbWlseSA9IHNv
>>"%B64%" echo Y2tldC5BRl9JTkVUNgoKc2VydmVycyA9IFtdCnRyeToKICAgIHNlcnZlcnMuYXBwZW5kKGh0dHAu
>>"%B64%" echo c2VydmVyLlRocmVhZGluZ0hUVFBTZXJ2ZXIoKCcxMjcuMC4wLjEnLCBQT1JUKSwgSGFuZGxlcikp
>>"%B64%" echo CmV4Y2VwdCBPU0Vycm9yIGFzIGU6CiAgICBwcmludCgnXG5b7Jik66WYXSDtj6ztirggJWQg67CU
>>"%B64%" echo 7J2465SpIOyLpO2MqDogJXMnICUgKFBPUlQsIGUpKQogICAgcHJpbnQoJyAgICAgICDsnbTrr7gg
>>"%B64%" echo 64uk66W4IO2UhOuhnOq3uOueqOydtCDsk7Dqs6Ag7J6I64uk66m0IOuLpOuluCDtj6ztirjroZw6
>>"%B64%" echo IFBPUlQ9OTAwMCBweXRob24gZmQtcHJveHkucHknKQogICAgc3lzLmV4aXQoMSkKCiMgbG9jYWxo
>>"%B64%" echo b3N0IOqwgCA6OjEoSVB2NinroZwg66i87KCAIO2VtOyEneuQmOuKlCBQQ+qwgCDsnojsirXri4jr
>>"%B64%" echo i6QuIElQdjTsl5Drp4wg67CU7J2465Sp7ZWY66m0CiMg6re465+wIO2ZmOqyveyXkOyEnCDsl7Dq
>>"%B64%" echo srDsnbQg7Iuk7Yyo7ZWY66+A66GcIOuRkCDso7zshowg66qo65GQ7JeQ7IScIOuwm+yKteuLiOuL
>>"%B64%" echo pC4KaWYgc29ja2V0Lmhhc19pcHY2OgogICAgdHJ5OgogICAgICAgIHNlcnZlcnMuYXBwZW5kKFY2
>>"%B64%" echo U2VydmVyKCgnOjoxJywgUE9SVCksIEhhbmRsZXIpKQogICAgZXhjZXB0IE9TRXJyb3I6CiAgICAg
>>"%B64%" echo ICAgcGFzcyAgICMgSVB2NuulvCDrqrsg7JOw64qUIFBD64qUIElQdjTroZwg7Lap67aE7ZWp64uI
>>"%B64%" echo 64ukCgpwcmludCgnZm9vdGJhbGwtZGF0YS5vcmcg7ZSE66Gd7IucIOyLpO2WiSDspJEnKQpwcmlu
>>"%B64%" echo dCgnICBodHRwOi8vMTI3LjAuMC4xOiVkICAtPiAgJXMnICUgKFBPUlQsIFVQU1RSRUFNKSkKcHJp
>>"%B64%" echo bnQoJyAg7IK07JWE7J6I64qU7KeAIO2ZleyduDogIGh0dHA6Ly8xMjcuMC4wLjE6JWQvX19waW5n
>>"%B64%" echo JyAlIFBPUlQpCnByaW50KCcgIOu2hOyEneq4sOydmCAi7ZSE66Gd7IucIOyjvOyGjCIg7Lm47JeQ
>>"%B64%" echo IOychCDso7zshozrpbwg64Sj7Jy87IS47JqULiDrgYTroKTrqbQgQ3RybCtDLlxuJykKCmZvciBz
>>"%B64%" echo IGluIHNlcnZlcnNbMTpdOgogICAgdGhyZWFkaW5nLlRocmVhZCh0YXJnZXQ9cy5zZXJ2ZV9mb3Jl
>>"%B64%" echo dmVyLCBkYWVtb249VHJ1ZSkuc3RhcnQoKQp0cnk6CiAgICBzZXJ2ZXJzWzBdLnNlcnZlX2ZvcmV2
>>"%B64%" echo ZXIoKQpleGNlcHQgS2V5Ym9hcmRJbnRlcnJ1cHQ6CiAgICBwcmludCgnXG7tlITroZ3si5zrpbwg
>>"%B64%" echo 7KKF66OM7ZaI7Iq164uI64ukLicpCg==
certutil -f -decode "%B64%" "%OUT%" >nul 2>nul
del "%B64%" >nul 2>nul
endlocal
goto :eof

:end
echo.
pause
