[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Get-Digest {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($utf8.GetBytes($Text)))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Invoke-GitRead {
    param([string[]]$Arguments)
    $text = (& git -C $root -c core.safecrlf=false @Arguments 2>$null | Out-String).Replace("`r`n", "`n")
    if ($LASTEXITCODE -ne 0) { throw 'Automatic Git verification failed; inspect the project locally.' }
    return $text
}

function Get-WorkFingerprint {
    $insideGit = & git -C $root rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0) { return 'no-git' }
    # Hash changes without copying source, prompts, or tool output into the audit.
    $parts = [System.Collections.Generic.List[string]]::new()
    # HEAD may not exist yet in a freshly installed project.
    $head = & git -C $root rev-parse --verify HEAD 2>$null
    $parts.Add($(if ($LASTEXITCODE -eq 0) { [string]$head } else { 'unborn' }))
    $parts.Add((Invoke-GitRead -Arguments @('diff', '--no-ext-diff', '--binary')))
    $parts.Add((Invoke-GitRead -Arguments @('diff', '--cached', '--no-ext-diff', '--binary')))
    $untracked = Invoke-GitRead -Arguments @('ls-files', '--others', '--exclude-standard', '-z')
    foreach ($relative in ($untracked.TrimEnd("`n") -split "`0")) {
        if (-not $relative) { continue }
        if ($relative.Replace('\', '/').StartsWith('.codex/.gi-hook-state/')) { continue }
        $path = [System.IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $path.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Untracked file escaped the project root.' }
        $item = Get-Item -LiteralPath $path -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { $parts.Add($relative + ':link'); continue }
        $parts.Add($relative + ':' + (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash)
    }
    return Get-Digest ($parts -join "`n")
}

function Write-Audit {
    param([string]$Outcome, [bool]$ChecksPassed, [int]$ReviewCount)
    $entry = [ordered]@{
        time_utc = [DateTime]::UtcNow.ToString('o'); event = $eventName
        session = $sessionKey; turn = $turnId; outcome = $Outcome
        checks_passed = $ChecksPassed; review_count = $ReviewCount
    }
    [System.IO.File]::AppendAllText((Join-Path $stateRoot 'events.jsonl'), (($entry | ConvertTo-Json -Compress) + "`n"), $utf8)
}

try {
    $event = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $eventName = [string]$event.hook_event_name
    if ($eventName -notin @('UserPromptSubmit', 'SessionStart', 'Stop')) { throw 'Unsupported GI hook event.' }
    if ([string]::IsNullOrWhiteSpace([string]$event.session_id)) { throw 'Missing hook session identity.' }
    $cwd = [System.IO.Path]::GetFullPath([string]$event.cwd)
    if ($cwd -ne $root -and -not $cwd.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Hook cwd does not belong to this project.' }
    $turnProperty = $event.PSObject.Properties['turn_id']
    $turnId = if ($turnProperty) { [string]$turnProperty.Value } else { '' }
    $sessionKey = Get-Digest ([string]$event.session_id)
    $stateRoot = Join-Path $root '.codex/.gi-hook-state'
    [void][System.IO.Directory]::CreateDirectory($stateRoot)
    $receiptPath = Join-Path $stateRoot ($sessionKey + '.json')
    $phase = if ($eventName -eq 'Stop') { 'Complete' } else { 'Work' }
    $context = (& (Join-Path $root 'tools/get-gi-context.ps1') -Phase $phase -SkipUpdateCheck | Out-String).Replace("`r`n", "`n").TrimEnd()
    $budgets = [System.IO.File]::ReadAllText((Join-Path $root 'config/gi-context-budgets.json')) | ConvertFrom-Json
    if ($context.Length -gt [int]$budgets.section_max_chars) { throw 'Mandatory hook context exceeds the existing section cap.' }

    if ($eventName -ne 'Stop') {
        Write-Audit -Outcome 'rules_injected' -ChecksPassed $true -ReviewCount 0
        @{ hookSpecificOutput = @{ hookEventName = $eventName; additionalContext = $context } } | ConvertTo-Json -Depth 5 -Compress
        exit 0
    }

    $checksPassed = $true
    $insideGit = & git -C $root rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -eq 0) {
        & git -C $root -c core.safecrlf=false diff --check 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $checksPassed = $false }
        & git -C $root -c core.safecrlf=false diff --cached --check 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $checksPassed = $false }
    }
    $fingerprint = Get-Digest ($context + "`n" + (Get-WorkFingerprint))
    $receipt = if (Test-Path -LiteralPath $receiptPath) { [System.IO.File]::ReadAllText($receiptPath) | ConvertFrom-Json } else { $null }
    $continuedProperty = $event.PSObject.Properties['stop_hook_active']
    $continued = $continuedProperty -and $continuedProperty.Value -eq $true
    if ($continued -and $receipt -and $receipt.fingerprint -eq $fingerprint -and $checksPassed) {
        Write-Audit -Outcome 'completion_allowed' -ChecksPassed $true -ReviewCount ([int]$receipt.review_count)
        '{}'
        exit 0
    }
    $reviewCount = if ($continued -and $receipt) { [int]$receipt.review_count + 1 } else { 1 }
    if ($reviewCount -gt 3) {
        Write-Audit -Outcome 'completion_stopped' -ChecksPassed $checksPassed -ReviewCount $reviewCount
        @{ continue = $false; stopReason = 'GI automatic completion verification did not settle; task remains unverified.'; systemMessage = 'GI: completion verification stopped after repeated changes or failed checks. Do not treat this as verified completion.' } | ConvertTo-Json -Compress
        exit 0
    }
    @{ fingerprint = $fingerprint; review_count = $reviewCount; turn = $turnId } | ConvertTo-Json -Compress |
        ForEach-Object { [System.IO.File]::WriteAllText($receiptPath, $_, $utf8) }
    Write-Audit -Outcome 'completion_review_required' -ChecksPassed $checksPassed -ReviewCount $reviewCount
    $checkMessage = if ($checksPassed) { 'Automatic whitespace checks passed.' } else { 'Automatic whitespace checks failed. Inspect git diff --check and git diff --cached --check; fix only authorized task changes or report the blocker.' }
    $reason = "[GI automatic final review]`n$context`n`n$checkMessage Review the actual result against the entire request now. No manual Complete call is needed. Report any unfinished or unverified requirement. Preserve unrelated work."
    if ($reason.Length -gt [int]$budgets.section_max_chars) { throw 'Automatic review exceeds the existing section cap.' }
    @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress
} catch {
    # Hook failures must be visible; never print a successful completion receipt.
    @{ continue = $false; stopReason = 'GI mandatory lifecycle verification failed.'; systemMessage = 'GI hook failed: mandatory context or local verification is unavailable. Task completion remains unverified.' } | ConvertTo-Json -Compress
    exit 0
}
