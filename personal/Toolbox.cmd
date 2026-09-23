@echo off
setlocal
pushd "%~dp0" || exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Open-Toolbox.ps1"
set "result=%errorlevel%"
popd
if not "%result%"=="0" (
  echo.
  echo The toolbox could not open. Review the error above.
  pause
)
exit /b %result%
