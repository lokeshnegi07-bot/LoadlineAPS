# Installs Loadline APS for the current Windows user (no administrator rights needed).
$ErrorActionPreference = 'Stop'
$pkg = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $env:LOCALAPPDATA 'Programs\Loadline'
Write-Host ''
Write-Host '  Installing Loadline APS' -ForegroundColor Cyan
Write-Host "  Folder: $dest"
try { Invoke-WebRequest 'http://localhost:8765/__stop' -UseBasicParsing -TimeoutSec 2 | Out-Null; Start-Sleep -Milliseconds 500 } catch {}
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item -Path (Join-Path $pkg 'site') -Destination $dest -Recurse -Force
Get-ChildItem $PSScriptRoot -File | Where-Object { $_.Name -ne 'install.ps1' } | Copy-Item -Destination $dest -Force
Get-ChildItem $dest -Recurse -File | Unblock-File
$sh = New-Object -ComObject WScript.Shell
function New-Shortcut($path, $target, $arguments, $desc) {
  $l = $sh.CreateShortcut($path); $l.TargetPath = $target; $l.Arguments = $arguments; $l.WorkingDirectory = $dest
  $l.IconLocation = "$dest\loadline.ico,0"; $l.Description = $desc; $l.Save()
}
$open = "`"$dest\launch.vbs`""
$menu = Join-Path ([Environment]::GetFolderPath('Programs')) 'Loadline'
New-Item -ItemType Directory -Path $menu -Force | Out-Null
New-Shortcut (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Loadline APS.lnk') "$env:WINDIR\System32\wscript.exe" $open 'Open Loadline APS'
New-Shortcut "$menu\Loadline APS.lnk" "$env:WINDIR\System32\wscript.exe" $open 'Open Loadline APS'
New-Shortcut "$menu\Stop Loadline server.lnk" "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dest\stop.ps1`"" 'Stop the Loadline APS server on this PC'
New-Shortcut "$menu\Uninstall Loadline.lnk" "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dest\uninstall.ps1`"" 'Remove Loadline APS'
$ans = Read-Host '  Start the Loadline server when Windows starts? (Y/N)'
if ($ans -match '^[Yy]') { New-Shortcut (Join-Path ([Environment]::GetFolderPath('Startup')) 'Loadline APS server.lnk') "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dest\server.ps1`"" 'Loadline APS server' }
# shows in Settings > Apps, with Uninstall
$ver = '1.0'; try { $ver = (Get-Content "$dest\site\version.json" -Raw | ConvertFrom-Json).version } catch {}
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\LoadlineAPS'
New-Item -Path $key -Force | Out-Null
@{ DisplayName = 'Loadline APS'; DisplayVersion = $ver; Publisher = 'Loadline'; DisplayIcon = "$dest\loadline.ico"; InstallLocation = $dest
   UninstallString = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dest\uninstall.ps1`"" }.GetEnumerator() | ForEach-Object { New-ItemProperty -Path $key -Name $_.Key -Value $_.Value -PropertyType String -Force | Out-Null }
New-ItemProperty -Path $key -Name NoModify -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $key -Name NoRepair -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host ''
Write-Host '  Done. Loadline APS is on your desktop and in the Start menu.' -ForegroundColor Green
Write-Host '  It runs at http://localhost:8765 on this PC and updates itself from GitHub when a new version is published.'
Write-Host ''
Start-Process "$env:WINDIR\System32\wscript.exe" -ArgumentList $open
