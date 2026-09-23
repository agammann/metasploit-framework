param([string] $ProjectName)

$ErrorActionPreference = 'Stop'

$setupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $setupDir 'companions.local.json'
$settings = @{
    OpenToolbox = $true
    OpenWireshark = $true
    OpenBurpSuite = $true
    OpenRustCveSniffer = $true
    WiresharkPath = ''
    BurpSuitePath = ''
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
        if ([IO.Path]::GetExtension($exe) -eq '.lnk') {
            Start-Process -FilePath $exe | Out-Null
        }
        else {
            Start-Process -FilePath $exe -WorkingDirectory (Split-Path -Parent $exe) -WindowStyle Normal | Out-Null
        }
        Write-Host "Opened $Name."
    }
    catch {
        Write-Warning "Could not open $Name`: $($_.Exception.Message)"
    }
}

function Get-BurpSuiteCandidatePaths {
    $paths = New-Object 'System.Collections.Generic.List[string]'

    # An install4j shortcut records the actual executable even when the user
    # chooses a non-default directory or a per-user installation.
    $startMenus = @(
        [Environment]::GetFolderPath('StartMenu'),
        [Environment]::GetFolderPath('CommonStartMenu')
    )
    try { $shell = New-Object -ComObject WScript.Shell } catch { $shell = $null }
    if ($shell) {
        foreach ($startMenu in $startMenus) {
            if (-not $startMenu) { continue }
            $programs = Join-Path $startMenu 'Programs'
            if (-not (Test-Path -LiteralPath $programs -PathType Container)) { continue }
            $shortcuts = Get-ChildItem -LiteralPath $programs -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.BaseName -match '^Burp Suite(?:$| )' -and $_.BaseName -notmatch 'Uninstall' } |
                Sort-Object @{ Expression = { if ($_.BaseName -eq 'Burp Suite') { 0 } else { 1 } } }, FullName
            foreach ($shortcut in $shortcuts) {
                try {
                    $target = $shell.CreateShortcut($shortcut.FullName).TargetPath
                    if ($target -and (Test-Path -LiteralPath $target -PathType Leaf)) {
                        $paths.Add($shortcut.FullName)
                    }
                }
                catch { continue }
            }
        }
    }

    # Some installations omit Start Menu shortcuts. Windows uninstall entries
    # can still identify both per-user and machine-wide installs.
    $uninstallRoots = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($root in $uninstallRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        foreach ($key in (Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
            $entry = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction SilentlyContinue
            if (-not $entry -or $entry.DisplayName -notmatch '^Burp Suite(?:$| Community Edition| Professional)') { continue }
            $location = [string] $entry.InstallLocation
            if ($location) {
                foreach ($filename in @('BurpSuite.exe', 'BurpSuiteCommunity.exe', 'BurpSuitePro.exe')) {
                    $paths.Add((Join-Path $location.Trim('"') $filename))
                }
            }
            $icon = [string] $entry.DisplayIcon
            if ($icon -match '^\s*"([^"]+\.exe)"' -or $icon -match '^\s*([^,]+\.exe)(?:,\d+)?\s*$') {
                $iconPath = $matches[1]
                if ([IO.Path]::GetFileName($iconPath) -match '^BurpSuite(?:Community|Pro)?\.exe$') {
                    $paths.Add($iconPath)
                }
            }
        }
    }

    $installationBases = @($env:ProgramFiles, ${env:ProgramFiles(x86)})
    if ($env:LOCALAPPDATA) {
        $installationBases += $env:LOCALAPPDATA
        $installationBases += (Join-Path $env:LOCALAPPDATA 'Programs')
    }
    foreach ($base in $installationBases) {
        if (-not $base) { continue }
        foreach ($folder in @('BurpSuite', 'Burp Suite', 'BurpSuiteCommunity', 'BurpSuitePro')) {
            foreach ($filename in @('BurpSuite.exe', 'BurpSuiteCommunity.exe', 'BurpSuitePro.exe')) {
                $paths.Add((Join-Path (Join-Path $base $folder) $filename))
            }
        }
    }

    return $paths.ToArray() | Select-Object -Unique
}

Start-DesktopCompanion -Name 'Wireshark' -Enabled $settings.OpenWireshark -ConfiguredPath $settings.WiresharkPath -CandidatePaths @(
    'C:\Program Files\Wireshark\Wireshark.exe'
) -ProcessNames @('Wireshark')

Start-DesktopCompanion -Name 'Burp Suite' -Enabled $settings.OpenBurpSuite -ConfiguredPath $settings.BurpSuitePath -CandidatePaths @(Get-BurpSuiteCandidatePaths) -ProcessNames @('BurpSuite', 'BurpSuiteCommunity', 'BurpSuitePro')

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
