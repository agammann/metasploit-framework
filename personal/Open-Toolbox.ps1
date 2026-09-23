$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $setupDir 'compose.yaml'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker Desktop is required. Install it before opening the toolbox.'
}

& docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Desktop is not ready. Run Launch-Metasploit.cmd first.'
}

& docker image inspect personal-metasploit:6.5.5 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'The toolkit image is missing. Run Launch-Metasploit.cmd first.'
}

Write-Host 'Opening toolbox. Nmap, sqlmap, John, Hydra, TShark, Nikto, Aircrack-ng, Volatility 3, and Sleuth Kit are available here.'
Write-Host 'Files in this folder\workspace are available inside the container at /workspace.'
& docker compose --project-directory $setupDir -f $composeFile run --rm --no-deps msf sh
if ($LASTEXITCODE -ne 0) { throw "Toolbox exited with code $LASTEXITCODE." }
