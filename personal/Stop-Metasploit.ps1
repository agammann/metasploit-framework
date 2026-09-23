$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $setupDir 'compose.yaml'

& docker compose --project-directory $setupDir -f $composeFile down
if ($LASTEXITCODE -ne 0) { throw 'Could not stop the Metasploit services.' }

Write-Host 'Metasploit services stopped. Your database volume is preserved.'
