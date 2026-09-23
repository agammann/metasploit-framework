@echo off
setlocal
where winget >nul 2>&1
if errorlevel 1 (
  echo Windows Package Manager is required to install the desktop companions.
  pause
  exit /b 1
)

echo Installing Wireshark. Review any installer or license prompts.
winget install --exact --id WiresharkFoundation.Wireshark --source winget
set "wiresharkResult=%errorlevel%"

echo Installing Burp Suite Community Edition. Review any installer or license prompts.
winget install --exact --id PortSwigger.BurpSuite.Community --source winget
set "burpResult=%errorlevel%"

if not "%wiresharkResult%"=="0" echo Wireshark installation needs attention.
if not "%burpResult%"=="0" echo Burp Suite installation needs attention.
echo Launch-Metasploit.cmd will open detected desktop apps on its next run.
pause
if not "%wiresharkResult%"=="0" exit /b %wiresharkResult%
exit /b %burpResult%
