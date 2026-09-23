@echo off
setlocal
pushd "%~dp0" || exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Stop-Metasploit.ps1"
set "result=%errorlevel%"
popd
if not "%result%"=="0" (
  echo.
  echo The services could not be stopped. Review the error above.
  pause
)
exit /b %result%
