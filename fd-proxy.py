# football-data.org 로컬 CORS 프록시 (파이썬 표준 라이브러리만 사용)
# -----------------------------------------------------------
# football-data.org는 서버용 API라 브라우저에서 직접 부르면 CORS로 막힙니다.
# 이 스크립트를 내 PC에서 띄우면 브라우저는 localhost를 부르고,
# 실제 요청은 이 프로그램이 대신 보냅니다. 토큰은 내 PC 밖으로 나가지 않습니다.
#
# 실행:  python fd-proxy.py        (윈도우에서는 py fd-proxy.py)
# 확인:  브라우저 주소창에 http://127.0.0.1:8787/__ping
# 분석기 "프록시 주소" 칸에:  http://127.0.0.1:8787
# 포트 바꾸기:  PORT=9000 python fd-proxy.py
# 끄기:  이 창에서 Ctrl+C
# -----------------------------------------------------------
import http.server, urllib.request, urllib.error, json, os, socket, sys, threading, time

PORT = int(os.environ.get('PORT', 8787))
UPSTREAM = 'https://api.football-data.org'
UPSTREAM_HOST = 'api.football-data.org'

class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Headers', 'X-Auth-Token, Content-Type')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Max-Age', '86400')

    def _send(self, code, body):
        self.send_response(code)
        self._cors()
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    # 브라우저는 X-Auth-Token 같은 커스텀 헤더 때문에 먼저 OPTIONS를 보냅니다.
    def do_OPTIONS(self):
        self.send_response(204); self._cors()
        self.send_header('Content-Length', '0'); self.end_headers()

    def do_GET(self):
        # 프록시가 살아 있는지 확인하는 용도. 토큰이 필요 없습니다.
        if self.path == '/__ping':
            return self._send(200, json.dumps(
                {'ok': True, 'proxy': 'fd-proxy', 'upstream': UPSTREAM_HOST, 'port': PORT}).encode())

        started = time.time()
        req = urllib.request.Request(
            UPSTREAM + self.path,
            headers={'X-Auth-Token': self.headers.get('X-Auth-Token', ''),
                     'Accept': 'application/json'})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                body, code = r.read(), r.status
        except urllib.error.HTTPError as e:
            body, code = e.read(), e.code
        except Exception as e:
            body, code = json.dumps({'message': 'upstream 연결 실패: %s' % e}).encode(), 502
        print('  %s  %s  (%dms)' % (code, self.path, (time.time() - started) * 1000))
        self._send(code, body)

    def log_message(self, *args):
        pass

class V6Server(http.server.ThreadingHTTPServer):
    address_family = socket.AF_INET6

servers = []
try:
    servers.append(http.server.ThreadingHTTPServer(('127.0.0.1', PORT), Handler))
except OSError as e:
    print('\n[오류] 포트 %d 바인딩 실패: %s' % (PORT, e))
    print('       이미 다른 프로그램이 쓰고 있다면 다른 포트로: PORT=9000 python fd-proxy.py')
    sys.exit(1)

# localhost 가 ::1(IPv6)로 먼저 해석되는 PC가 있습니다. IPv4에만 바인딩하면
# 그런 환경에서 연결이 실패하므로 두 주소 모두에서 받습니다.
if socket.has_ipv6:
    try:
        servers.append(V6Server(('::1', PORT), Handler))
    except OSError:
        pass   # IPv6를 못 쓰는 PC는 IPv4로 충분합니다

print('football-data.org 프록시 실행 중')
print('  http://127.0.0.1:%d  ->  %s' % (PORT, UPSTREAM))
print('  살아있는지 확인:  http://127.0.0.1:%d/__ping' % PORT)
print('  분석기의 "프록시 주소" 칸에 위 주소를 넣으세요. 끄려면 Ctrl+C.\n')

for s in servers[1:]:
    threading.Thread(target=s.serve_forever, daemon=True).start()
try:
    servers[0].serve_forever()
except KeyboardInterrupt:
    print('\n프록시를 종료했습니다.')
