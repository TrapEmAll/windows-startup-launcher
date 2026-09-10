[CmdletBinding()]
param(
    [switch]$Interactive,
    [switch]$Test,
    [switch]$DryRun,
    [switch]$NoApps,
    [switch]$VerboseOutput
)

$script:Version = '2.0.0'
$script:Config = [ordered]@{
    LaunchChatGPT = $true
    LaunchDiscord = $true
    LaunchXbox = $true
    StartupDelaySeconds = 3
    PerAppDelaySeconds = 1
    PreventDuplicates = $true
    # Optional menu features are manual-only and enabled here by number.
    EnabledFeatures = 11..200
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

function Test-FeatureEnabled {
    param([int]$Feature)
    return ($script:Config.EnabledFeatures -contains $Feature)
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
    $productivityApps = @{
        51 = '^Microsoft Edge$'
        52 = '^Google Chrome$'
        53 = 'Visual Studio Code|^Code$'
        54 = '^Windows Terminal$'
        55 = '^Microsoft Teams$'
        56 = '^Zoom$'
        57 = '^Spotify$'
        58 = '^Steam$'
        59 = '^Notion$'
        60 = '^Obsidian$'
    }
    if ($productivityApps.ContainsKey($Feature)) {
        [void](Start-InstalledApp $productivityApps[$Feature])
        return
    }
    $webTargets = @{
        61 = 'https://chatgpt.com/'
        62 = 'https://github.com/'
        63 = 'https://calendar.google.com/'
        64 = 'https://mail.google.com/'
        65 = 'https://drive.google.com/'
        66 = 'https://www.youtube.com/'
        67 = 'https://weather.com/'
        68 = 'https://news.google.com/'
        69 = 'https://www.google.com/maps/'
        70 = 'https://www.reddit.com/'
    }
    if ($webTargets.ContainsKey($Feature)) { Start-Process $webTargets[$Feature]; return }
    switch ($Feature) {
        71 { Get-Date }
        72 { Get-TimeZone | Format-List }
        73 { Get-Culture | Format-List }
        74 { Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 Name, Id, CPU | Format-Table -AutoSize }
        75 { Get-Service | Where-Object Status -eq Running | Sort-Object DisplayName | Select-Object -First 30 Status, DisplayName | Format-Table -AutoSize }
        76 { Get-ChildItem Env: | Sort-Object Name | Format-Table -AutoSize }
        77 { $env:Path -split ';' | Where-Object { $_ } }
        78 { Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsArchitecture | Format-List }
        79 { Get-NetAdapter | Select-Object Name, Status, LinkSpeed, MacAddress | Format-Table -AutoSize }
        80 { Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, SizeRemaining, Size | Format-Table -AutoSize }
    }
    $workspaceTargets = @{
        81 = 'shell:AppsFolder'
        82 = 'shell:Common Startup'
        83 = 'shell:Recent'
        84 = 'shell:Fonts'
        85 = 'shell:SendTo'
        86 = 'shell:Common Programs'
        87 = 'shell:Administrative Tools'
        88 = 'shell:ConnectionsFolder'
        89 = 'shell:ControlPanelFolder'
        90 = (Split-Path $PSScriptRoot -Parent)
    }
    if ($workspaceTargets.ContainsKey($Feature)) { Start-Process $workspaceTargets[$Feature]; return }
    $utilityTargets = @{
        101='mspaint.exe'; 102='write.exe'; 103='charmap.exe'; 104='magnify.exe'; 105='osk.exe'
        106='eventvwr.msc'; 107='perfmon.exe'; 108='resmon.exe'; 109='msinfo32.exe'; 110='winver.exe'
    }
    if ($utilityTargets.ContainsKey($Feature)) { Start-Process $utilityTargets[$Feature]; return }
    $controlPanels = @{
        111='appwiz.cpl'; 112='desk.cpl'; 113='intl.cpl'; 114='main.cpl'; 115='powercfg.cpl'
        116='sysdm.cpl'; 117='firewall.cpl'; 118='timedate.cpl'; 119='wscui.cpl'; 120='hdwwiz.cpl'
    }
    if ($controlPanels.ContainsKey($Feature)) { Start-Process $controlPanels[$Feature]; return }
    $shellTargets = @{
        121='shell:AccountPictures'; 122='shell:AppData'; 123='shell:Common AppData'; 124='shell:Common Desktop'
        125='shell:Common Documents'; 126='shell:Common Downloads'; 127='shell:Common Pictures'
        128='shell:Common Music'; 129='shell:Common Videos'; 130='shell:Local AppData'
    }
    if ($shellTargets.ContainsKey($Feature)) { Start-Process $shellTargets[$Feature]; return }
    $developerApps = @{
        131='Docker'; 132='Postman'; 133='Visual Studio$'; 134='PyCharm'; 135='FileZilla'
        136='PuTTY'; 137='7-Zip'; 138='WinRAR'; 139='OBS Studio'; 140='Git Bash'
    }
    if ($developerApps.ContainsKey($Feature)) { [void](Start-InstalledApp $developerApps[$Feature]); return }
    $referenceSites = @{
        141='https://learn.microsoft.com/'; 142='https://learn.microsoft.com/powershell/'
        143='https://git-scm.com/doc'; 144='https://docs.github.com/'; 145='https://developer.mozilla.org/'
        146='https://stackoverflow.com/'; 147='https://www.w3.org/'; 148='https://www.python.org/doc/'
        149='https://docs.docker.com/'; 150='https://www.powershellgallery.com/'
    }
    if ($referenceSites.ContainsKey($Feature)) { Start-Process $referenceSites[$Feature]; return }
    switch ($Feature) {
        151 { Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed | Format-List }
        152 { Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion | Format-List }
        153 { Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate | Format-List }
        154 { Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber | Format-List }
        155 { Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, FileSystem, Size, FreeSpace | Format-Table -AutoSize }
        156 { Get-Printer | Select-Object Name, DriverName, PrinterStatus | Format-Table -AutoSize }
        157 { Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20 HotFixID, InstalledOn | Format-Table -AutoSize }
        158 { Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Select-Object -Last 10 | Format-Table -AutoSize }
        159 { Get-ScheduledTask | Where-Object State -ne Disabled | Select-Object -First 30 TaskName, State | Format-Table -AutoSize }
        160 { Get-Process | Group-Object Responding | Select-Object Name, Count | Format-Table -AutoSize }
        161 { ipconfig /all }
        162 { ping.exe 1.1.1.1 -n 4 }
        163 { nslookup.exe example.com }
        164 { tracert.exe -h 5 1.1.1.1 }
        165 { route.exe print }
        166 { netstat.exe -ano }
        167 { arp.exe -a }
        168 { hostname.exe }
        169 { whoami.exe /all }
        170 { systeminfo.exe }
        171 { Clear-DnsClientCache; Write-Host 'DNS cache flushed.' }
        172 { Get-NetIPConfiguration | Format-List }
        173 { Get-NetRoute -AddressFamily IPv4 | Format-Table -AutoSize }
        174 { Get-DnsClientServerAddress | Format-Table -AutoSize }
        175 { Get-NetFirewallProfile | Select-Object Name, Enabled | Format-Table -AutoSize }
        176 { Get-NetAdapterStatistics | Format-Table -AutoSize }
        177 { Get-WinEvent -LogName System -MaxEvents 20 | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-List }
        178 { Get-WinEvent -LogName Application -MaxEvents 20 | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-List }
        179 { Get-EventLog -LogName System -Newest 20 | Format-Table -AutoSize }
        180 { Get-EventLog -LogName Application -Newest 20 | Format-Table -AutoSize }
    }
    $mediaApps = @{
        181='Photos'; 182='Camera'; 183='Media Player'; 184='Xbox Game Bar'; 185='Movies & TV'
        186='Groove Music'; 187='Clipchamp'; 188='HEIF Image Extensions'; 189='AV1 Video Extension'; 190='Windows Media Player'
    }
    if ($mediaApps.ContainsKey($Feature)) { [void](Start-InstalledApp $mediaApps[$Feature]); return }
    $settingsTargets = @{
        191='ms-settings:easeofaccess-display'; 192='ms-settings:easeofaccess-keyboard'; 193='ms-settings:easeofaccess-mouse'
        194='ms-settings:notifications'; 195='ms-settings:storagesense'; 196='ms-settings:about'
        197='ms-settings:recovery'; 198='ms-settings:optionalfeatures'; 199='ms-settings:privacy-notifications'; 200='ms-settings:clipboard'
    }
    if ($settingsTargets.ContainsKey($Feature)) { Start-Process $settingsTargets[$Feature]; return }
    switch ($Feature) {
        91 { $note = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'startup-routine-note.txt'; if (-not (Test-Path $note)) { New-Item -ItemType File -Path $note | Out-Null }; Start-Process notepad.exe $note }
        92 { $note = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'startup-routine-note.txt'; if (Test-Path $note) { Start-Process notepad.exe $note } else { Write-Warning 'Note file does not exist. Use feature 91 first.' } }
        93 { Set-Clipboard -Value (Split-Path $PSScriptRoot -Parent); Write-Host 'Project path copied.' }
        94 { Set-Clipboard -Value 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File .\outputs\Windows-Startup-Routine.ps1'; Write-Host 'Startup command copied.' }
        95 { if ((Read-Host 'Clear launcher log? Type YES') -eq 'YES') { Clear-Content -LiteralPath $script:Config.LogFile -ErrorAction SilentlyContinue; Write-Host 'Log cleared.' } }
        96 { $configPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'startup-routine-config.json'; $script:Config | ConvertTo-Json | Set-Content -LiteralPath $configPath; Write-Host "Config exported to $configPath" }
        97 { Start-Process ([Environment]::GetFolderPath('MyDocuments')) }
        98 { Get-Help about_PowerShell -ErrorAction SilentlyContinue | Out-Host }
        99 { Write-Host 'Features 1-100 are available through interactive mode.' }
        100 { Write-Host "Startup Routine v$script:Version" }
    }
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
        Write-Host '51-60. Launch productivity apps'
        Write-Host '61-70. Open web destinations'
        Write-Host '71-80. Read-only diagnostics'
        Write-Host '81-90. Workspace navigation'
        Write-Host '91-100. Notes, clipboard, and help'
        Write-Host '101-110. Windows utilities'
        Write-Host '111-120. Control panels'
        Write-Host '121-130. Shell folders'
        Write-Host '131-140. Developer tools'
        Write-Host '141-150. Reference websites'
        Write-Host '151-160. Hardware diagnostics'
        Write-Host '161-170. Network diagnostics'
        Write-Host '171-180. Network and event tools'
        Write-Host '181-190. Media applications'
        Write-Host '191-200. Accessibility and settings'
        switch (Read-Host 'Choose an option') {
            '1' { Invoke-AppStartup; Read-Host 'Press Enter' }
            '2' { Invoke-SelfTest; Read-Host 'Press Enter' }
            '3' { Show-SystemSummary | Format-List; Read-Host 'Press Enter' }
            '4' { Start-Process 'shell:startup' }
            '5' { Start-Process 'ms-settings:' }
            '6' { Start-Process ([Environment]::GetFolderPath('MyDocuments')) }
            '7' { if (Test-Path $script:Config.LogFile) { Get-Content $script:Config.LogFile | Select-Object -Last 30 }; Read-Host 'Press Enter' }
            '8' { return }
            { $_ -match '^1[1-9]$|^20$|^2[1-9]$|^3[0-9]$|^4[0-9]$|^5[0-9]$|^6[0-9]$|^7[0-9]$|^8[0-9]$|^9[0-9]$|^1[0-9][0-9]$|^200$' } {
                $selectedFeature = [int]$_
                if (-not (Test-FeatureEnabled $selectedFeature)) {
                    Write-Warning "Feature $selectedFeature is disabled in configuration."
                } else {
                    Invoke-UtilityFeature $selectedFeature
                }
                Read-Host 'Press Enter'
            }
            default { Write-Host 'Invalid option'; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

if ($Test) { Invoke-SelfTest; exit 0 }
if ($Interactive) { Show-LauncherMenu; exit 0 }
Invoke-AppStartup
exit 0

