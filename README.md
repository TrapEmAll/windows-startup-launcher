# Windows Startup Launcher

A one-shot PowerShell startup launcher for the ChatGPT desktop app, Discord, and Xbox.

## Modes

Startup mode launches the configured apps once and exits. It does not monitor processes, attach to applications, or run a heartbeat.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File .\outputs\Open-ChatGPT-Discord-Xbox.ps1
```

Optional manual modes:

```powershell
.\outputs\Open-ChatGPT-Discord-Xbox.ps1 -Interactive
.\outputs\Open-ChatGPT-Discord-Xbox.ps1 -Test
.\outputs\Open-ChatGPT-Discord-Xbox.ps1 -DryRun
```

Place a shortcut using the first command in `shell:startup` for login launch.

## Testing

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Launcher.ps1
```

