/* ============================================================
   데스크톱 다리 (HTML 화면  <->  파이썬 엔진)

   이 파일은 화면 코드를 고치지 않습니다. 앱 안에서 열렸을 때에만
   fetch 를 파이썬 쪽으로 돌려놓고, 화면에서 필요 없어진 부분을 정리합니다.
   그냥 브라우저로 열면 아무 일도 하지 않고 예전 그대로 동작합니다.

   파이썬을 거치면 CORS 가 없습니다. 프록시도, 8787 포트도 필요 없습니다.
   ============================================================ */
(function () {
  'use strict';

  // 파이썬이 대신 불러 줄 곳. 나머지 주소는 건드리지 않습니다.
  var API_HOSTS = /(^|\.)(v3\.football\.api-sports\.io|api\.football-data\.org|api\.openligadb\.de|thesportsdb\.com)$/i;

  function ready(fn) {
    if (window.pywebview && window.pywebview.api) { fn(); return; }
    window.addEventListener('pywebviewready', fn, { once: true });
  }

  function isApiUrl(u) {
    try { return API_HOSTS.test(new URL(u, location.href).hostname); }
    catch (e) { return false; }
  }

  /* ---------- 1. fetch 를 파이썬으로 ---------- */
  function installFetch() {
    var native = window.fetch.bind(window);

    window.fetch = function (input, init) {
      var url = (typeof input === 'string') ? input : (input && input.url) || '';
      if (!isApiUrl(url)) return native(input, init);

      init = init || {};
      var headers = {};
      var h = init.headers;
      if (h) {
        if (typeof h.forEach === 'function' && !Array.isArray(h)) h.forEach(function (v, k) { headers[k] = v; });
        else if (Array.isArray(h)) h.forEach(function (p) { headers[p[0]] = p[1]; });
        else Object.keys(h).forEach(function (k) { headers[k] = h[k]; });
      }

      return window.pywebview.api.http_get(url, headers).then(function (r) {
        if (!r || !r.ok) {
          // 화면 코드는 "네트워크 실패"를 TypeError 로 알아봅니다. 모양을 맞춰 줍니다.
          throw new TypeError((r && r.error) || '파이썬 엔진이 응답하지 않았습니다');
        }
        return new Response(r.body, {
          status: r.status || 200,
          headers: { 'Content-Type': 'application/json; charset=utf-8' }
        });
      });
    };
  }

  /* ---------- 2. 화면에서 필요 없어진 것 치우기 ---------- */
  function tidyUi() {
    var $ = function (id) { return document.getElementById(id); };

    // 프록시 칸 — 데스크톱에서는 의미가 없습니다.
    var proxy = $('fdProxy');
    if (proxy) {
      proxy.value = '';
      var lab = document.querySelector('label[for="fdProxy"]');
      if (lab) lab.hidden = true;
      proxy.hidden = true;
    }

    // football-data.org 칸 아래의 CORS·프록시 설명 문단을 걷어냅니다.
    var row = $('fdKey') && $('fdKey').closest('.src-row');
    if (row) {
      row.querySelectorAll('.small').forEach(function (el) {
        if (/CORS|프록시|8787/.test(el.textContent)) el.hidden = true;
      });
      var note = document.createElement('div');
      note.className = 'small';
      note.style.marginTop = '6px';
      note.innerHTML = '이 앱은 <b>파이썬이 대신 호출</b>하므로 CORS 가 없습니다. '
        + '프록시를 띄울 필요도, 주소를 입력할 필요도 없습니다. '
        + '토큰은 football-data.org 로만 전송됩니다.';
      row.appendChild(note);
    }

    // 진단 버튼 — 프록시가 아니라 네 소스를 전부 두드려 봅니다.
    document.querySelectorAll('button').forEach(function (b) {
      if (/프록시 진단/.test(b.textContent)) {
        b.textContent = '🔎 소스 연결 진단';
        b.setAttribute('onclick', 'desktopProbe()');
      }
    });

    // 키 저장 안내를 사실에 맞게 고칩니다.
    var v4 = document.querySelector('.v4-note');
    if (v4) {
      v4.innerHTML = '입력한 키는 <b>내 PC 안에만</b> 저장됩니다 — '
        + '<code id="keysPath">…</code> (나만 읽을 수 있는 권한). '
        + '각 키는 그 키가 속한 서비스로만 전송되며, 파이썬 엔진이 다른 곳으로는 보내지 않습니다.<br>'
        + '<button class="btn btn-secondary" style="margin-top:8px" onclick="desktopForgetKeys()">저장된 키 지우기</button> '
        + '<button class="btn btn-secondary" style="margin-top:8px" onclick="window.pywebview.api.open_log()">기록 파일 열기</button>';
    }

    // 앱 안이라는 표시.
    var badge = document.querySelector('.version-badge');
    if (badge) badge.textContent = 'v4.0 · 데스크톱 · 🐍 Python 엔진';

    var st = $('fdStatus');
    if (st) st.textContent = '프록시 없이 파이썬이 직접 호출합니다';
    var dot = $('fdDot');
    if (dot) dot.className = 'dot';
  }

  /* ---------- 3. 키를 내 PC 에 기억시키기 ---------- */
  var KEY_IDS = ['apiKey', 'fdKey', 'tsdbKey'];

  function collectKeys() {
    var out = {};
    KEY_IDS.forEach(function (id) {
      var el = document.getElementById(id);
      out[id] = el ? el.value.trim() : '';
    });
    return out;
  }

  function installKeyStore() {
    window.pywebview.api.load_keys().then(function (r) {
      if (!r || !r.ok) return;
      var saved = r.keys || {}, filled = 0;
      KEY_IDS.forEach(function (id) {
        var el = document.getElementById(id);
        if (el && saved[id] && !el.value) { el.value = saved[id]; filled++; }
      });
      if (filled) {
        var s = document.getElementById('apiStatus');
        if (s && saved.apiKey) s.textContent = '저장된 키를 불러왔습니다 · 연결 확인을 눌러보세요';
      }
    });

    var timer = null;
    KEY_IDS.forEach(function (id) {
      var el = document.getElementById(id);
      if (!el) return;
      el.addEventListener('input', function () {
        clearTimeout(timer);
        timer = setTimeout(function () { window.pywebview.api.save_keys(collectKeys()); }, 800);
      });
    });

    window.pywebview.api.app_info().then(function (info) {
      var el = document.getElementById('keysPath');
      if (el && info && info.keys) el.textContent = info.keys;
    });
  }

  /* ---------- 4. 화면에서 부르는 진단·정리 함수 ---------- */
  window.desktopProbe = function () {
    var box = document.getElementById('fdDiag');
    if (!box) return;
    box.hidden = false;
    box.textContent = '네 소스를 차례로 확인하는 중…';
    window.pywebview.api.probe(collectKeys()).then(function (r) {
      if (!r || !r.ok) { box.textContent = '진단 실패: ' + ((r && r.error) || '알 수 없음'); return; }
      var mark = { ok: '✅', warn: '⚠️', fail: '❌', skip: '·' };
      box.textContent = r.results.map(function (x) {
        return (mark[x.state] || '·') + ' ' + x.name + ' — ' + x.detail;
      }).join('\n');
    });
  };

  window.desktopForgetKeys = function () {
    window.pywebview.api.forget_keys().then(function () {
      KEY_IDS.forEach(function (id) {
        var el = document.getElementById(id);
        if (el) el.value = '';
      });
      var s = document.getElementById('apiStatus');
      if (s) s.textContent = '저장된 키를 지웠습니다';
    });
  };

  /* ---------- 실행 ---------- */
  ready(function () {
    try {
      installFetch();
      tidyUi();
      installKeyStore();
      document.documentElement.setAttribute('data-desktop', '1');
      console.log('데스크톱 다리 연결됨 — API 호출은 파이썬이 대신합니다');
    } catch (e) {
      console.error('데스크톱 다리 설치 실패:', e);
    }
  });
})();
