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
    for ($attempt = 0; $attempt -lt 45; $attempt++) {
        Start-Sleep -Seconds 2
        & docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $dockerReady = $true
            break
        }
    }
    if (-not $dockerReady) {
        throw 'Docker Desktop did not become ready. Open Docker Desktop, check its status, and run this script again.'
    }
}

if (-not (Test-Path -LiteralPath $envFile)) {
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

New-Item -ItemType Directory -Force -Path $moduleDir, $workspaceDir | Out-Null

Write-Host 'Building the pinned Metasploit image...'
& docker @composeArgs build msf
if ($LASTEXITCODE -ne 0) { throw 'Metasploit image build failed.' }

Write-Host 'Starting the database...'
& docker @composeArgs up -d db
if ($LASTEXITCODE -ne 0) { throw 'Database startup failed.' }

Write-Host 'Opening Metasploit console. Type exit to close it.'
& docker @composeArgs run --rm --service-ports msf
if ($LASTEXITCODE -ne 0) { throw "Metasploit exited with code $LASTEXITCODE." }
