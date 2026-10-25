# Opens Loadline APS: starts the local server if it isn't running, opens the app window, then checks GitHub for updates.
$Port = 8765
$dir = $PSScriptRoot
function Test-Up { try { (Invoke-WebRequest "http://localhost:$Port/__ping" -UseBasicParsing -TimeoutSec 1).Content -eq 'loadline' } catch { $false } }
if (-not (Test-Up)) {
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$dir\server.ps1`"", '-Port', $Port)
  for ($i = 0; $i -lt 60 -and -not (Test-Up); $i++) { Start-Sleep -Milliseconds 250 }
}
$url = "http://localhost:$Port/index.html"
$browsers = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")
$b = $browsers | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
# --app opens Loadline in its own window, without tabs or an address bar, like a desktop program
if ($b) { Start-Process $b -ArgumentList "--app=$url" } else { Start-Process $url }
& "$dir\update.ps1"
