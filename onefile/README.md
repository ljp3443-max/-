# 축구 분석기 — 설치가 필요 없는 단일 실행 파일

`축구분석기.bat` 하나만 더블클릭하면 됩니다. **아무것도 설치하지 않습니다.**

```
   축구분석기.bat  (파일 하나)
        │
        ├─ server.ps1  을 꺼내서 실행   ← 윈도우 기본 PowerShell
        │
        ▼
   http://127.0.0.1:8791/          ← 내 PC 안에서만 도는 서버
        │  화면(HTML)을 여기서 내려줍니다
        │  API 요청도 /proxy 로 받아 대신 보냅니다
        ▼
   API-Football · football-data.org · OpenLigaDB · TheSportsDB
```

## 왜 이 방식인가

화면이 `file://` 이 아니라 `http://127.0.0.1:...` 에서 열리므로, API 호출을 **같은
주소**의 `/proxy` 로 넘길 수 있습니다. 같은 주소끼리는 CORS 검사가 없습니다.
그래서

* 프록시를 따로 띄울 필요가 없고
* 프록시 주소를 입력할 칸도 없고 (앱에서 숨깁니다)
* Node 도 파이썬도 필요 없습니다 — PowerShell 은 윈도우에 이미 들어 있습니다

## 파일

| 파일 | 하는 일 |
|---|---|
| `server.ps1` | 내 PC 안의 작은 HTTP 서버. 화면을 내려주고 API 를 대신 호출 |
| `local-bridge.js` | 화면 쪽 다리. `fetch` 를 같은 주소의 `/proxy` 로 돌림 |
| `make_local_ui.py` | `../sports-ai-analyzer-v4.html` + 다리 → `index.html` |
| `gen_bat.py` | `server.ps1` + `index.html` 을 `축구분석기.bat` 하나로 묶음 |

## 다시 만들기

```
python3 make_local_ui.py      # index.html 생성
python3 gen_bat.py            # 축구분석기.bat 생성
```

원본 HTML 은 건드리지 않습니다. 화면을 고치려면 `../sports-ai-analyzer-v4.html`
을 고치고 위 두 줄을 다시 돌리면 됩니다.

## 서버가 지키는 것

* **호스트 허용 목록** — 네 곳 외에는 아예 부르지 않습니다
* **헤더 격리** — football-data.org 토큰은 football-data.org 로만 갑니다
* **호출 간격** — 무료 등급 한도에 맞춰 호스트별로 띄웁니다 (fd 는 6.5초)
* **재시도** — 429·5xx 는 백오프로 3회까지
* 모든 호출이 검은 창에 한 줄씩 남습니다

## 끄는 법

검은 창을 닫으면 됩니다.
