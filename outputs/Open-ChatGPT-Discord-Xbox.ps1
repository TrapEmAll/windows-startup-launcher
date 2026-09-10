[CmdletBinding()]
param(
    [switch]$Interactive,
    [switch]$Test,
    [switch]$DryRun,
    [switch]$NoApps,
    [switch]$VerboseOutput
)

$script:Version = '1.0.0'
$script:Config = [ordered]@{
    LaunchChatGPT = $true
    LaunchDiscord = $true
    LaunchXbox = $true
    StartupDelaySeconds = 3
    PerAppDelaySeconds = 1
    PreventDuplicates = $true
    LogFile = Join-Path $env:TEMP 'startup-launcher.log'
}

function Write-LauncherLog {
    param([string]$Message)
    $line = "$(Get-Date -Format s) $Message"
    Add-Content -LiteralPath $script:Config.LogFile -Value $line -ErrorAction SilentlyContinue
    if ($VerboseOutput) { Write-Host $line }
}

function Start-InstalledApp {
    param([string]$NamePattern, [string[]]$ProcessNames = @())
    $app = Get-StartApps | Where-Object { $_.Name -match $NamePattern } | Select-Object -First 1
    if (-not $app) { Write-LauncherLog "Not found: $NamePattern"; return $false }
    if ($script:Config.PreventDuplicates -and $ProcessNames) {
        if (Get-Process -Name $ProcessNames -ErrorAction SilentlyContinue) {
            Write-LauncherLog "Already running: $NamePattern"; return $true
        }
    }
    if ($DryRun) { Write-Host "[dry run] Start $($app.Name)"; return $true }
    Start-Process "shell:AppsFolder\$($app.AppID)"
    Write-LauncherLog "Started: $($app.Name)"
    return $true
}

function Start-ProtocolApp {
    param([string]$Protocol, [string]$Label)
    if ($DryRun) { Write-Host "[dry run] Start $Label ($Protocol)"; return $true }
    Start-Process $Protocol
    Write-LauncherLog "Started protocol: $Label"
    return $true
}

function Invoke-AppStartup {
    if (-not $NoApps) {
        Start-Sleep -Seconds $script:Config.StartupDelaySeconds
        if ($script:Config.LaunchChatGPT) { [void](Start-InstalledApp '^ChatGPT$' @('ChatGPT')) }
        Start-Sleep -Seconds $script:Config.PerAppDelaySeconds
        if ($script:Config.LaunchDiscord) {
            if (-not (Start-InstalledApp '^Discord$' @('Discord'))) { [void](Start-ProtocolApp 'discord:' 'Discord') }
        }
        Start-Sleep -Seconds $script:Config.PerAppDelaySeconds
        if ($script:Config.LaunchXbox) { [void](Start-ProtocolApp 'xbox:' 'Xbox') }
    }
    Write-LauncherLog 'Startup routine complete'
}

function Show-SystemSummary {
    Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime
    Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free
}

function Invoke-SelfTest {
    Write-Host "Startup Launcher v$script:Version"
    Write-Host "PowerShell $($PSVersionTable.PSVersion)"
    foreach ($item in @(@('ChatGPT','^ChatGPT$'),@('Discord','^Discord$'))) {
        $found = Get-StartApps | Where-Object { $_.Name -match $item[1] } | Select-Object -First 1
        Write-Host "$($item[0]): $([bool]$found)"
    }
    Write-Host "Xbox protocol: $([bool](Get-Command Start-Process))"
    Write-Host "Log file: $($script:Config.LogFile)"
}

function Invoke-UtilityFeature {
    param([int]$Feature)
    $folders = [ordered]@{
        11 = ([Environment]::GetFolderPath('MyDocuments'))
        12 = ([Environment]::GetFolderPath('UserProfile'))
        13 = ([Environment]::GetFolderPath('Desktop'))
        14 = ([Environment]::GetFolderPath('MyPictures'))
        15 = ([Environment]::GetFolderPath('MyMusic'))
        16 = ([Environment]::GetFolderPath('MyVideos'))
        17 = (Join-Path $env:USERPROFILE 'Downloads')
        18 = $env:TEMP
        19 = (Join-Path $env:USERPROFILE 'OneDrive')
        20 = (Join-Path $env:USERPROFILE 'source\repos')
    }
    if ($folders.Contains($Feature)) {
        if (Test-Path $folders[$Feature]) { Start-Process $folders[$Feature] }
        else { Write-Warning "Folder not found: $($folders[$Feature])" }
        return
    }
    $targets = @{
        21 = 'shell:startup'
        22 = 'ms-settings:'
        23 = 'ms-settings:windowsupdate'
        24 = 'ms-settings:display'
        25 = 'ms-settings:sound'
        26 = 'ms-settings:bluetooth'
        27 = 'ms-settings:appsfeatures'
        28 = 'ms-settings:privacy'
        29 = 'windowsdefender:'
        30 = 'control'
    }
    if ($targets.ContainsKey($Feature)) { Start-Process $targets[$Feature]; return }
    $tools = @{
        31 = 'taskmgr.exe'
        32 = 'devmgmt.msc'
        33 = 'ncpa.cpl'
        34 = 'wt.exe'
        35 = 'powershell.exe'
        36 = 'cmd.exe'
        37 = 'calc.exe'
        38 = 'notepad.exe'
        39 = 'snippingtool.exe'
        40 = 'explorer.exe'
    }
    if ($tools.ContainsKey($Feature)) { Start-Process $tools[$Feature]; return }
    switch ($Feature) {
        41 { Show-SystemSummary | Format-List }
        42 { Get-CimInstance Win32_Battery | Select-Object Name, BatteryStatus, EstimatedChargeRemaining | Format-List }
        43 { Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free | Format-Table -AutoSize }
        44 { Get-NetConnectionProfile | Select-Object Name, InterfaceAlias, NetworkCategory, IPv4Connectivity | Format-Table -AutoSize }
        45 { (Get-CimInstance Win32_OperatingSystem).LastBootUpTime }
        46 { Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory | Format-List }
        47 { Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-List }
        48 { if (Test-Path $script:Config.LogFile) { Get-Content $script:Config.LogFile } else { Write-Host 'No log entries.' } }
        49 { if ((Read-Host 'Clear launcher log? Type YES') -eq 'YES') { Clear-Content -LiteralPath $script:Config.LogFile -ErrorAction SilentlyContinue } }
        50 { Write-Host "Startup Launcher v$script:Version" }
    }
}

function Show-LauncherMenu {
    do {
        Clear-Host
        Write-Host "Startup Launcher v$script:Version"
        Write-Host '1. Launch configured apps'
        Write-Host '2. Run self-test'
        Write-Host '3. Show system summary'
        Write-Host '4. Open startup folder'
        Write-Host '5. Open Windows Settings'
        Write-Host '6. Open a work folder'
        Write-Host '7. Show log'
        Write-Host '8. Exit'
        Write-Host '11-20. Open common folders'
        Write-Host '21-30. Open Windows settings and tools'
        Write-Host '31-40. Open system utilities'
        Write-Host '41-50. Diagnostics, logs, and version'
        switch (Read-Host 'Choose an option') {
            '1' { Invoke-AppStartup; Read-Host 'Press Enter' }
            '2' { Invoke-SelfTest; Read-Host 'Press Enter' }
            '3' { Show-SystemSummary | Format-List; Read-Host 'Press Enter' }
            '4' { Start-Process 'shell:startup' }
            '5' { Start-Process 'ms-settings:' }
            '6' { Start-Process ([Environment]::GetFolderPath('MyDocuments')) }
            '7' { if (Test-Path $script:Config.LogFile) { Get-Content $script:Config.LogFile | Select-Object -Last 30 }; Read-Host 'Press Enter' }
            '8' { return }
            { $_ -match '^1[1-9]$|^20$|^2[1-9]$|^3[0-9]$|^4[0-9]$|^50$' } { Invoke-UtilityFeature ([int]$_); Read-Host 'Press Enter' }
            default { Write-Host 'Invalid option'; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

if ($Test) { Invoke-SelfTest; exit 0 }
if ($Interactive) { Show-LauncherMenu; exit 0 }
Invoke-AppStartup
exit 0

