$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $setupDir 'companions.local.json'
$settings = @{
    OpenToolbox = $true
    OpenWireshark = $true
    OpenBurpSuite = $true
    WiresharkPath = ''
    BurpSuitePath = ''
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

if ($settings.OpenToolbox) {
    try {
        $projectName = if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { 'personal-metasploit' }
        $runningToolbox = & docker ps --quiet --filter "label=com.docker.compose.project=$projectName" --filter 'label=personal.metasploit.role=toolbox'
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

function Start-DesktopCompanion {
    param(
        [string] $Name,
        [object] $Enabled,
        [string] $ConfiguredPath,
        [string[]] $CandidatePaths,
        [string[]] $ProcessNames
    )

    if (-not $Enabled) { return }

    $paths = @()
    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) { $paths += $ConfiguredPath }
    $paths += $CandidatePaths
    $exe = $paths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $exe) {
        Write-Host "$Name is not installed at a known path; skipping."
        return
    }

    foreach ($processName in $ProcessNames) {
        if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
            Write-Host "$Name is already open."
            return
        }
    }

    try {
        Start-Process -FilePath $exe -WorkingDirectory (Split-Path -Parent $exe) -WindowStyle Normal | Out-Null
        Write-Host "Opened $Name."
    }
    catch {
        Write-Warning "Could not open $Name`: $($_.Exception.Message)"
    }
}

Start-DesktopCompanion -Name 'Wireshark' -Enabled $settings.OpenWireshark -ConfiguredPath $settings.WiresharkPath -CandidatePaths @(
    'C:\Program Files\Wireshark\Wireshark.exe'
) -ProcessNames @('Wireshark')

Start-DesktopCompanion -Name 'Burp Suite' -Enabled $settings.OpenBurpSuite -ConfiguredPath $settings.BurpSuitePath -CandidatePaths @(
    'C:\Program Files\BurpSuiteCommunity\BurpSuiteCommunity.exe',
    'C:\Program Files\BurpSuitePro\BurpSuitePro.exe'
) -ProcessNames @('BurpSuiteCommunity', 'BurpSuitePro')
