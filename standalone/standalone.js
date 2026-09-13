/* ============================================================
   혼자 도는 판(standalone)을 위한 마무리.

   이 파일 하나를 브라우저로 열면 끝입니다. 서버도, 프록시도, 배치 파일도
   없습니다. 그래서 브라우저가 직접 부를 수 없는 소스(football-data.org)는
   화면에서 아예 치웁니다 — 있어도 못 쓰는데 자리를 차지하고, 실패 메시지로
   사람을 헷갈리게 할 뿐입니다.

   대신 키를 이 브라우저에 기억시킬 수 있게 합니다. 매번 넣는 게 제일 번거롭습니다.
   ============================================================ */
(function () {
  'use strict';

  var KEY_STORE = 'usai_keys_v1';
  var IDS = ['apiKey', 'tsdbKey'];
  var $ = function (id) { return document.getElementById(id); };

  /* ---------- 1. 브라우저에서 못 쓰는 소스 치우기 ---------- */
  function dropFootballData() {
    var fd = $('fdKey');
    var row = fd && fd.closest('.src-row');
    if (row) row.remove();

    // 남은 소스 번호를 1,2,3 으로 다시 매깁니다.
    var n = 0;
    document.querySelectorAll('.src-row .src-rank').forEach(function (el) {
      el.textContent = String(++n);
    });

    // 대체 소스 띠에서도 뺍니다.
    var bar = document.querySelector('.probar');
    if (bar && /FOOTBALL-DATA/.test(bar.textContent)) {
      bar.innerHTML = '<span class="protag">1 · API-FOOTBALL</span>'
        + '<span class="protag">2 · OPENLIGADB</span>'
        + '<span class="protag">3 · TheSportsDB</span>';
    }
  }

  /* ---------- 2. 키 기억하기 ---------- */
  function readStore() {
    try { return JSON.parse(localStorage.getItem(KEY_STORE) || '{}'); }
    catch (e) { return {}; }
  }
  function writeStore(o) {
    try { localStorage.setItem(KEY_STORE, JSON.stringify(o)); return true; }
    catch (e) { return false; }
  }

  function installKeyMemory() {
    var saved = readStore();
    var on = !!saved.__remember;

    IDS.forEach(function (id) {
      var el = $(id);
      if (el && on && saved[id] && !el.value) el.value = saved[id];
    });

    var box = document.createElement('label');
    box.className = 'small';
    box.style.cssText = 'display:flex;align-items:center;gap:8px;margin-top:10px;cursor:pointer';
    box.innerHTML = '<input type="checkbox" id="rememberKeys" style="width:auto;margin:0">'
      + '<span>이 브라우저에 키를 기억시키기 <b id="rememberState"></b></span>';

    var anchor = $('apiKey') && $('apiKey').closest('.src-row');
    if (!anchor) return;
    anchor.appendChild(box);

    var cb = $('rememberKeys');
    var state = $('rememberState');
    cb.checked = on;

    function save() {
      if (!cb.checked) {
        writeStore({});
        state.textContent = '· 꺼짐';
        return;
      }
      var o = { __remember: true };
      IDS.forEach(function (id) { o[id] = ($(id) || {}).value || ''; });
      state.textContent = writeStore(o) ? '· 기억함' : '· 저장 실패';
    }

    cb.addEventListener('change', save);
    var timer = null;
    IDS.forEach(function (id) {
      var el = $(id);
      if (!el) return;
      el.addEventListener('input', function () {
        if (!cb.checked) return;
        clearTimeout(timer);
        timer = setTimeout(save, 600);
      });
    });
    state.textContent = on ? '· 기억함' : '';
  }

  /* ---------- 3. 안내 문구를 사실에 맞게 ---------- */
  function fixNotes() {
    var note = document.querySelector('.v4-note');
    if (note && /저장되지 않습니다/.test(note.textContent)) {
      note.innerHTML = '키는 <b>이 브라우저 안에만</b> 남습니다. 위 칸을 체크하지 않으면 '
        + '새로고침할 때 사라지고, 체크하면 이 브라우저에 저장됩니다(다른 사람에게 전송되지 않습니다).<br>'
        + '각 키는 해당 서비스로만 전송되며, 모델은 API가 실제로 돌려준 값만 사용합니다.';
    }

    var badge = document.querySelector('.version-badge');
    if (badge) badge.textContent = 'v4.0 · 단일 파일';

    var intro = document.querySelector('.card .small');
    if (intro && /위에서부터 차례로/.test(intro.textContent)) {
      intro.innerHTML = '소스를 <b>위에서부터 차례로</b> 시도하고, 하나가 성공하면 나머지는 호출하지 않습니다. '
        + '<b>API-Football 키 하나면 30개 리그가 전부 덮입니다.</b> '
        + '키가 없어도 OpenLigaDB(독일)와 TheSportsDB 공개 키로 동작하지만 커버리지가 좁습니다.';
    }
  }

  function boot() {
    try {
      dropFootballData();
      installKeyMemory();
      fixNotes();
    } catch (e) {
      console.error('마무리 중 오류:', e);
    }
  }

  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
