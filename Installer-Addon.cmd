@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Addon.ps1"
set "installExitCode=%ERRORLEVEL%"
echo.
pause
exit /b %installExitCode%
