@echo off
title Install Loadline APS
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\install.ps1"
if errorlevel 1 (echo. & echo   Installation did not finish. See the message above.)
echo.
pause
