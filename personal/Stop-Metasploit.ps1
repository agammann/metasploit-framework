$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $setupDir 'compose.yaml'
$projectName = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { 'personal-metasploit' }
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

& docker compose --project-directory $setupDir -f $composeFile down
if ($LASTEXITCODE -ne 0) { throw 'Could not stop the Metasploit services.' }

Write-Host 'Metasploit services stopped. Your database volume is preserved.'
