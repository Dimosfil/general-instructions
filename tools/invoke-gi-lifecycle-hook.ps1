[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8

function Get-Digest {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($utf8.GetBytes($Text)))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Invoke-HookGit {
    param([string[]]$Arguments, [string]$InputText)
    $gitPath = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    if ($IsWindows -and $gitPath -notmatch '[\\/](mingw64|mingw32|clangarm64)[\\/]bin[\\/]git\.exe$') {
        $gitRoot = Split-Path -Parent (Split-Path -Parent $gitPath)
        $gitPath = @('mingw64', 'mingw32', 'clangarm64') |
            ForEach-Object { Join-Path $gitRoot "$_/bin/git.exe" } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1
        if (-not $gitPath) { throw 'Windowless Git executable not found for automatic verification.' }
    }
    $start = [System.Diagnostics.ProcessStartInfo]::new($gitPath)
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = $utf8
    $start.StandardInputEncoding = $utf8
    foreach ($argument in @('-C', $root, '--no-pager', '-c', 'core.safecrlf=false', '-c', 'core.fsmonitor=false') + $Arguments) {
        $start.ArgumentList.Add($argument)
    }
    $process = [System.Diagnostics.Process]::Start($start)
    try {
        $output = $process.StandardOutput.ReadToEndAsync()
        $errors = $process.StandardError.ReadToEndAsync()
        if ($InputText) { $process.StandardInput.Write($InputText) }
        $process.StandardInput.Close()
        $process.WaitForExit()
        $null = $errors.GetAwaiter().GetResult()
        return @{ ExitCode = $process.ExitCode; Output = $output.GetAwaiter().GetResult() }
    } finally { $process.Dispose() }
}

function Assert-WindowlessDiff {
    $filters = Invoke-HookGit @('config', '--get-regexp', '^filter\..*\.(clean|process)$')
    if ($filters.ExitCode -eq 1) { return }
    if ($filters.ExitCode -ne 0) { throw 'Could not verify Git filter configuration.' }
    $tracked = Invoke-HookGit @('ls-files', '-z')
    if ($tracked.ExitCode -ne 0) { throw 'Could not verify Git attributes for tracked files.' }
    if (-not $tracked.Output) { return }
    $attributes = Invoke-HookGit -Arguments @('check-attr', '-z', '--stdin', 'filter') -InputText $tracked.Output
    if ($attributes.ExitCode -ne 0) { throw 'Could not verify Git filter attributes.' }
    $fields = $attributes.Output -split "`0"
    for ($index = 2; $index -lt $fields.Count; $index += 3) {
        $filter = [regex]::Escape($fields[$index])
        if ($filters.Output -match "(?m)^filter\.$filter\.(clean|process) +\S") {
            throw [System.NotSupportedException]::new('An external Git clean or process filter applies to tracked files and has no verified windowless launch path.')
        }
    }
}

function Invoke-GitRead {
    param([string[]]$Arguments)
    $result = Invoke-HookGit $Arguments
    if ($result.ExitCode -ne 0) { throw 'Automatic Git verification failed; inspect the project locally.' }
    return $result.Output.Replace("`r`n", "`n")
}

function Get-WorkFingerprint {
    param([bool]$InsideGit)
    if (-not $InsideGit) { return 'no-git' }
    # Hash changes without copying source, prompts, or tool output into the audit.
    $parts = [System.Collections.Generic.List[string]]::new()
    # HEAD may not exist yet in a freshly installed project.
    $head = Invoke-HookGit @('rev-parse', '--verify', 'HEAD')
    $parts.Add($(if ($head.ExitCode -eq 0) { $head.Output.TrimEnd() } else { 'unborn' }))
    $parts.Add((Invoke-GitRead -Arguments @('diff', '--ignore-submodules=dirty', '--no-ext-diff', '--no-textconv', '--binary')))
    $parts.Add((Invoke-GitRead -Arguments @('diff', '--cached', '--ignore-submodules=dirty', '--no-ext-diff', '--no-textconv', '--binary')))
    $untracked = Invoke-GitRead -Arguments @('ls-files', '--others', '--exclude-standard', '-z')
    foreach ($relative in ($untracked.TrimEnd("`n") -split "`0")) {
        if (-not $relative) { continue }
        if ($relative.Replace('\', '/') -match '^\.(codex|opencode)/\.gi-hook-state/') { continue }
        $path = [System.IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $path.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Untracked file escaped the project root.' }
        $item = Get-Item -LiteralPath $path -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { $parts.Add($relative + ':link'); continue }
        $parts.Add($relative + ':' + (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash)
    }
    return Get-Digest ($parts -join "`n")
}

function Write-Audit {
    param([string]$Outcome, [bool]$ChecksPassed, [int]$ReviewCount, [string]$ServiceTool = '', [string]$Delivery = '')
    $entry = [ordered]@{
        time_utc = [DateTime]::UtcNow.ToString('o'); event = $eventName
        session = $sessionKey; turn = $turnId; outcome = $Outcome
        checks_passed = $ChecksPassed; review_count = $ReviewCount
    }
    if ($ServiceTool) { $entry['service_tool'] = $ServiceTool; $entry['delivery'] = $Delivery }
    [System.IO.File]::AppendAllText((Join-Path $stateRoot 'events.jsonl'), (($entry | ConvertTo-Json -Compress) + "`n"), $utf8)
}

try {
    $event = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $hostProperty = $event.PSObject.Properties['host']
    $hookHost = if ($hostProperty) { [string]$hostProperty.Value } else { 'codex' }
    if ($hookHost -notin @('codex', 'opencode')) { throw 'Unsupported GI hook host.' }
    $eventName = [string]$event.hook_event_name
    if ($eventName -notin @('UserPromptSubmit', 'SessionStart', 'PreToolUse', 'Stop')) { throw 'Unsupported GI hook event.' }
    if ($eventName -eq 'PreToolUse') {
        $isServiceTool = [string]$event.tool_name -match '^(?:mcp__codex_app__|codex_app[./])?(?:create_thread|send_message_to_thread)$'
        if ($hookHost -eq 'opencode') { $isServiceTool = [string]$event.tool_name -eq 'task' }
        if (-not $isServiceTool) { '{}'; exit 0 }
    }
    if ([string]::IsNullOrWhiteSpace([string]$event.session_id)) { throw 'Missing hook session identity.' }
    $cwd = [System.IO.Path]::GetFullPath([string]$event.cwd)
    if ($cwd -ne $root -and -not $cwd.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Hook cwd does not belong to this project.' }
    $turnProperty = $event.PSObject.Properties['turn_id']
    $turnId = if ($turnProperty) { [string]$turnProperty.Value } else { '' }
    $sessionKey = Get-Digest ([string]$event.session_id)
    $stateRoot = Join-Path $root ('.' + $hookHost + '/.gi-hook-state')
    [void][System.IO.Directory]::CreateDirectory($stateRoot)
    $receiptPath = Join-Path $stateRoot ($sessionKey + '.json')
    $phase = if ($eventName -eq 'Stop') { 'Complete' } else { 'Work' }
    $context = (& (Join-Path $root 'tools/get-gi-context.ps1') -Phase $phase -MandatoryOnly:($eventName -eq 'PreToolUse') -SkipUpdateCheck | Out-String).Replace("`r`n", "`n").TrimEnd()
    $budgets = [System.IO.File]::ReadAllText((Join-Path $root 'config/gi-context-budgets.json')) | ConvertFrom-Json
    if ($context.Length -gt [int]$budgets.section_max_chars) { throw 'Mandatory hook context exceeds the existing section cap.' }

    if ($eventName -eq 'PreToolUse') {
        $inputObject = $event.tool_input
        if ($inputObject.prompt -isnot [string] -or [string]::IsNullOrWhiteSpace($inputObject.prompt)) { throw 'Service message requires a nonempty prompt.' }
        # Preserve the original task and every routing/authorization field.
        # Only an identical generated prefix is reused; never strip user text.
        $prefix = "[GI automatic service context]`n$context`n[End GI automatic service context]`n`n"
        if ($prefix.Length -gt [int]$budgets.section_max_chars) { throw 'Service context exceeds the existing section cap.' }
        $delivery = if ($inputObject.prompt.StartsWith($prefix, [StringComparison]::Ordinal)) { 'reused' } else { 'added' }
        if ($delivery -eq 'added') { $inputObject.prompt = $prefix + $inputObject.prompt }
        Write-Audit -Outcome 'service_rules_forwarded' -ChecksPassed $true -ReviewCount 0 -ServiceTool ([string]$event.tool_name) -Delivery $delivery
        @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'allow'; updatedInput = $inputObject } } | ConvertTo-Json -Depth 100 -Compress
        exit 0
    }

    if ($eventName -ne 'Stop') {
        Write-Audit -Outcome 'rules_injected' -ChecksPassed $true -ReviewCount 0
        @{ hookSpecificOutput = @{ hookEventName = $eventName; additionalContext = $context } } | ConvertTo-Json -Depth 5 -Compress
        exit 0
    }

    $checksPassed = $true
    $insideGit = $false
    if (Test-Path -LiteralPath (Join-Path $root '.git')) {
        $worktree = Invoke-HookGit @('rev-parse', '--is-inside-work-tree')
        if ($worktree.ExitCode -ne 0 -or $worktree.Output.Trim() -ne 'true') { throw 'Automatic Git verification could not resolve the project worktree.' }
        $insideGit = $true
        if ($IsWindows) { Assert-WindowlessDiff }
        $unstaged = Invoke-HookGit @('diff', '--ignore-submodules=dirty', '--no-ext-diff', '--no-textconv', '--check')
        $staged = Invoke-HookGit @('diff', '--cached', '--ignore-submodules=dirty', '--no-ext-diff', '--no-textconv', '--check')
        $checksPassed = $unstaged.ExitCode -eq 0 -and $staged.ExitCode -eq 0
    }
    # A successful Stop must not create a synthetic user prompt and duplicate
    # the already streamed final answer. Work rules require review before it.
    # The audit records automated checks, not proof of semantic review.
    $fingerprint = Get-Digest ($context + "`n" + (Get-WorkFingerprint $insideGit))
    $receipt = if (Test-Path -LiteralPath $receiptPath) { [System.IO.File]::ReadAllText($receiptPath) | ConvertFrom-Json } else { $null }
    $continuedProperty = $event.PSObject.Properties['stop_hook_active']
    $continued = $continuedProperty -and $continuedProperty.Value -eq $true
    if ($checksPassed) {
        if (Test-Path -LiteralPath $receiptPath) { Remove-Item -LiteralPath $receiptPath }
        Write-Audit -Outcome 'completion_allowed' -ChecksPassed $true -ReviewCount 0
        '{}'
        exit 0
    }
    $reviewCount = if ($continued -and $receipt -and $receipt.turn -eq $turnId) { [int]$receipt.review_count + 1 } else { 1 }
    if ($reviewCount -gt 3) {
        Write-Audit -Outcome 'completion_stopped' -ChecksPassed $checksPassed -ReviewCount $reviewCount
        @{ continue = $false; stopReason = 'GI automatic completion verification did not settle; task remains unverified.'; systemMessage = 'GI: completion verification stopped after repeated failed checks. Do not treat this as verified completion.' } | ConvertTo-Json -Compress
        exit 0
    }
    @{ fingerprint = $fingerprint; review_count = $reviewCount; turn = $turnId } | ConvertTo-Json -Compress |
        ForEach-Object { [System.IO.File]::WriteAllText($receiptPath, $_, $utf8) }
    Write-Audit -Outcome 'completion_check_failed' -ChecksPassed $false -ReviewCount $reviewCount
    # Only a real failure warrants the host's visible continuation protocol.
    $reason = '[GI completion check failed] Automatic whitespace checks failed. Inspect git diff --check and git diff --cached --check; fix only authorized task changes or report the blocker. Preserve unrelated work. Return only a necessary correction; do not repeat an unchanged final answer.'
    if ($reason.Length -gt [int]$budgets.section_max_chars) { throw 'Completion correction exceeds the existing section cap.' }
    @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress
} catch {
    if ((Get-Variable -Name eventName -ErrorAction SilentlyContinue) -and $eventName -eq 'PreToolUse') {
        # PreToolUse does not support continue:false; explicitly deny forwarding.
        @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = 'GI mandatory service context is unavailable; message was not forwarded.' } } | ConvertTo-Json -Compress
        exit 0
    }
    # Hook failures must be visible; never print a successful completion receipt.
    $message = 'GI hook failed: mandatory context or local verification is unavailable. Task completion remains unverified.'
    if ($_.Exception -is [System.NotSupportedException] -and $eventName -eq 'Stop') {
        $message = 'GI hook blocked Windows Git verification. ' + $_.Exception.Message
    }
    @{ continue = $false; stopReason = 'GI mandatory lifecycle verification failed.'; systemMessage = $message } | ConvertTo-Json -Compress
    exit 0
}
