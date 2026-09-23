$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $setupDir 'compose.yaml'
$envFile = Join-Path $setupDir '.env'
$moduleDir = Join-Path $setupDir 'modules'
$workspaceDir = Join-Path $setupDir 'workspace'
$composeArgs = @('compose', '--project-directory', $setupDir, '-f', $composeFile)

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker Desktop is required. Install and start it before running this script.'
}

& docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Starting Docker Desktop...'
    Start-Process -FilePath (Get-Command docker).Source -ArgumentList @('desktop', 'start') -WindowStyle Hidden | Out-Null
    $dockerReady = $false
    for ($attempt = 0; $attempt -lt 120; $attempt++) {
        Start-Sleep -Seconds 2
        & docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $dockerReady = $true
            break
        }
        if (($attempt + 1) % 15 -eq 0) {
            Write-Host 'Still waiting for Docker Desktop...'
        }
    }
    if (-not $dockerReady) {
        throw 'Docker Desktop did not become ready. Open Docker Desktop, check its status, and run this script again.'
    }
}

if (-not (Test-Path -LiteralPath $envFile)) {
    $candidateProject = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { 'personal-metasploit' }
    & docker volume inspect "${candidateProject}_db_data" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        throw "The database for '$candidateProject' still exists, but personal/.env is missing. Restore the original .env file before starting so its database password stays the same."
    }

    $secretBytes = New-Object byte[] 32
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $random.GetBytes($secretBytes)
    }
    finally {
        $random.Dispose()
    }
    $password = -join ($secretBytes | ForEach-Object { $_.ToString('x2') })
    Set-Content -LiteralPath $envFile -Value "MSF_DB_PASSWORD=$password" -Encoding ASCII
}

# Compose must use the password stored beside this setup, even if the caller
# happens to have an unrelated variable with the same name.
Remove-Item Env:\MSF_DB_PASSWORD -ErrorAction SilentlyContinue
$composeConfigJson = & docker @composeArgs config --format json
if ($LASTEXITCODE -ne 0) { throw 'Metasploit Compose configuration is invalid.' }
$composeConfig = $composeConfigJson | ConvertFrom-Json
$projectName = $composeConfig.name
if (-not $projectName) { throw 'Could not determine the Metasploit Compose project name.' }

$existingConsole = & docker ps --quiet --filter "label=com.docker.compose.project=$projectName" --filter 'label=personal.metasploit.role=console'
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect running Metasploit consoles.' }
if ($existingConsole) {
    & (Join-Path $setupDir 'Start-Companions.ps1') -ProjectName $projectName
    Write-Host 'A Metasploit console is already running. Use its existing window, or Stop and Launch again if that window was closed.'
    return
}

$publishedPort = @($composeConfig.services.msf.ports)[0]
if (-not $publishedPort -or -not $publishedPort.published) {
    throw 'Metasploit Compose configuration has no published listener port.'
}
$bindAddress = if ($publishedPort.host_ip) { [string]$publishedPort.host_ip } else { '0.0.0.0' }
try {
    $bindIp = [System.Net.IPAddress]::Parse($bindAddress)
    $portProbe = [System.Net.Sockets.TcpListener]::new($bindIp, [int]$publishedPort.published)
    $portProbe.Start()
}
catch {
    throw "Cannot reserve ${bindAddress}:$($publishedPort.published) for Metasploit. Check MSF_BIND_ADDRESS or stop the program using this port. $($_.Exception.Message)"
}
finally {
    if ($portProbe) { $portProbe.Stop() }
}

New-Item -ItemType Directory -Force -Path $moduleDir, $workspaceDir | Out-Null

Write-Host 'Building the pinned Metasploit image...'
& docker @composeArgs build msf
if ($LASTEXITCODE -ne 0) { throw 'Metasploit image build failed.' }

Write-Host 'Starting the database...'
& docker @composeArgs up -d db
if ($LASTEXITCODE -ne 0) { throw 'Database startup failed.' }

$stopMarker = Join-Path $workspaceDir '.stop-requested'
Set-Content -LiteralPath $stopMarker -Value 'false' -Encoding ASCII
& (Join-Path $setupDir 'Start-Companions.ps1') -ProjectName $projectName

Write-Host 'Opening Metasploit console. Type exit to close it.'
& docker @composeArgs run --rm --service-ports --label personal.metasploit.role=console msf
if ($LASTEXITCODE -ne 0) {
    if ((Test-Path -LiteralPath $stopMarker) -and ((Get-Content -LiteralPath $stopMarker -Raw).Trim() -eq 'true')) {
        Write-Host 'Metasploit stopped by the Stop button.'
    }
    else {
        throw "Metasploit exited with code $LASTEXITCODE."
    }
}
