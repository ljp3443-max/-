"""단일 실행 파일(.bat) 을 만듭니다.

안에 들어가는 것
  * server.ps1   (base64, certutil 로 꺼냄)
  * index.html   (base64, PowerShell 이 이 파일을 직접 읽어서 꺼냄)

사용자가 받는 것은 이 파일 하나뿐입니다.
"""
from __future__ import annotations

import base64
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "축구분석기.bat")
MARK = "::HTMLB64::"


def chunks(data: bytes, width: int = 76) -> list[str]:
    b = base64.b64encode(data).decode("ascii")
    return [b[i:i + width] for i in range(0, len(b), width)]


def main() -> int:
    ps = open(os.path.join(HERE, "server.ps1"), "rb").read()
    html = open(os.path.join(HERE, "index.html"), "rb").read()

    L: list[str] = []
    A = L.append
    A("@echo off")
    A("chcp 65001 >nul")
    A("title 축구 분석기")
    A("cd /d \"%~dp0\"")
    A("")
    A("echo.")
    A("echo   축구 분석기를 시작합니다...")
    A("echo.")
    A("")
    A("rem ---- 윈도우에 기본으로 들어 있는 PowerShell 을 찾습니다 ----")
    A("set \"PS=%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\"")
    A("if not exist \"%PS%\" set \"PS=powershell.exe\"")
    A("")
    A("rem ---- 서버 스크립트를 꺼냅니다 ----")
    A("set \"WORK=%TEMP%\\sports-ai-analyzer\"")
    A("if not exist \"%WORK%\" mkdir \"%WORK%\" >nul 2>nul")
    A("call :writeps \"%WORK%\\server.ps1\"")
    A("if not exist \"%WORK%\\server.ps1\" goto extractfail")
    A("")
    A("rem ---- 띄웁니다. 화면(HTML)은 이 파일 안에서 직접 읽어 갑니다. ----")
    A("\"%PS%\" -NoProfile -ExecutionPolicy Bypass -File \"%WORK%\\server.ps1\" -Source \"%~f0\"")
    A("if errorlevel 1 goto runfail")
    A("echo.")
    A("echo   프로그램이 종료됐습니다.")
    A("pause")
    A("exit /b 0")
    A("")
    A(":extractfail")
    A("echo.")
    A("echo [오류] 서버 파일을 꺼내지 못했습니다.")
    A("echo        %TEMP% 폴더에 쓸 수 없는 상태일 수 있습니다.")
    A("echo.")
    A("pause")
    A("exit /b 1")
    A("")
    A(":runfail")
    A("echo.")
    A("echo [오류] PowerShell 로 실행하지 못했습니다.")
    A("echo        위에 나온 메시지를 알려주시면 바로 잡겠습니다.")
    A("echo.")
    A("pause")
    A("exit /b 1")
    A("")
    A(":writeps")
    A("setlocal")
    A("set \"OUT=%~1\"")
    A("set \"B64=%~1.b64\"")
    A("if exist \"%B64%\" del \"%B64%\" >nul 2>nul")
    for c in chunks(ps):
        A(f">>\"%B64%\" echo {c}")
    A("certutil -f -decode \"%B64%\" \"%OUT%\" >nul 2>nul")
    A("rem certutil 이 막혀 있는 PC 도 있습니다. 그럴 때는 PowerShell 로 풉니다.")
    A("if not exist \"%OUT%\" \"%PS%\" -NoProfile -ExecutionPolicy Bypass -Command \"[IO.File]::WriteAllBytes('%OUT%',[Convert]::FromBase64String(((Get-Content -Raw '%B64%') -replace '\\s','')))\"")
    A("del \"%B64%\" >nul 2>nul")
    A("endlocal")
    A("goto :eof")
    A("")
    A(MARK)
    L.extend(chunks(html))
    A("")

    data = ("\r\n".join(L)).encode("utf-8")
    open(OUT, "wb").write(data)
    print(f"{OUT}  {len(data):,} bytes  {len(L)} lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
