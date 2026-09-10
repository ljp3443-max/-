# 축구 분석기 — 바탕화면 앱

HTML 화면은 그대로 두고, API 접속을 파이썬이 맡는 구조입니다.

```
   ui/index.html          ← 화면 (기존 HTML + bridge.js)
        │  window.pywebview.api.http_get(...)
        ▼
   app.py   (pywebview 창)
        │
        ▼
   engine.py              ← 실제 API 호출 · 키 보관 · 재시도 · 진단
        │
        ▼
   API-Football · football-data.org · OpenLigaDB · TheSportsDB
```

## 왜 이렇게 만드는가

브라우저로 HTML 을 열면 football-data.org 가 **CORS 로 막힙니다.** 브라우저가
아니라 파이썬이 요청을 보내면 CORS 라는 개념 자체가 없습니다. 그래서 이 구조에서는

* `fd-proxy` 를 띄울 필요가 없습니다
* 8787 포트를 열 필요가 없습니다
* 프록시 주소를 입력할 칸도 없습니다 (앱에서 자동으로 숨깁니다)

## 파일

| 파일 | 하는 일 |
|---|---|
| `engine.py` | 엔진. HTTP 호출, 키 저장, 속도 제한, 재시도, 진단. **표준 라이브러리만** 씁니다 |
| `app.py` | pywebview 창을 띄우고 `engine` 을 화면에 노출하는 껍데기 |
| `bridge.js` | 화면 쪽 다리. `fetch` 를 파이썬으로 돌리고 필요 없어진 UI 를 정리 |
| `make_ui.py` | `../sports-ai-analyzer-v4.html` + `bridge.js` → `ui/index.html` |
| `build.bat` | PyInstaller 로 `축구분석기.exe` 를 만들어 바탕화면에 둡니다 |
| `실행-개발용.bat` | exe 없이 바로 실행 (수정하면서 볼 때) |

원본 HTML 은 **건드리지 않습니다.** 화면을 고치려면 `../sports-ai-analyzer-v4.html`
을 고치고 `python make_ui.py` 를 다시 돌리면 됩니다.

## 만드는 법 (윈도우) — 파일 두 개면 됩니다

`데스크톱앱-만들기.bat` 과 `sports-ai-analyzer-v4.html` 을 한 폴더에 두고
배치 파일을 더블클릭하세요. 나머지 파이썬 파일은 배치 파일 안에 들어 있어
스스로 꺼냅니다. 실행하면 두 가지 중에 고르게 합니다.

    [1] 지금 바로 실행해 보기      - 설치 30초쯤, 창이 바로 뜹니다
    [2] 바탕화면 exe 만들기        - 1~3분, 아이콘이 생깁니다

먼저 [1] 로 잘 도는지 보고, 마음에 들면 [2] 로 exe 를 만드는 편이 좋습니다.

## 저장소에서 직접 쓸 때

1. 파이썬 설치 — <https://www.python.org/downloads/>
   설치 화면에서 **"Add Python to PATH"** 를 반드시 체크
2. 이 폴더에서 `build.bat` 더블클릭
3. 1~3분 뒤 바탕화면에 `축구분석기.exe` 가 생깁니다
4. 더블클릭

만들지 않고 그냥 써 보려면 `실행-개발용.bat` 을 더블클릭하세요.

> 윈도우 10·11 은 Edge WebView2 런타임이 기본으로 들어 있어 따로 받을 것이 없습니다.
> 아주 오래된 윈도우라면 Microsoft 에서 "Edge WebView2 Runtime" 을 한 번 설치하면 됩니다.

## 키는 어디에 저장되나

`%APPDATA%\SportsAIAnalyzer\keys.json` — 내 계정만 읽을 수 있는 권한(0600)으로 저장합니다.
앱 안의 **저장된 키 지우기** 버튼으로 언제든 지울 수 있습니다.

각 키는 그 키가 속한 서비스로만 갑니다. `engine.py` 가 헤더를 보내기 전에 확인해서,
예를 들어 football-data.org 토큰이 TheSportsDB 로 가는 일은 생기지 않습니다.

## 무슨 일이 있었는지 보려면

`%APPDATA%\SportsAIAnalyzer\app.log` — 앱 안의 **기록 파일 열기** 버튼으로도 열립니다.
어느 주소를 불렀고 몇 번째에 성공했는지, 무엇이 몇 초 기다렸는지가 남습니다.
