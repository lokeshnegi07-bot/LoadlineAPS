# Updates the local copy from GitHub when a newer version is published on the main branch.
# Runs in the background after the app opens; the update shows the next time Loadline is opened (or after a page reload).
# Your data is kept: it lives in the browser, not in these files.
$ErrorActionPreference = 'Stop'
$repo = 'lokeshnegi07-bot/LoadlineAPS'; $branch = 'main'
$site = Join-Path $PSScriptRoot 'site'; $log = Join-Path $PSScriptRoot 'update.log'
function Write-Log($m) { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm} {1}" -f (Get-Date), $m) }
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  $local = ''; try { $local = (Get-Content (Join-Path $site 'version.json') -Raw | ConvertFrom-Json).version } catch {}
  $remote = (Invoke-RestMethod "https://raw.githubusercontent.com/$repo/$branch/version.json?t=$([DateTime]::UtcNow.Ticks)" -TimeoutSec 10).version
  if (-not $remote -or $remote -eq $local) { exit }
  $tmp = Join-Path $env:TEMP ('loadline-update-' + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    Invoke-WebRequest "https://github.com/$repo/archive/refs/heads/$branch.zip" -OutFile "$tmp\src.zip" -UseBasicParsing -TimeoutSec 600
    Expand-Archive -Path "$tmp\src.zip" -DestinationPath "$tmp\x" -Force
    $src = Get-ChildItem "$tmp\x" -Directory | Select-Object -First 1
    if (-not $src -or -not (Test-Path "$($src.FullName)\app\index.html") -or -not (Test-Path "$($src.FullName)\version.json")) { throw 'The download does not look like Loadline.' }
    foreach ($item in 'index.html', 'auth.js', 'favicon.svg', 'version.json', 'app', 'media') {
      $from = Join-Path $src.FullName $item
      if (Test-Path $from) { Copy-Item -Path $from -Destination $site -Recurse -Force }
    }
    Write-Log "Updated from $local to $remote"
  } finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
} catch { Write-Log "Update check skipped: $($_.Exception.Message)" }
