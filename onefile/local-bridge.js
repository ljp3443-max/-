/* ============================================================
   같은 주소에서 대신 불러 주는 다리.

   이 화면은 file:// 이 아니라 http://127.0.0.1:<포트>/ 에서 열립니다.
   그래서 API 호출을 같은 주소의 /proxy 로 넘기면 CORS 가 아예 생기지 않습니다.
   실제 요청은 내 PC 에서 도는 작은 서버(윈도우 기본 PowerShell)가 보냅니다.

   프록시 주소를 입력할 일도, 포트를 맞출 일도 없습니다.
   ============================================================ */
(function () {
  'use strict';

  var API_HOSTS = /(^|\.)(v3\.football\.api-sports\.io|api\.football-data\.org|api\.openligadb\.de|thesportsdb\.com)$/i;

  function isApiUrl(u) {
    try { return API_HOSTS.test(new URL(u, location.href).hostname); }
    catch (e) { return false; }
  }

  var native = window.fetch.bind(window);
  window.fetch = function (input, init) {
    var url = (typeof input === 'string') ? input : (input && input.url) || '';
    if (!isApiUrl(url)) return native(input, init);
    init = init || {};
    // 같은 주소로 보내므로 사전요청(preflight)도, 차단도 없습니다.
    return native('/proxy?url=' + encodeURIComponent(url), {
      method: 'GET',
      headers: init.headers || {},
      cache: 'no-store',
      signal: init.signal
    });
  };

  function tidy() {
    var $ = function (id) { return document.getElementById(id); };

    var proxy = $('fdProxy');
    if (proxy) {
      proxy.value = '';
      proxy.hidden = true;
      var lab = document.querySelector('label[for="fdProxy"]');
      if (lab) lab.hidden = true;
    }

    var row = $('fdKey') && $('fdKey').closest('.src-row');
    if (row) {
      row.querySelectorAll('.small').forEach(function (el) {
        if (/CORS|프록시|8787/.test(el.textContent)) el.hidden = true;
      });
      var note = document.createElement('div');
      note.className = 'small';
      note.style.marginTop = '6px';
      note.innerHTML = '이 창은 <b>내 PC 안의 작은 서버</b>를 통해 열려 있습니다. '
        + 'API 요청도 그 서버가 대신 보내므로 CORS 가 없고, 프록시 주소를 넣을 필요도 없습니다.';
      row.appendChild(note);
    }

    document.querySelectorAll('button').forEach(function (b) {
      if (/프록시 진단/.test(b.textContent)) {
        b.textContent = '🔎 소스 연결 진단';
        b.setAttribute('onclick', 'localProbe()');
      }
    });

    var badge = document.querySelector('.version-badge');
    if (badge) badge.textContent = 'v4.0 · 내 PC 서버 연결됨';
    var st = $('fdStatus');
    if (st) st.textContent = '프록시 없이 바로 호출합니다';
  }

  window.localProbe = function () {
    var box = document.getElementById('fdDiag');
    if (!box) return;
    box.hidden = false;
    box.textContent = '네 소스를 차례로 확인하는 중…';
    var keys = {
      apiKey: (document.getElementById('apiKey') || {}).value || '',
      fdKey: (document.getElementById('fdKey') || {}).value || '',
      tsdbKey: (document.getElementById('tsdbKey') || {}).value || ''
    };
    var jobs = [
      ['API-Football', 'https://v3.football.api-sports.io/status',
        keys.apiKey ? { 'x-apisports-key': keys.apiKey } : null],
      ['football-data.org', 'https://api.football-data.org/v4/competitions/PL',
        keys.fdKey ? { 'X-Auth-Token': keys.fdKey } : null],
      ['OpenLigaDB', 'https://api.openligadb.de/getavailableleagues', {}],
      ['TheSportsDB', 'https://www.thesportsdb.com/api/v1/json/3/all_leagues.php', {}]
    ];
    Promise.all(jobs.map(function (j) {
      if (j[2] === null) return Promise.resolve('·  ' + j[0] + ' — 키를 입력하지 않아 건너뜁니다');
      var t0 = Date.now();
      return fetch(j[1], { headers: j[2] }).then(function (r) {
        var ms = Date.now() - t0;
        if (r.status === 200) return '✅ ' + j[0] + ' — 정상 · ' + ms + 'ms';
        if (r.status === 401 || r.status === 403) return '❌ ' + j[0] + ' — 키가 거부됐습니다 (HTTP ' + r.status + ')';
        if (r.status === 429) return '⚠️ ' + j[0] + ' — 호출 한도 초과, 잠시 뒤 다시';
        return '⚠️ ' + j[0] + ' — HTTP ' + r.status;
      }).catch(function (e) { return '❌ ' + j[0] + ' — 연결 실패 (' + e.message + ')'; });
    })).then(function (lines) { box.textContent = lines.join('\n'); });
  };

  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', tidy);
  else tidy();
})();
