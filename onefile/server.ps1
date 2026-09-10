param(
  [string]$Source = '',
  [int]$Port = 0,
  [switch]$NoBrowser,
  [switch]$TestAllowLocal,
  [string]$TestUpstream = '',
  [string]$ForceServer = ''
)

# 축구 분석기 - 내 PC 안에서만 도는 작은 서버.
#
# 브라우저가 직접 부르면 막히는 API(CORS)를 이 서버가 대신 부릅니다.
# 화면도 이 서버가 내려주므로 화면과 데이터의 출처가 같아지고, 그래서
# 브라우저가 막을 이유 자체가 없어집니다.
#
# 윈도우에 기본으로 들어 있는 PowerShell 로만 돌아갑니다.

$ErrorActionPreference = 'Stop'

# 무슨 일이 생기든 창이 그냥 사라지지 않게 합니다.
trap {
  Write-Host ''
  Write-Host '============================================'
  Write-Host ' [오류] 프로그램을 시작하지 못했습니다.'
  Write-Host ''
  Write-Host ("  " + $_.Exception.Message)
  Write-Host ''
  Write-Host '  아래 내용을 그대로 알려주시면 바로 잡겠습니다.'
  Write-Host ("  " + $_.ScriptStackTrace)
  Write-Host '============================================'
  Write-Host ''
  try { Read-Host '엔터를 누르면 닫힙니다' } catch { }
  exit 1
}

try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
try { Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue } catch { }

$ALLOWED = @(
  'v3.football.api-sports.io',
  'api.football-data.org',
  'api.openligadb.de',
  'www.thesportsdb.com',
  'thesportsdb.com'
)

# 헤더 이름 -> 그 헤더를 받아도 되는 호스트.
$HEADER_HOME = @{
  'x-auth-token'    = @('api.football-data.org')
  'x-apisports-key' = @('v3.football.api-sports.io')
}

# 무료 등급 기준 호스트별 최소 호출 간격(초).
$MIN_GAP = @{
  'api.football-data.org'     = 6.5
  'v3.football.api-sports.io' = 0.4
  'api.openligadb.de'         = 0.2
  'www.thesportsdb.com'       = 1.2
  'thesportsdb.com'           = 1.2
}
$script:lastCall = @{}
$script:logFile = ''

function Write-Line([string]$m) {
  $line = "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m
  Write-Host $line
  if ($script:logFile) {
    try { Add-Content -LiteralPath $script:logFile -Value $line -Encoding UTF8 } catch { }
  }
}

# ---------------------------------------------------------------- 화면 꺼내기

function Get-EmbeddedHtml([string]$path) {
  $lines = [IO.File]::ReadAllLines($path)
  $start = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i].Trim() -eq '::HTMLB64::') { $start = $i; break }
  }
  if ($start -lt 0) { throw "화면 데이터를 찾지 못했습니다: $path" }
  $sb = New-Object Text.StringBuilder
  for ($k = $start + 1; $k -lt $lines.Length; $k++) {
    $l = $lines[$k].Trim()
    if ($l.Length -gt 0) { [void]$sb.Append($l) }
  }
  return [Convert]::FromBase64String($sb.ToString())
}

# ---------------------------------------------------------------- 바깥 호출

function Wait-Turn([string]$hostName) {
  $gap = $MIN_GAP[$hostName]
  if (-not $gap) { return }
  $prev = $script:lastCall[$hostName]
  if ($prev) {
    $wait = $prev.AddSeconds($gap) - (Get-Date)
    if ($wait.TotalMilliseconds -gt 0) { Start-Sleep -Milliseconds ([int]$wait.TotalMilliseconds) }
  }
  $script:lastCall[$hostName] = Get-Date
}

function Invoke-Upstream([string]$url, $clientHeaders) {
  try { $uri = [Uri]$url }
  catch { return @{ status = 400; bytes = [Text.Encoding]::UTF8.GetBytes('{"message":"주소를 해석하지 못했습니다"}'); ctype = 'application/json' } }

  $hostName = $uri.Host
  $okScheme = ($uri.Scheme -eq 'https')
  if ($TestAllowLocal -and $uri.Scheme -eq 'http' -and $hostName -eq '127.0.0.1') { $okScheme = $true }
  if (-not $okScheme) {
    return @{ status = 400; bytes = [Text.Encoding]::UTF8.GetBytes('{"message":"https 만 허용합니다"}'); ctype = 'application/json' }
  }

  $allowed = ($ALLOWED -contains $hostName)
  if ($TestAllowLocal -and $hostName -eq '127.0.0.1') { $allowed = $true }
  if (-not $allowed) {
    Write-Line "  차단  허용되지 않은 호스트: $hostName"
    return @{ status = 403; bytes = [Text.Encoding]::UTF8.GetBytes('{"message":"허용되지 않은 호스트입니다"}'); ctype = 'application/json' }
  }

  $started = Get-Date
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    Wait-Turn $hostName
    try {
      $sendUrl = $url
      if ($TestUpstream) { $sendUrl = $TestUpstream.TrimEnd('/') + $uri.PathAndQuery }
      $req = New-Object Net.Http.HttpRequestMessage ([Net.Http.HttpMethod]::Get), $sendUrl
      [void]$req.Headers.TryAddWithoutValidation('Accept', 'application/json')
      [void]$req.Headers.TryAddWithoutValidation('User-Agent', 'SportsAIAnalyzer/4.0 (local)')
      foreach ($k in $clientHeaders.Keys) {
        $allowHosts = $HEADER_HOME[$k.ToLower()]
        if ($null -eq $allowHosts) { continue }
        if ($allowHosts -notcontains $hostName) {
          Write-Line "  헤더 차단  $k 는 $hostName 으로 보내지 않습니다"
          continue
        }
        [void]$req.Headers.TryAddWithoutValidation($k, $clientHeaders[$k])
      }

      $resp = $script:http.SendAsync($req).GetAwaiter().GetResult()
      $bytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
      $code = [int]$resp.StatusCode
      $ms = [int]((Get-Date) - $started).TotalMilliseconds

      if (($code -eq 429 -or $code -ge 500) -and $attempt -lt 3) {
        Write-Line "  $code  $url - 재시도 ($attempt/3)"
        Start-Sleep -Milliseconds ([int](1500 * $attempt))
        continue
      }
      Write-Line "  $code  $url  (${ms}ms, $($bytes.Length) 바이트)"
      return @{ status = $code; bytes = $bytes; ctype = 'application/json; charset=utf-8' }
    }
    catch {
      $msg = $_.Exception.Message
      if ($_.Exception.InnerException) { $msg = $_.Exception.InnerException.Message }
      if ($attempt -lt 3) {
        Write-Line "  실패  $url - $msg - 재시도 ($attempt/3)"
        Start-Sleep -Milliseconds ([int](1500 * $attempt))
        continue
      }
      Write-Line "  포기  $url  $msg"
      $esc = $msg.Replace('\', '\\').Replace('"', '\"')
      return @{ status = 502; bytes = [Text.Encoding]::UTF8.GetBytes("{`"message`":`"연결 실패: $esc`"}"); ctype = 'application/json' }
    }
  }
}

# ---------------------------------------------------------------- 길 안내
# 어떤 서버 방식을 쓰든 여기서 답을 만듭니다.

function Get-Route([string]$method, [string]$path, [string]$query, $headers) {
  if ($method -ne 'GET') {
    return @{ status = 405; ctype = 'application/json'; bytes = [Text.Encoding]::UTF8.GetBytes('{"message":"GET만 지원합니다"}') }
  }
  if ($path -eq '/' -or $path -eq '/index.html') {
    return @{ status = 200; ctype = 'text/html; charset=utf-8'; bytes = $script:htmlBytes }
  }
  if ($path -eq '/__ping') {
    return @{ status = 200; ctype = 'application/json; charset=utf-8'
              bytes = [Text.Encoding]::UTF8.GetBytes("{`"ok`":true,`"port`":$script:port,`"server`":`"$script:mode`"}") }
  }
  if ($path -eq '/__quit') {
    $script:running = $false
    return @{ status = 200; ctype = 'application/json'; bytes = [Text.Encoding]::UTF8.GetBytes('{"ok":true}') }
  }
  if ($path -eq '/favicon.ico') {
    return @{ status = 204; ctype = 'image/x-icon'; bytes = (New-Object byte[] 0) }
  }
  if ($path -eq '/proxy') {
    $url = ''
    foreach ($pair in $query.Split('&')) {
      $eq = $pair.IndexOf('=')
      if ($eq -gt 0 -and $pair.Substring(0, $eq) -eq 'url') { $url = [Uri]::UnescapeDataString($pair.Substring($eq + 1)) }
    }
    if (-not $url) {
      return @{ status = 400; ctype = 'application/json'; bytes = [Text.Encoding]::UTF8.GetBytes('{"message":"url 이 없습니다"}') }
    }
    return Invoke-Upstream $url $headers
  }
  return @{ status = 404; ctype = 'application/json'; bytes = [Text.Encoding]::UTF8.GetBytes('{"message":"없는 주소입니다"}') }
}

# ---------------------------------------------------------------- 방식 1: HttpListener
# 윈도우가 직접 관리하는 HTTP 서버입니다. 브라우저가 미리 열어 두는 빈 연결,
# 연결 재사용, 동시 접속을 전부 알아서 처리해 줍니다.

function Start-Listener([int]$p) {
  # HttpListener 는 Host 헤더로 주소를 맞춥니다. 브라우저가 localhost 로 열 수도
  # 있으므로 둘 다 등록해 보고, 권한 때문에 안 되면 127.0.0.1 만으로 다시 시도합니다.
  foreach ($set in @(@("http://127.0.0.1:$p/", "http://localhost:$p/"), @("http://127.0.0.1:$p/"))) {
    $l = New-Object Net.HttpListener
    foreach ($pre in $set) { $l.Prefixes.Add($pre) }
    try {
      $l.Start()
      return $l
    }
    catch {
      try { $l.Close() } catch { }
      $lastErr = $_
    }
  }
  throw $lastErr
}

function Run-HttpListener($listener) {
  while ($script:running) {
    $ctx = $null
    try {
      $ctx = $listener.GetContext()
      $req = $ctx.Request
      $headers = @{}
      foreach ($k in $req.Headers.AllKeys) { $headers[$k] = $req.Headers[$k] }

      $r = Get-Route $req.HttpMethod $req.Url.AbsolutePath $req.Url.Query.TrimStart('?') $headers
      $res = $ctx.Response
      $res.StatusCode = [int]$r.status
      $res.ContentType = [string]$r.ctype
      $res.Headers['Cache-Control'] = 'no-store'
      $res.ContentLength64 = $r.bytes.Length
      if ($r.bytes.Length -gt 0) { $res.OutputStream.Write($r.bytes, 0, $r.bytes.Length) }
      $res.OutputStream.Close()

      if ($req.Url.AbsolutePath -ne '/proxy') {
        Write-Line ("  {0}  {1}  ({2} 바이트)" -f $r.status, $req.Url.AbsolutePath, $r.bytes.Length)
      }
    }
    catch {
      if ($script:running) { Write-Line "요청 처리 중 오류: $($_.Exception.Message)" }
    }
    finally {
      if ($ctx) { try { $ctx.Response.Close() } catch { } }
    }
  }
}

# ---------------------------------------------------------------- 방식 2: TcpListener
# HttpListener 를 쓸 수 없는 PC 를 위한 대비책. 직접 HTTP 를 말합니다.

function Read-Head($stream, $client) {
  # 브라우저는 쓰지도 않을 연결을 미리 열어 둡니다. 그런 연결에 갇히지 않도록
  # 잠깐만 기다려 보고, 아무것도 오지 않으면 그냥 버립니다.
  $waited = 0
  # 브라우저는 연결하자마자 요청을 보냅니다. 400ms 안에 아무것도 없으면
  # 쓰지 않을 연결이므로 붙잡고 있지 않습니다.
  while ($client.Available -eq 0 -and $waited -lt 400) {
    Start-Sleep -Milliseconds 10
    $waited += 10
    if (-not $client.Connected) { return '' }
  }
  if ($client.Available -eq 0) { return '' }

  $sb = New-Object Text.StringBuilder
  while ($true) {
    $b = $stream.ReadByte()
    if ($b -lt 0) { break }
    [void]$sb.Append([char]$b)
    if ($sb.Length -ge 4 -and $sb.ToString($sb.Length - 4, 4) -eq "`r`n`r`n") { break }
    if ($sb.Length -gt 16384) { break }
  }
  return $sb.ToString()
}

function Run-TcpListener($listener) {
  while ($script:running) {
    $client = $null
    try {
      $client = $listener.AcceptTcpClient()
      $client.ReceiveTimeout = 5000
      $client.SendTimeout = 30000
      $client.NoDelay = $true
      # 닫을 때 아직 안 나간 데이터가 버려지지 않도록 합니다.
      $client.Client.LingerState = New-Object Net.Sockets.LingerOption($true, 10)
      $ns = $client.GetStream()

      $head = Read-Head $ns $client
      if (-not $head) { continue }

      $lines = $head -split "`r`n"
      $parts = $lines[0] -split ' '
      if ($parts.Length -lt 2) { continue }

      $headers = @{}
      for ($i = 1; $i -lt $lines.Length; $i++) {
        $c = $lines[$i].IndexOf(':')
        if ($c -gt 0) { $headers[$lines[$i].Substring(0, $c).Trim()] = $lines[$i].Substring($c + 1).Trim() }
      }

      $target = $parts[1]
      $path = $target
      $query = ''
      $q = $target.IndexOf('?')
      if ($q -ge 0) { $path = $target.Substring(0, $q); $query = $target.Substring($q + 1) }

      $r = Get-Route $parts[0] $path $query $headers
      $head2 = "HTTP/1.1 $([int]$r.status) X`r`n" +
               "Content-Type: $($r.ctype)`r`n" +
               "Content-Length: $($r.bytes.Length)`r`n" +
               "Cache-Control: no-store`r`n" +
               "Connection: close`r`n`r`n"
      $hb = [Text.Encoding]::UTF8.GetBytes($head2)
      $ns.Write($hb, 0, $hb.Length)
      if ($r.bytes.Length -gt 0) { $ns.Write($r.bytes, 0, $r.bytes.Length) }
      $ns.Flush()
      # 보낸 것이 다 나갈 때까지 기다렸다가 닫습니다.
      try { $client.Client.Shutdown([Net.Sockets.SocketShutdown]::Send) } catch { }

      if ($path -ne '/proxy') {
        Write-Line ("  {0}  {1}  ({2} 바이트)" -f $r.status, $path, $r.bytes.Length)
      }
    }
    catch {
      if ($script:running) { Write-Line "요청 처리 중 오류: $($_.Exception.Message)" }
    }
    finally {
      if ($client) { try { $client.Close() } catch { } }
    }
  }
}

# ---------------------------------------------------------------- 시작

if (-not $Source) { $Source = $PSCommandPath }

# %TEMP% 가 비어 있는 환경도 있습니다. 순서대로 찾아봅니다.
$tmpRoot = $env:TEMP
if (-not $tmpRoot) { $tmpRoot = $env:TMP }
if (-not $tmpRoot) { $tmpRoot = [IO.Path]::GetTempPath() }
$workDir = Join-Path $tmpRoot 'sports-ai-analyzer'
try {
  if (-not (Test-Path $workDir)) { [void](New-Item -ItemType Directory -Path $workDir -Force) }
  $script:logFile = Join-Path $workDir 'app.log'
  Set-Content -LiteralPath $script:logFile -Value ("=== {0} ===" -f (Get-Date)) -Encoding UTF8
}
catch { $script:logFile = '' }

$script:htmlBytes = Get-EmbeddedHtml $Source
Write-Line ("화면 준비됨 - {0:N0} 바이트" -f $script:htmlBytes.Length)

$script:http = New-Object Net.Http.HttpClient
$script:http.Timeout = [TimeSpan]::FromSeconds(25)
$script:running = $true

$candidates = if ($Port -gt 0) { @($Port) } else { @(8791, 8792, 8793, 8794, 8795) }
$server = $null
$script:mode = ''
$script:port = 0

foreach ($p in $candidates) {
  if ($ForceServer -ne 'tcp') {
    try {
      $server = Start-Listener $p
      $script:mode = 'httplistener'
      $script:port = $p
      break
    }
    catch {
      Write-Line "HttpListener 를 포트 $p 에 열지 못했습니다 ($($_.Exception.Message)) - 다른 방식으로 시도합니다"
    }
  }
  if ($ForceServer -ne 'httplistener') {
    try {
      $l = New-Object Net.Sockets.TcpListener ([Net.IPAddress]::Loopback), $p
      $l.Start()
      $server = $l
      $script:mode = 'tcp'
      $script:port = $p
      break
    }
    catch { }
  }
}

if ($null -eq $server) {
  Write-Host ''
  Write-Host '[오류] 쓸 수 있는 포트를 찾지 못했습니다 (8791~8795).'
  Write-Host '       다른 프로그램이 쓰고 있거나 방화벽이 막고 있습니다.'
  Write-Host ''
  Read-Host '엔터를 누르면 닫힙니다'
  exit 1
}

$root = "http://127.0.0.1:$($script:port)/"
Write-Host ''
Write-Host '  ============================================'
Write-Host '   축구 분석기가 준비됐습니다.'
Write-Host ''
Write-Host "   주소:  $root"
Write-Host ''
Write-Host '   * 브라우저가 저절로 열립니다.'
Write-Host '     안 열리면 위 주소를 복사해 붙여넣으세요.'
Write-Host '   * 이 검은 창을 닫으면 프로그램이 꺼집니다.'
Write-Host '  ============================================'
Write-Host ''
Write-Line "서버 방식: $($script:mode)"
if ($script:logFile) { Write-Line "기록 파일: $($script:logFile)" }

if (-not $NoBrowser) {
  try { Start-Process $root } catch { Write-Line "브라우저를 여는 데 실패했습니다: $($_.Exception.Message)" }
}

if ($script:mode -eq 'httplistener') { Run-HttpListener $server } else { Run-TcpListener $server }

try { if ($script:mode -eq 'httplistener') { $server.Stop() } else { $server.Stop() } } catch { }
Write-Line '종료했습니다.'
