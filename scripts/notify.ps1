# claude-notify hook entry point (Stop / Notification).
# User settings live in %USERPROFILE%\.claude\claude-notify\ so they survive plugin updates.
try {
    $event = 'Stop'; $project = ''; $hookMessage = ''; $cwd = ''; $transcript = ''
    try {
        $data = [Console]::In.ReadToEnd() | ConvertFrom-Json
        if ($data.hook_event_name) { $event = $data.hook_event_name }
        if ($data.cwd) { $cwd = $data.cwd; $project = Split-Path -Leaf $data.cwd }
        if ($data.transcript_path) { $transcript = $data.transcript_path }
        if ($data.message) { $hookMessage = $data.message }
    } catch {}

    $defaults = @{
        Stop         = @{ message = '답변이 완료되었습니다'; sound = 'C:\Windows\Media\tada.wav' }
        Notification = @{ message = 'Claude가 확인을 기다립니다'; sound = 'C:\Windows\Media\chimes.wav' }
    }
    if (-not $defaults.ContainsKey($event)) { $event = 'Stop' }

    # First run: create the user folder with an editable config and an empty sounds folder.
    $userDir = Join-Path $env:USERPROFILE '.claude\claude-notify'
    $configPath = Join-Path $userDir 'config.json'
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Force (Join-Path $userDir 'sounds') | Out-Null
        Copy-Item (Join-Path $PSScriptRoot 'config.template.json') $configPath
    }

    $message = $defaults[$event].message
    $sound = ''
    $showFiles = $true; $checkSecurity = $true
    try {
        $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $entry = $config.$event
        if ($entry.message) { $message = $entry.message }
        if ($entry.sound) { $sound = $entry.sound }
        if ($null -ne $config.Review.changedFiles) { $showFiles = [bool]$config.Review.changedFiles }
        if ($null -ne $config.Review.security) { $checkSecurity = [bool]$config.Review.security }
    } catch {}

    # A sound is either a link (downloaded and cached by notify-popup.ps1) or a file path.
    # Relative paths are resolved against the user folder; a missing file falls back to the default.
    if ($sound -notmatch '^https?://') {
        if ($sound -and -not [IO.Path]::IsPathRooted($sound)) { $sound = Join-Path $userDir $sound }
        if (-not $sound -or -not (Test-Path -LiteralPath $sound)) { $sound = $defaults[$event].sound }
    }

    $detail = @()
    if ($hookMessage -and $event -ne 'Stop') { $detail += $hookMessage }
    if ($project) { $detail += $project }

    # Hand off to a detached process so the hook returns immediately instead of blocking
    # Claude until the popup is closed. Base64 avoids command-line quoting issues.
    $payload = @{
        event = $event; message = $message; detail = ($detail -join "`n")
        sound = $sound; fallback = $defaults[$event].sound; cache = (Join-Path $userDir 'cache')
        # Only the Stop card shows what changed; the popup process does the (slower) analysis.
        review = ($event -eq 'Stop' -and ($showFiles -or $checkSecurity))
        transcript = $transcript; cwd = $cwd; showFiles = $showFiles; checkSecurity = $checkSecurity
    } | ConvertTo-Json -Compress
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))

    # Keep only one popup on screen: close any earlier one before showing the new one.
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%notify-popup.ps1%'" |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSScriptRoot\notify-popup.ps1`"", $b64
} catch {}
exit 0
