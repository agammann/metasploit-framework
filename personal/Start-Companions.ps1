param([string] $ProjectName)

$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $setupDir 'companions.local.json'
$settings = @{
    OpenToolbox = $true
    OpenRustCveSniffer = $true
    RustCveSnifferPath = ''
}

if (Test-Path -LiteralPath $configPath) {
    try {
        $local = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        foreach ($key in @($settings.Keys)) {
            if ($null -ne $local.PSObject.Properties[$key]) {
                $settings[$key] = $local.$key
            }
        }
    }
    catch {
        Write-Warning "Could not read companions.local.json: $($_.Exception.Message)"
    }
}

if (-not $ProjectName) {
    $ProjectName = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { 'personal-metasploit' }
}

if ($settings.OpenToolbox) {
    try {
        $runningToolbox = & docker ps --quiet --filter "label=com.docker.compose.project=$ProjectName" --filter 'label=personal.metasploit.role=toolbox'
        if ($runningToolbox) {
            Write-Host 'The command-line toolbox is already open.'
        }
        else {
            $toolbox = Join-Path $setupDir 'Toolbox.cmd'
            Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', ('"' + $toolbox + '"')) -WorkingDirectory $setupDir -WindowStyle Normal | Out-Null
            Write-Host 'Opened the command-line toolbox.'
        }
    }
    catch {
        Write-Warning "Could not open the toolbox: $($_.Exception.Message)"
    }
}

if ($settings.OpenRustCveSniffer) {
    $scannerBatch = if ($settings.RustCveSnifferPath) {
        [string] $settings.RustCveSnifferPath
    }
    else {
        Join-Path $setupDir 'tools/rust-cve-sniffer-v0.5.0/Start Scanner.bat'
    }
    if (Test-Path -LiteralPath $scannerBatch -PathType Leaf) {
        try {
            $runningScanner = @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.CommandLine -match '(?i)scan-ui\.ps1' -and
                    $_.CommandLine -match [regex]::Escape((Split-Path -Leaf (Split-Path -Parent $scannerBatch)))
                })
            if ($runningScanner.Count -gt 0) {
                Write-Host 'Rust CVE Sniffer is already open.'
            }
            else {
                Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', ('"' + $scannerBatch + '"')) -WorkingDirectory (Split-Path -Parent $scannerBatch) -WindowStyle Normal | Out-Null
                Write-Host 'Opened Rust CVE Sniffer.'
            }
        }
        catch {
            Write-Warning "Could not open Rust CVE Sniffer: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host 'Rust CVE Sniffer is not installed; skipping.'
    }
}
