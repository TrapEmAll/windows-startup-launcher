$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..\outputs\Open-ChatGPT-Discord-Xbox.ps1'
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $scriptPath), [ref]$null, [ref]$errors) | Out-Null
if ($errors) { throw ($errors | ForEach-Object Message | Out-String) }
$content = Get-Content -LiteralPath $scriptPath -Raw
foreach ($required in @('$Interactive','$Test','$DryRun','$NoApps','Start-InstalledApp','Start-ProtocolApp','exit 0')) {
    if ($content -notmatch [regex]::Escape($required)) { throw "Missing required capability: $required" }
}
foreach ($feature in 11..20) {
    if ($content -notmatch "\b$feature\s*=") { throw "Missing feature $feature" }
}
foreach ($feature in 21..30) {
    if ($content -notmatch "\b$feature\s*=") { throw "Missing feature $feature" }
}
foreach ($feature in 31..40) {
    if ($content -notmatch "\b$feature\s*=") { throw "Missing feature $feature" }
}
foreach ($feature in 41..50) {
    if ($content -notmatch "\b$feature\s*[{=]") { throw "Missing feature $feature" }
}
Write-Host 'Launcher tests passed.'

