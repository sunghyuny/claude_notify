# Builds the "what changed / what to check" summary shown on the Stop card.
# Dot-sourced by notify-popup.ps1; every function returns an empty result on failure.

# Files Claude created or edited since the last prompt the person typed, in edit order.
function Get-ChangedFiles([string]$transcript) {
    $found = [ordered]@{}
    if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) { return @() }
    $lines = [IO.File]::ReadAllLines($transcript)
    for ($i = $lines.Length - 1; $i -ge 0; $i--) {
        $l = $lines[$i]
        if ($l -match '"type":"user"') {
            if ($l -match '"tool_result"') { continue }
            try { if (-not ($l | ConvertFrom-Json).isMeta) { break } } catch {}
            continue
        }
        if ($l -notmatch '"type":"tool_use"') { continue }
        try { $entry = $l | ConvertFrom-Json } catch { continue }
        $uses = @($entry.message.content | Where-Object { $_.type -eq 'tool_use' })
        [array]::Reverse($uses)
        foreach ($c in $uses) {
            if ($c.name -notin 'Edit', 'Write', 'MultiEdit', 'NotebookEdit') { continue }
            $p = if ($c.input.file_path) { $c.input.file_path } else { $c.input.notebook_path }
            if ($p -and -not $found.Contains($p)) { $found[$p] = $c.name }
        }
    }
    $paths = @($found.Keys); [array]::Reverse($paths)
    foreach ($p in $paths) { [pscustomobject]@{ Path = $p; Tool = $found[$p] } }
}

# API keys, tokens and passwords written straight into the changed files.
function Find-Secrets($files) {
    $patterns = [ordered]@{
        'Anthropic/OpenAI 키'  = 'sk-(ant-)?[A-Za-z0-9_\-]{20,}'
        'AWS 키'               = 'AKIA[0-9A-Z]{16}'
        'GitHub 토큰'          = '(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,})'
        'Google API 키'        = 'AIza[0-9A-Za-z_\-]{35}'
        'Slack 토큰'           = 'xox[abprs]-[A-Za-z0-9\-]{10,}'
        '개인 키'              = '-----BEGIN [A-Z ]*PRIVATE KEY-----'
        '비밀번호/키 값'       = '(?i)(api[_\-]?key|secret|password|passwd|pwd|token|access[_\-]?key)["'']?\s*[:=]\s*["''][^"''\s]{8,}["'']'
    }
    $placeholder = '(?i)(your|example|xxxx|changeme|placeholder|dummy|sample|<[^>]+>|\$\{|process\.env|os\.environ|getenv|\*{4})'
    foreach ($f in $files) {
        $path = $f.Path
        if ((Split-Path -Leaf $path) -match '^\.env') { continue }   # secrets belong in .env; checked separately
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        if ((Get-Item -LiteralPath $path).Length -gt 1MB) { continue }
        $n = 0
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            $n++
            if ($line.Contains([char]0)) { break }
            foreach ($kind in $patterns.Keys) {
                $m = [regex]::Match($line, $patterns[$kind])
                if ($m.Success -and $m.Value -notmatch $placeholder) {
                    [pscustomobject]@{ Path = $path; Line = $n; Kind = $kind }
                    break
                }
            }
        }
    }
}

# .env, key and credential files that are not ignored by git or are already tracked.
function Find-ExposedFiles([string]$cwd) {
    if (-not $cwd -or -not (Get-Command git -ErrorAction SilentlyContinue)) { return }
    $root = git -C $cwd rev-parse --show-toplevel 2>$null
    if (-not $root) { return }
    $sensitive = '(^|/)(\.env(\.[^/]+)?|[^/]+\.(pem|key|p12|pfx)|id_rsa|id_ed25519|credentials\.json|service-account[^/]*\.json)$'
    $template = '\.env\.(example|sample|template|dist)$'
    foreach ($f in @(git -C $root ls-files --others --exclude-standard 2>$null)) {
        if ($f -match $sensitive -and $f -notmatch $template) { [pscustomobject]@{ Path = $f; Problem = 'NotIgnored' } }
    }
    foreach ($f in @(git -C $root ls-files 2>$null)) {
        if ($f -match $sensitive -and $f -notmatch $template) { [pscustomobject]@{ Path = $f; Problem = 'Tracked' } }
    }
}

# Everything the card needs: changed files with a mark, and warnings as (text, hint) pairs.
function Get-Review([string]$transcript, [string]$cwd, [bool]$showFiles, [bool]$checkSecurity) {
    $changed = @(Get-ChangedFiles $transcript)
    $untracked = @()
    if ($cwd -and (Get-Command git -ErrorAction SilentlyContinue)) {
        $root = git -C $cwd rev-parse --show-toplevel 2>$null
        if ($root) {
            $untracked = @(git -C $root ls-files --others --exclude-standard 2>$null |
                ForEach-Object { [IO.Path]::GetFullPath((Join-Path $root $_)) })
        }
    }

    $short = { param($p) if ($cwd -and $p.StartsWith("$cwd\", 'OrdinalIgnoreCase')) { $p.Substring($cwd.Length + 1) } else { $p } }

    $files = @()
    if ($showFiles) {
        foreach ($f in $changed) {
            $full = [IO.Path]::GetFullPath($f.Path)
            $added = if ($untracked.Count) { $untracked -contains $full } else { $f.Tool -eq 'Write' }
            $files += [pscustomobject]@{ Mark = $(if ($added) { '+' } else { '~' }); Path = (& $short $f.Path) }
        }
    }

    $warnings = @()
    if ($checkSecurity) {
        foreach ($s in @(Find-Secrets $changed)) {
            $warnings += [pscustomobject]@{
                Text = "$(& $short $s.Path):$($s.Line)  $($s.Kind)"
                Hint = '코드에 직접 들어 있습니다. .env로 옮기고 환경 변수로 읽으세요'
            }
        }
        foreach ($e in @(Find-ExposedFiles $cwd)) {
            $warnings += if ($e.Problem -eq 'Tracked') {
                [pscustomobject]@{ Text = "$($e.Path)  이미 git에 포함됨"; Hint = "git rm --cached $($e.Path) 후 .gitignore에 추가하세요" }
            } else {
                [pscustomobject]@{ Text = "$($e.Path)  .gitignore에 없음"; Hint = '깃헙에 올라갈 수 있습니다. .gitignore에 추가하세요' }
            }
        }
    }
    [pscustomobject]@{ Files = $files; Warnings = $warnings }
}
