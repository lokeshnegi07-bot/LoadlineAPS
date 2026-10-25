# Removes Loadline APS: stops the server, deletes the shortcuts, the Apps entry and the program folder.
$dir = $PSScriptRoot
try { Invoke-WebRequest 'http://localhost:8765/__stop' -UseBasicParsing -TimeoutSec 2 | Out-Null } catch {}
Remove-Item ([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'Loadline APS.lnk')) -Force -ErrorAction SilentlyContinue
Remove-Item ([IO.Path]::Combine([Environment]::GetFolderPath('Programs'), 'Loadline')) -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ([IO.Path]::Combine([Environment]::GetFolderPath('Startup'), 'Loadline APS server.lnk')) -Force -ErrorAction SilentlyContinue
Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\LoadlineAPS' -Recurse -Force -ErrorAction SilentlyContinue
Start-Process cmd.exe -WindowStyle Hidden -ArgumentList "/c timeout /t 2 >nul & rmdir /s /q `"$dir`""
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show('Loadline APS has been removed. Your data in the browser was not deleted.', 'Loadline APS') | Out-Null
