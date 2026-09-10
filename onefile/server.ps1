param(
  [string]$Source = '',
  [int]$Port = 0,
  [switch]$NoBrowser,
  [switch]$TestAllowLocal,
  [string]$TestUpstream = ''
)

# 축구 분석기 - 내 PC 안에서만 도는 작은 서버.
#
# 왜 필요한가: football-data.org 같은 API 는 브라우저가 직접 부르면 막습니다(CORS).
# 브라우저가 아니라 이 서버가 대신 부르면 그런 제약이 없습니다.
# 윈도우에 기본으로 들어 있는 PowerShell 로만 돌아가므로 설치할 것이 없습니다.

$ErrorActionPreference = 'Stop'

# 무슨 일이 생기든 창이 그냥 사라지지 않게 합니다.
# 창이 번쩍하고 닫히면 무엇이 잘못됐는지 알 길이 없습니다.
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

# 이 서버가 말을 걸어도 되는 곳. 여기 없는 주소는 아예 부르지 않습니다.
$ALLOWED = @(
  'v3.football.api-sports.io',
  'api.football-data.org',
  'api.openligadb.de',
  'www.thesportsdb.com',
  'thesportsdb.com'
)

# 헤더 이름 -> 그 헤더를 받아도 되는 호스트.
# football-data.org 토큰이 TheSportsDB 로 가는 일이 생기지 않게 합니다.
$HEADER_HOME = @{
  'x-auth-token'    = @('api.football-data.org')
  'x-apisports-key' = @('v3.football.api-sports.io')
}

# 무료 등급 기준 호스트별 최소 호출 간격(초).
$MIN_GAP = @{
  'api.football-data.org'      = 6.5
  'v3.football.api-sports.io'  = 0.4
  'api.openligadb.de'          = 0.2
  'www.thesportsdb.com'        = 1.2
  'thesportsdb.com'            = 1.2
}
$script:lastCall = @{}

function Write-Line([string]$m) {
  Write-Host ("{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m)
}

# ---------------------------------------------------------------- 화면 꺼내기

function Get-EmbeddedHtml([string]$path) {
  $lines = [IO.File]::ReadAllLines($path)
  $start = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i].Trim() -eq '::HTMLB64::') { $start = $i; break }
  }
  if ($start -lt 0) { throw '화면 데이터를 찾지 못했습니다.' }
  $sb = New-Object Text.StringBuilder
  for ($k = $start + 1; $k -lt $lines.Length; $k++) {
    $l = $lines[$k].Trim()
    if ($l.Length -gt 0) { [void]$sb.Append($l) }
  }
  return [Convert]::FromBase64String($sb.ToString())
}

# ---------------------------------------------------------------- HTTP 유틸

function Read-Head($stream) {
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

function Send-Response($stream, [string]$status, [string]$ctype, [byte[]]$body) {
  if ($null -eq $body) { $body = New-Object byte[] 0 }
  $head = "HTTP/1.1 $status`r`n" +
          "Content-Type: $ctype`r`n" +
          "Content-Length: $($body.Length)`r`n" +
          "Cache-Control: no-store`r`n" +
          "Connection: close`r`n`r`n"
  $hb = [Text.Encoding]::UTF8.GetBytes($head)
  $stream.Write($hb, 0, $hb.Length)
  if ($body.Length -gt 0) { $stream.Write($body, 0, $body.Length) }
  $stream.Flush()
}

function Send-Json($stream, [string]$status, [string]$json) {
  Send-Response $stream $status 'application/json; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes($json))
}

function Get-QueryValue([string]$query, [string]$name) {
  foreach ($pair in $query.Split('&')) {
    $eq = $pair.IndexOf('=')
    if ($eq -lt 0) { continue }
    if ($pair.Substring(0, $eq) -eq $name) {
      return [Uri]::UnescapeDataString($pair.Substring($eq + 1))
    }
  }
  return ''
}

# ---------------------------------------------------------------- 바깥 호출

function Wait-Turn([string]$hostName) {
  $gap = $MIN_GAP[$hostName]
  if (-not $gap) { return }
  $prev = $script:lastCall[$hostName]
  if ($prev) {
    $wait = $prev.AddSeconds($gap) - (Get-Date)
    if ($wait.TotalMilliseconds -gt 0) {
      Start-Sleep -Milliseconds ([int]$wait.TotalMilliseconds)
    }
  }
  $script:lastCall[$hostName] = Get-Date
}

function Invoke-Upstream([string]$url, $clientHeaders) {
  try { $uri = [Uri]$url } catch { return @{ status = 0; body = '주소를 해석하지 못했습니다'; ctype = 'text/plain' } }

  $hostName = $uri.Host
  $okScheme = ($uri.Scheme -eq 'https')
  if ($TestAllowLocal -and $uri.Scheme -eq 'http' -and $hostName -eq '127.0.0.1') { $okScheme = $true }
  if (-not $okScheme) { return @{ status = 400; body = '{"message":"https 만 허용합니다"}'; ctype = 'application/json' } }

  $allowed = ($ALLOWED -contains $hostName)
  if ($TestAllowLocal -and $hostName -eq '127.0.0.1') { $allowed = $true }
  if (-not $allowed) {
    Write-Line "  차단  허용되지 않은 호스트: $hostName"
    return @{ status = 403; body = '{"message":"허용되지 않은 호스트입니다"}'; ctype = 'application/json' }
  }

  $started = Get-Date
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    Wait-Turn $hostName
    try {
      # 시험용: 실제 API 대신 내 PC 의 가짜 서버로 보냅니다. 허용 검사와 헤더
      # 검사는 위에서 원래 주소로 이미 끝났으므로 그대로 유지됩니다.
      $sendUrl = $url
      if ($TestUpstream) { $sendUrl = $TestUpstream.TrimEnd('/') + $uri.PathAndQuery }
      $req = New-Object Net.Http.HttpRequestMessage ([Net.Http.HttpMethod]::Get), $sendUrl
      [void]$req.Headers.TryAddWithoutValidation('Accept', 'application/json')
      [void]$req.Headers.TryAddWithoutValidation('User-Agent', 'SportsAIAnalyzer/4.0 (local)')
      foreach ($k in $clientHeaders.Keys) {
        $lk = $k.ToLower()
        $allowHosts = $HEADER_HOME[$lk]
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
        Write-Line "  $code  $url - $([int](1.5*$attempt))초 뒤 재시도 ($attempt/3)"
        Start-Sleep -Milliseconds ([int](1500 * $attempt))
        continue
      }
      Write-Line "  $code  $url  (${ms}ms)"
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
      return @{ status = 502; body = "{`"message`":`"연결 실패: $esc`"}"; ctype = 'application/json' }
    }
  }
}

# ---------------------------------------------------------------- 시작

if (-not $Source) { $Source = $PSCommandPath }
$htmlBytes = Get-EmbeddedHtml $Source
Write-Line ("화면 준비됨 - {0:N0} 바이트" -f $htmlBytes.Length)

$script:http = New-Object Net.Http.HttpClient
$script:http.Timeout = [TimeSpan]::FromSeconds(25)

$candidates = if ($Port -gt 0) { @($Port) } else { @(8791, 8792, 8793, 8794, 8795) }
$listener = $null
foreach ($p in $candidates) {
  try {
    $l = New-Object Net.Sockets.TcpListener ([Net.IPAddress]::Loopback), $p
    $l.Start()
    $listener = $l
    $Port = $p
    break
  }
  catch { }
}
if ($null -eq $listener) {
  Write-Host ''
  Write-Host '[오류] 쓸 수 있는 포트를 찾지 못했습니다.'
  Write-Host '       다른 프로그램이 8791~8795 를 쓰고 있습니다.'
  Write-Host ''
  Read-Host '엔터를 누르면 닫힙니다'
  exit 1
}

$root = "http://127.0.0.1:$Port/"
Write-Host ''
Write-Host '  ============================================'
Write-Host '   축구 분석기가 준비됐습니다.'
Write-Host ''
Write-Host "   주소:  $root"
Write-Host ''
Write-Host '   * 브라우저가 저절로 열립니다.'
Write-Host '     안 열리면 위 주소를 직접 붙여넣으세요.'
Write-Host '   * 이 검은 창을 닫으면 프로그램이 꺼집니다.'
Write-Host '  ============================================'
Write-Host ''

if (-not $NoBrowser) {
  try { Start-Process $root } catch { Write-Line "브라우저를 여는 데 실패했습니다: $($_.Exception.Message)" }
}

$running = $true
while ($running) {
  $client = $null
  try {
    $client = $listener.AcceptTcpClient()
    $client.ReceiveTimeout = 15000
    $client.SendTimeout = 30000
    $ns = $client.GetStream()

    $head = Read-Head $ns
    if (-not $head) { $client.Close(); continue }

    $lines = $head -split "`r`n"
    $parts = $lines[0] -split ' '
    if ($parts.Length -lt 2) { $client.Close(); continue }
    $method = $parts[0]
    $target = $parts[1]

    $headers = @{}
    for ($i = 1; $i -lt $lines.Length; $i++) {
      $c = $lines[$i].IndexOf(':')
      if ($c -gt 0) { $headers[$lines[$i].Substring(0, $c).Trim()] = $lines[$i].Substring($c + 1).Trim() }
    }

    $path = $target
    $query = ''
    $q = $target.IndexOf('?')
    if ($q -ge 0) { $path = $target.Substring(0, $q); $query = $target.Substring($q + 1) }

    if ($method -ne 'GET') {
      Send-Json $ns '405 Method Not Allowed' '{"message":"GET만 지원합니다"}'
    }
    elseif ($path -eq '/' -or $path -eq '/index.html') {
      Send-Response $ns '200 OK' 'text/html; charset=utf-8' $htmlBytes
    }
    elseif ($path -eq '/__ping') {
      Send-Json $ns '200 OK' "{`"ok`":true,`"port`":$Port,`"server`":`"powershell`"}"
    }
    elseif ($path -eq '/__quit') {
      Send-Json $ns '200 OK' '{"ok":true}'
      $running = $false
    }
    elseif ($path -eq '/favicon.ico') {
      Send-Response $ns '204 No Content' 'image/x-icon' (New-Object byte[] 0)
    }
    elseif ($path -eq '/proxy') {
      $url = Get-QueryValue $query 'url'
      if (-not $url) {
        Send-Json $ns '400 Bad Request' '{"message":"url 이 없습니다"}'
      }
      else {
        $r = Invoke-Upstream $url $headers
        $bytes = if ($r.ContainsKey('bytes')) { $r.bytes } else { [Text.Encoding]::UTF8.GetBytes([string]$r.body) }
        $code = [int]$r.status
        if ($code -le 0) { $code = 502 }
        Send-Response $ns "$code X" $r.ctype $bytes
      }
    }
    else {
      Send-Json $ns '404 Not Found' '{"message":"없는 주소입니다"}'
    }
  }
  catch {
    Write-Line "요청 처리 중 오류: $($_.Exception.Message)"
  }
  finally {
    if ($client) { try { $client.Close() } catch { } }
  }
}

try { $listener.Stop() } catch { }
Write-Line '종료했습니다.'
