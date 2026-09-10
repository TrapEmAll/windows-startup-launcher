# Windows Startup Launcher

A one-shot PowerShell startup routine for apps, Windows tools, folders, diagnostics, and optional utilities.

## Modes

Startup mode launches the configured apps once and exits. It does not monitor processes, attach to applications, or run a heartbeat.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File .\outputs\Windows-Startup-Routine.ps1
```

Optional manual modes:

```powershell
.\outputs\Windows-Startup-Routine.ps1 -Interactive
.\outputs\Windows-Startup-Routine.ps1 -Test
.\outputs\Windows-Startup-Routine.ps1 -DryRun
```

Place a shortcut using the first command in `shell:startup` for login launch.

## Testing

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Launcher.ps1
```

