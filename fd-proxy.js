// football-data.org 로컬 CORS 프록시
// -----------------------------------------------------------
// football-data.org는 서버용 API라 브라우저에서 직접 부르면 CORS로 막힙니다.
// 이 스크립트를 내 PC에서 띄우면 브라우저는 localhost를 부르고,
// 실제 요청은 이 프로그램이 대신 보냅니다. 토큰은 내 PC 밖으로 나가지 않습니다.
//
// 실행:  node fd-proxy.js
// 확인:  브라우저 주소창에 http://127.0.0.1:8787/__ping
// 분석기 "프록시 주소" 칸에:  http://127.0.0.1:8787
// 포트 바꾸기:  PORT=9000 node fd-proxy.js   (윈도우: set PORT=9000 && node fd-proxy.js)
// 끄기:  이 창에서 Ctrl+C
// -----------------------------------------------------------
const http = require('http');
const https = require('https');

const PORT = Number(process.env.PORT || 8787);
const UPSTREAM = 'api.football-data.org';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'X-Auth-Token, Content-Type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Max-Age': '86400'
};

function handler(req, res) {
  // 브라우저는 X-Auth-Token 같은 커스텀 헤더 때문에 먼저 OPTIONS를 보냅니다.
  if (req.method === 'OPTIONS') { res.writeHead(204, CORS); return res.end(); }

  // 프록시가 살아 있는지 확인하는 용도. 토큰이 필요 없습니다.
  if (req.url === '/__ping') {
    res.writeHead(200, { ...CORS, 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ ok: true, proxy: 'fd-proxy', upstream: UPSTREAM, port: PORT }));
  }

  if (req.method !== 'GET') {
    res.writeHead(405, { ...CORS, 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ message: 'GET만 지원합니다.' }));
  }

  const token = req.headers['x-auth-token'] || '';
  const started = Date.now();
  const upstream = https.request({
    hostname: UPSTREAM, path: req.url, method: 'GET',
    headers: { 'X-Auth-Token': token, 'Accept': 'application/json' }
  }, r => {
    console.log(`  ${r.statusCode}  ${req.url}  (${Date.now() - started}ms)`);
    res.writeHead(r.statusCode || 502, { ...CORS, 'Content-Type': 'application/json; charset=utf-8' });
    r.pipe(res);
  });

  upstream.on('error', e => {
    console.log(`  실패  ${req.url}  ${e.message}`);
    res.writeHead(502, { ...CORS, 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'upstream 연결 실패: ' + e.message }));
  });
  upstream.end();
}

// localhost 가 ::1(IPv6)로 먼저 해석되는 PC가 있습니다. IPv4에만 바인딩하면
// 그런 환경에서 연결이 실패하므로 두 주소 모두에서 받습니다.
let up = 0, done = 0;
const hosts = ['127.0.0.1', '::1'];
hosts.forEach(host => {
  const s = http.createServer(handler);
  s.on('error', e => {
    done++;
    if (e.code === 'EADDRINUSE') {
      console.error(`\n[오류] 포트 ${PORT}을 이미 다른 프로그램이 쓰고 있습니다.`);
      console.error(`       다른 포트로: PORT=9000 node fd-proxy.js`);
      console.error(`       (윈도우) set PORT=9000 && node fd-proxy.js`);
      process.exit(1);
    }
    // IPv6를 못 쓰는 PC는 조용히 넘어갑니다 (IPv4로 충분합니다).
    if (!['EAFNOSUPPORT', 'EADDRNOTAVAIL', 'EINVAL'].includes(e.code))
      console.error(`  ${host} 바인딩 실패: ${e.code}`);
    finish();
  });
  s.listen(PORT, host, () => { up++; done++; finish(); });
});

function finish() {
  if (done < hosts.length) return;
  if (!up) { console.error('\n[오류] 어떤 주소에도 바인딩하지 못했습니다.'); process.exit(1); }
  console.log('football-data.org 프록시 실행 중');
  console.log(`  http://127.0.0.1:${PORT}  ->  https://${UPSTREAM}`);
  console.log(`  살아있는지 확인:  http://127.0.0.1:${PORT}/__ping`);
  console.log('  분석기의 "프록시 주소" 칸에 위 주소를 넣으세요. 끄려면 Ctrl+C.\n');
}
