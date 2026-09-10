"""축구 분석기 데스크톱 앱의 엔진.

화면(HTML)은 그리기만 하고, 바깥세상과 이야기하는 일은 전부 여기서 합니다.
표준 라이브러리만 씁니다 — pip 로 따로 받을 것이 없고, PyInstaller 로 묶어도
용량이 크게 늘지 않습니다.

여기서 하는 일
  * 네 곳의 축구 API 호출 (재시도 · 타임아웃 · 호스트별 속도 제한)
  * 각 키를 그 키가 속한 곳에만 보내기
  * 키를 내 PC 안에 저장 (파일 권한 0600)
  * 소스별 연결 진단
  * 무슨 일이 있었는지 로그 남기기

브라우저가 아니므로 CORS 라는 것이 아예 없습니다. 프록시도 필요 없습니다.
"""

from __future__ import annotations

import json
import os
import ssl
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

APP_NAME = "SportsAIAnalyzer"
VERSION = "4.0-desktop"
USER_AGENT = f"{APP_NAME}/{VERSION} (+local desktop app)"

# 이 앱이 말을 걸어도 되는 곳. 여기 없는 주소는 아예 부르지 않습니다.
# 화면 쪽 코드가 어떤 이유로든 엉뚱한 주소를 넘겨도 키가 새 나가지 않습니다.
ALLOWED_HOSTS = {
    "v3.football.api-sports.io",
    "api.football-data.org",
    "api.openligadb.de",
    "www.thesportsdb.com",
    "thesportsdb.com",
}

# 헤더 이름 -> 그 헤더를 받아도 되는 호스트.
# football-data.org 토큰이 TheSportsDB 로 가는 일 따위가 생기지 않게 합니다.
HEADER_HOME = {
    "x-auth-token": {"api.football-data.org"},
    "x-apisports-key": {"v3.football.api-sports.io"},
    "x-rapidapi-key": {"v3.football.api-sports.io"},
}

# 무료 등급 기준으로 잡은 호스트별 최소 호출 간격(초).
MIN_INTERVAL = {
    "api.football-data.org": 6.5,   # 분당 10회
    "v3.football.api-sports.io": 0.4,
    "api.openligadb.de": 0.2,
    "www.thesportsdb.com": 1.2,
    "thesportsdb.com": 1.2,
}

TIMEOUT = 20
MAX_RETRY = 3
RETRY_STATUS = {408, 425, 429, 500, 502, 503, 504}


# ---------------------------------------------------------------- 저장 위치

def data_dir() -> str:
    if sys.platform.startswith("win"):
        base = os.environ.get("APPDATA") or os.path.expanduser("~")
    elif sys.platform == "darwin":
        base = os.path.expanduser("~/Library/Application Support")
    else:
        base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    d = os.path.join(base, APP_NAME)
    os.makedirs(d, exist_ok=True)
    return d


KEYS_PATH = lambda: os.path.join(data_dir(), "keys.json")
LOG_PATH = lambda: os.path.join(data_dir(), "app.log")


def log(msg: str) -> None:
    line = f"{time.strftime('%Y-%m-%d %H:%M:%S')}  {msg}\n"
    try:
        p = LOG_PATH()
        # 로그가 무한히 자라지 않도록 1MB 를 넘으면 앞부분을 버립니다.
        if os.path.exists(p) and os.path.getsize(p) > 1_000_000:
            with open(p, "r", encoding="utf-8", errors="replace") as f:
                tail = f.read()[-200_000:]
            with open(p, "w", encoding="utf-8") as f:
                f.write(tail)
        with open(p, "a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass
    print(line, end="", flush=True)


# ---------------------------------------------------------------- 속도 제한

_last_call: dict[str, float] = {}
_rate_lock = threading.Lock()


def _throttle(host: str) -> float:
    """같은 호스트를 너무 빨리 연달아 부르지 않도록 기다립니다. 기다린 초를 돌려줍니다."""
    gap = MIN_INTERVAL.get(host, 0.0)
    if gap <= 0:
        return 0.0
    with _rate_lock:
        prev = _last_call.get(host, 0.0)
        wait = prev + gap - time.monotonic()
        if wait <= 0:
            _last_call[host] = time.monotonic()
            return 0.0
        _last_call[host] = prev + gap
    time.sleep(wait)
    return wait


def _ssl_ctx() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    # PyInstaller 로 묶은 exe 에는 인증서 묶음이 없을 수 있어 certifi 가 있으면 씁니다.
    try:
        import certifi  # type: ignore
        ctx.load_verify_locations(certifi.where())
    except Exception:
        pass
    return ctx


# ---------------------------------------------------------------- HTTP

def clean_headers(host: str, headers: dict | None) -> dict:
    """이 호스트가 받아도 되는 헤더만 남깁니다."""
    out = {"Accept": "application/json", "User-Agent": USER_AGENT}
    for k, v in (headers or {}).items():
        if v in (None, ""):
            continue
        home = HEADER_HOME.get(str(k).lower())
        if home is not None and host not in home:
            log(f"헤더 차단: {k} 는 {host} 로 보내지 않습니다")
            continue
        out[str(k)] = str(v)
    return out


def http_get(url: str, headers: dict | None = None, timeout: int = TIMEOUT) -> dict:
    """GET 한 번. 늘 dict 를 돌려주고 예외를 밖으로 내보내지 않습니다."""
    try:
        host = urllib.parse.urlparse(url).hostname or ""
    except ValueError:
        return {"ok": False, "status": 0, "body": "", "error": "주소를 해석하지 못했습니다"}

    if not url.lower().startswith("https://"):
        return {"ok": False, "status": 0, "body": "", "error": "https 만 허용합니다"}
    if host not in ALLOWED_HOSTS:
        log(f"허용되지 않은 호스트 차단: {host}")
        return {"ok": False, "status": 0, "body": "",
                "error": f"허용되지 않은 호스트입니다: {host}"}

    hdrs = clean_headers(host, headers)
    ctx = _ssl_ctx()
    started = time.monotonic()
    last_err = ""

    for attempt in range(1, MAX_RETRY + 1):
        waited = _throttle(host)
        try:
            req = urllib.request.Request(url, headers=hdrs, method="GET")
            with urllib.request.urlopen(req, timeout=timeout, context=ctx) as r:
                body = r.read().decode("utf-8", errors="replace")
                ms = int((time.monotonic() - started) * 1000)
                log(f"  {r.status}  {url}  ({ms}ms{', 대기 %.1fs' % waited if waited else ''})")
                return {"ok": True, "status": r.status, "body": body, "error": "",
                        "elapsed_ms": ms, "attempts": attempt}
        except urllib.error.HTTPError as e:
            body = ""
            try:
                body = e.read().decode("utf-8", errors="replace")
            except Exception:
                pass
            if e.code in RETRY_STATUS and attempt < MAX_RETRY:
                back = 1.5 * attempt
                log(f"  {e.code}  {url} — {back:.1f}초 뒤 재시도 ({attempt}/{MAX_RETRY})")
                time.sleep(back)
                last_err = f"HTTP {e.code}"
                continue
            ms = int((time.monotonic() - started) * 1000)
            log(f"  {e.code}  {url}  ({ms}ms)")
            # 4xx 는 화면에서 설명해야 하므로 본문을 그대로 넘깁니다.
            return {"ok": True, "status": e.code, "body": body, "error": "",
                    "elapsed_ms": ms, "attempts": attempt}
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            last_err = getattr(e, "reason", None) or str(e)
            last_err = str(last_err)
            if attempt < MAX_RETRY:
                back = 1.5 * attempt
                log(f"  실패  {url} — {last_err} — {back:.1f}초 뒤 재시도 ({attempt}/{MAX_RETRY})")
                time.sleep(back)
                continue

    ms = int((time.monotonic() - started) * 1000)
    log(f"  포기  {url}  {last_err}")
    return {"ok": False, "status": 0, "body": "", "error": last_err or "연결 실패",
            "elapsed_ms": ms, "attempts": MAX_RETRY}


# ---------------------------------------------------------------- 키 저장

def load_keys() -> dict:
    try:
        with open(KEYS_PATH(), encoding="utf-8") as f:
            d = json.load(f)
        return {k: str(v) for k, v in d.items() if k in ("apiKey", "fdKey", "tsdbKey")}
    except (OSError, ValueError):
        return {}


def save_keys(keys: dict) -> dict:
    keep = {k: str(v or "") for k, v in (keys or {}).items()
            if k in ("apiKey", "fdKey", "tsdbKey")}
    path = KEYS_PATH()
    try:
        # 남이 못 읽게 만든 뒤에 내용을 씁니다 (순서가 반대면 잠깐 열려 있습니다).
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(keep, f, ensure_ascii=False, indent=1)
        log(f"키 저장 — {sum(1 for v in keep.values() if v)}개 · {path}")
        return {"ok": True, "path": path}
    except OSError as e:
        log(f"키 저장 실패: {e}")
        return {"ok": False, "error": str(e)}


def forget_keys() -> dict:
    try:
        os.remove(KEYS_PATH())
        log("저장된 키 삭제")
    except FileNotFoundError:
        pass
    except OSError as e:
        return {"ok": False, "error": str(e)}
    return {"ok": True}


# ---------------------------------------------------------------- 진단

PROBES = [
    ("primary", "API-Football", "https://v3.football.api-sports.io/status",
     lambda k: {"x-apisports-key": k.get("apiKey", "")}, "apiKey"),
    ("fd", "football-data.org", "https://api.football-data.org/v4/competitions/PL",
     lambda k: {"X-Auth-Token": k.get("fdKey", "")}, "fdKey"),
    ("oldb", "OpenLigaDB", "https://api.openligadb.de/getavailableleagues",
     lambda k: {}, None),
    ("fallback", "TheSportsDB",
     "https://www.thesportsdb.com/api/v1/json/3/all_leagues.php",
     lambda k: {}, None),
]


def probe(keys: dict | None = None) -> list:
    """네 소스를 차례로 두드려 보고 어디가 되고 어디가 막히는지 알려줍니다."""
    keys = keys or {}
    out = []
    for sid, name, url, mk, need in PROBES:
        if need and not keys.get(need):
            out.append({"id": sid, "name": name, "state": "skip",
                        "detail": "키를 입력하지 않아 건너뜁니다"})
            continue
        r = http_get(url, mk(keys), timeout=12)
        if not r["ok"]:
            out.append({"id": sid, "name": name, "state": "fail",
                        "detail": f"연결 실패 — {r['error']}"})
        elif r["status"] == 200:
            out.append({"id": sid, "name": name, "state": "ok",
                        "detail": f"정상 · {r.get('elapsed_ms', 0)}ms"})
        elif r["status"] in (401, 403):
            out.append({"id": sid, "name": name, "state": "fail",
                        "detail": f"키가 거부됐습니다 (HTTP {r['status']})"})
        elif r["status"] == 429:
            out.append({"id": sid, "name": name, "state": "warn",
                        "detail": "호출 한도 초과 — 잠시 뒤 다시"})
        else:
            out.append({"id": sid, "name": name, "state": "warn",
                        "detail": f"HTTP {r['status']}"})
    return out


def app_info() -> dict:
    return {"version": VERSION, "python": sys.version.split()[0],
            "platform": sys.platform, "data_dir": data_dir(),
            "log": LOG_PATH(), "keys": KEYS_PATH(),
            "frozen": bool(getattr(sys, "frozen", False))}
