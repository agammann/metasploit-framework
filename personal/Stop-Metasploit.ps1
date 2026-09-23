$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $setupDir 'compose.yaml'
$composeArgs = @('compose', '--project-directory', $setupDir, '-f', $composeFile)
# Stopping containers does not connect to PostgreSQL. Supply a placeholder so
# Compose can still read the configuration if the local .env was lost.
$env:MSF_DB_PASSWORD = 'unused-for-stop'
$composeConfigJson = & docker @composeArgs config --format json
if ($LASTEXITCODE -ne 0) { throw 'Could not read the Metasploit Compose configuration.' }
$projectName = ($composeConfigJson | ConvertFrom-Json).name
if (-not $projectName) { throw 'Could not determine the Metasploit Compose project name.' }
$workspaceDir = Join-Path $setupDir 'workspace'
if (Test-Path -LiteralPath $workspaceDir) {
    Set-Content -LiteralPath (Join-Path $workspaceDir '.stop-requested') -Value 'true' -Encoding ASCII
}

$oneOffIds = @(& docker ps --quiet --filter "label=com.docker.compose.project=$projectName" --filter 'label=com.docker.compose.service=msf' --filter 'label=com.docker.compose.oneoff=True' | Where-Object { $_ })
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect running Metasploit containers.' }
if ($oneOffIds.Count -gt 0) {
    & docker stop @oneOffIds | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not stop a Metasploit console or toolbox.' }
}

& docker @composeArgs down
if ($LASTEXITCODE -ne 0) { throw 'Could not stop the Metasploit services.' }

Write-Host 'Metasploit services stopped. Your database volume is preserved.'
