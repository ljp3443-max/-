"""축구 분석기 — 바탕화면 앱.

화면은 ui/index.html (기존 HTML 그대로), 엔진은 engine.py.
이 파일은 둘을 붙여 창 하나로 띄우는 얇은 껍데기입니다.

개발 중 실행:  python app.py
exe 로 묶기:   build.bat
"""

from __future__ import annotations

import os
import sys
import threading
import webbrowser

import engine

# pywebview 는 창을 띄울 때에만 필요합니다. 없다고 해서 import 만으로 죽으면
# 엔진을 따로 시험해 볼 수 없으므로, 없으면 None 으로 두고 main() 에서만 따집니다.
try:
    import webview  # pywebview
except ImportError:
    webview = None


def resource_dir() -> str:
    """개발 중에는 이 파일 옆, exe 로 묶은 뒤에는 풀린 임시 폴더."""
    return getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))


def ui_path() -> str:
    p = os.path.join(resource_dir(), "ui", "index.html")
    if not os.path.exists(p):
        raise SystemExit(f"화면 파일을 찾지 못했습니다: {p}")
    return p


class Api:
    """화면에서 window.pywebview.api.<이름>(...) 으로 부르는 것들.

    돌려주는 값은 전부 JSON 으로 오가므로 dict / list / 기본형만 씁니다.
    예외를 밖으로 내보내지 않습니다 — 던지면 화면 쪽 Promise 가 조용히 죽습니다.
    """

    def __init__(self) -> None:
        self.window = None

    # ---- 바깥세상 ----------------------------------------------------
    def http_get(self, url: str, headers: dict | None = None) -> dict:
        try:
            return engine.http_get(url, headers or {})
        except Exception as e:                     # 여기서 막지 않으면 화면이 멈춥니다
            engine.log(f"http_get 예외: {e!r}")
            return {"ok": False, "status": 0, "body": "", "error": str(e)}

    def probe(self, keys: dict | None = None) -> dict:
        try:
            return {"ok": True, "results": engine.probe(keys or {})}
        except Exception as e:
            engine.log(f"probe 예외: {e!r}")
            return {"ok": False, "error": str(e), "results": []}

    # ---- 내 PC -------------------------------------------------------
    def load_keys(self) -> dict:
        try:
            return {"ok": True, "keys": engine.load_keys()}
        except Exception as e:
            return {"ok": False, "error": str(e), "keys": {}}

    def save_keys(self, keys: dict | None = None) -> dict:
        try:
            return engine.save_keys(keys or {})
        except Exception as e:
            return {"ok": False, "error": str(e)}

    def forget_keys(self) -> dict:
        try:
            return engine.forget_keys()
        except Exception as e:
            return {"ok": False, "error": str(e)}

    def app_info(self) -> dict:
        try:
            return engine.app_info()
        except Exception as e:
            return {"error": str(e)}

    def save_text(self, filename: str, text: str) -> dict:
        """네이티브 저장 대화상자. 브라우저의 다운로드 대신 씁니다."""
        try:
            if webview is None:
                return {"ok": False, "error": "창이 없습니다 (pywebview 미설치)"}
            win = self.window or (webview.windows[0] if webview.windows else None)
            if win is None:
                return {"ok": False, "error": "창을 찾지 못했습니다"}
            picked = win.create_file_dialog(
                webview.SAVE_DIALOG, save_filename=filename or "briefing.txt")
            if not picked:
                return {"ok": False, "cancelled": True}
            path = picked if isinstance(picked, str) else picked[0]
            with open(path, "w", encoding="utf-8") as f:
                f.write(text or "")
            engine.log(f"파일 저장 — {path}")
            return {"ok": True, "path": path}
        except Exception as e:
            engine.log(f"save_text 예외: {e!r}")
            return {"ok": False, "error": str(e)}

    def open_log(self) -> dict:
        try:
            path = engine.LOG_PATH()
            if not os.path.exists(path):
                open(path, "a", encoding="utf-8").close()
            webbrowser.open("file://" + path)
            return {"ok": True, "path": path}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    def open_external(self, url: str) -> dict:
        """바깥 링크는 앱 창이 아니라 기본 브라우저에서 엽니다."""
        try:
            if not str(url).lower().startswith(("http://", "https://")):
                return {"ok": False, "error": "http(s) 주소만 엽니다"}
            webbrowser.open(url)
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "error": str(e)}


def main() -> None:
    if webview is None:
        print("pywebview 가 없습니다. 먼저 설치하세요:\n\n    pip install pywebview\n")
        raise SystemExit(1)

    engine.log("=" * 52)
    engine.log(f"축구 분석기 데스크톱 시작 — {engine.app_info()}")

    api = Api()
    window = webview.create_window(
        "ULTIMATE SPORTS AI ANALYZER v4",
        url=ui_path(),
        js_api=api,
        width=1480, height=1000,
        min_size=(1100, 720),
        background_color="#060d18",
        text_select=True,
    )
    api.window = window
    # gui 를 지정하지 않으면 pywebview 가 알아서 고릅니다
    # (윈도우: Edge WebView2, 맥: WebKit, 리눅스: GTK/Qt).
    webview.start(debug=bool(os.environ.get("USAI_DEBUG")))
    engine.log("종료")


if __name__ == "__main__":
    main()
