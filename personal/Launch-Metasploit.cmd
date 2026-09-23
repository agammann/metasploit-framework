@echo off
setlocal
pushd "%~dp0" || exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Metasploit.ps1"
set "result=%errorlevel%"
popd
if not "%result%"=="0" (
  echo.
  echo Metasploit could not start. Review the error above.
  pause
)
exit /b %result%
