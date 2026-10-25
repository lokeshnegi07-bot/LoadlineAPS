# Loadline APS local web server: serves the site folder at http://localhost:<port>/ for this PC only.
param([int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'site'))
$types = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.json'='application/json'; '.svg'='image/svg+xml';
  '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.webp'='image/webp'; '.ico'='image/x-icon'; '.mp4'='video/mp4'; '.webm'='video/webm'; '.vtt'='text/vtt'; '.txt'='text/plain; charset=utf-8'; '.xlsx'='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:$Port/")
$http.Start()
while ($http.IsListening) {
  $ctx = $http.GetContext(); $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    if ($path -eq '/__ping') { $b = [Text.Encoding]::UTF8.GetBytes('loadline'); $res.ContentType = 'text/plain'; $res.OutputStream.Write($b, 0, $b.Length); continue }
    if ($path -eq '/__stop') { $res.StatusCode = 204; $res.Close(); $http.Stop(); break }
    if ($path.EndsWith('/')) { $path += 'index.html' }
    $full = [IO.Path]::GetFullPath((Join-Path $root $path.TrimStart('/')))
    if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not [IO.File]::Exists($full)) {
      $res.StatusCode = 404; $b = [Text.Encoding]::UTF8.GetBytes('Not found'); $res.OutputStream.Write($b, 0, $b.Length); continue
    }
    $ext = [IO.Path]::GetExtension($full).ToLower()
    $res.ContentType = $(if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' })
    $res.Headers['Cache-Control'] = 'no-cache'
    $fs = [IO.File]::OpenRead($full)
    try { $res.ContentLength64 = $fs.Length; $fs.CopyTo($res.OutputStream) } finally { $fs.Dispose() }
  } catch { try { $res.StatusCode = 500 } catch {} }
  finally { try { $res.Close() } catch {} }
}
