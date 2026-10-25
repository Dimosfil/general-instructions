[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('gi-hooks-' + [guid]::NewGuid().ToString('N'))
$utf8 = [System.Text.UTF8Encoding]::new($false)
$shell = (Get-Process -Id $PID).Path

function Invoke-Hook {
    param([hashtable]$Event, [string]$Raw)
    $start = [System.Diagnostics.ProcessStartInfo]::new($shell)
    foreach ($arg in @('-NoProfile', '-NonInteractive', '-File', (Join-Path $testRoot 'tools/invoke-gi-lifecycle-hook.ps1'))) { $start.ArgumentList.Add($arg) }
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardInputEncoding = $utf8
    $start.StandardOutputEncoding = $utf8
    $start.StandardErrorEncoding = $utf8
    $process = [System.Diagnostics.Process]::Start($start)
    try {
        $inputText = if ($Raw) { $Raw } else { $Event | ConvertTo-Json -Depth 8 -Compress }
        $process.StandardInput.WriteLine($inputText)
        $process.StandardInput.Close()
        $output = $process.StandardOutput.ReadToEndAsync()
        $errors = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) { $process.Kill($true); throw 'Hook test timed out.' }
        if ($process.ExitCode -ne 0 -or $errors.Result) { throw ('Hook process failed: ' + $errors.Result) }
        return $output.Result | ConvertFrom-Json
    } finally { $process.Dispose() }
}

function Assert-True { param([bool]$Condition, [string]$Message); if (-not $Condition) { throw $Message } }

try {
    foreach ($directory in @('tools', 'config', 'patterns/AGENTS_RUNTIME', '.codex')) { [void][System.IO.Directory]::CreateDirectory((Join-Path $testRoot $directory)) }
    foreach ($relative in @('tools/get-gi-context.ps1', 'tools/invoke-gi-lifecycle-hook.ps1', 'config/gi-context-budgets.json', 'patterns/AGENTS_RUNTIME/03-rule-precedence.md')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination (Join-Path $testRoot $relative)
    }
    [System.IO.File]::WriteAllText((Join-Path $testRoot '.gitignore'), ".codex/.gi-hook-state/`n", $utf8)
    & git -C $testRoot init --quiet
    $rules = [System.IO.File]::ReadAllText((Join-Path $testRoot 'patterns/AGENTS_RUNTIME/03-rule-precedence.md')).Replace("`r`n", "`n").TrimEnd()
    $event = @{ session_id = 'native-test'; turn_id = 'turn-1'; cwd = $testRoot; hook_event_name = 'UserPromptSubmit' }
    foreach ($toolName in @('create_thread','send_message_to_thread','mcp__codex_app__create_thread','codex_app.send_message_to_thread')) {
        $service = @{ session_id='native-test'; turn_id='service-turn'; cwd=$testRoot; hook_event_name='PreToolUse'; tool_name=$toolName
            tool_input=@{prompt="Original task — сохранить дословно.`r`nSecond line"; threadId='unchanged-target'; hostId='local'; target=@{projectId='unchanged-project';environment=@{type='local'}}} }
        $result = Invoke-Hook $service
        $updated = $result.hookSpecificOutput.updatedInput
        Assert-True ($result.hookSpecificOutput.permissionDecision -eq 'allow' -and $updated.prompt.Contains($rules)) 'Service call did not automatically receive mandatory rules.'
        Assert-True (-not $updated.prompt.Contains('TASK COMPLETION REVIEW') -and -not $updated.prompt.Contains('GI UPDATE STATUS')) 'Service forwarding leaked sender project preferences.'
        Assert-True ($updated.prompt.EndsWith($service.tool_input.prompt) -and $updated.threadId -eq 'unchanged-target' -and $updated.target.projectId -eq 'unchanged-project') 'Service hook changed task text or destination.'
        $service.tool_input.prompt = $updated.prompt
        $repeated = Invoke-Hook $service
        Assert-True ($repeated.hookSpecificOutput.updatedInput.prompt -ceq $updated.prompt) 'Service forwarding duplicated an identical mandatory block.'
    }
    $service.tool_name = 'mcp__other__create_thread'
    $result = Invoke-Hook $service
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Service hook intercepted an unrelated tool.'
    $result = Invoke-Hook $event
    Assert-True ($result.hookSpecificOutput.additionalContext.Contains($rules)) 'UserPromptSubmit did not inject the actual mandatory rules.'
    Assert-True ($result.hookSpecificOutput.additionalContext.Contains('sending one final response') -and $result.hookSpecificOutput.additionalContext.Contains('without raw HTML tags')) 'Pre-response review/format rules are missing from actual hook context.'
    $event.hook_event_name = 'SessionStart'; $event.source = 'compact'
    $result = Invoke-Hook $event
    Assert-True ($result.hookSpecificOutput.additionalContext.Contains($rules)) 'Compaction did not restore mandatory rules.'
    $event.hook_event_name = 'Stop'; $event.stop_hook_active = $false
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Successful completion created a visible continuation without manual Complete.'
    $event.stop_hook_active = $true
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Unchanged reviewed result was not allowed.'
    [System.IO.File]::WriteAllText((Join-Path $testRoot 'new-file.txt'), 'changed after review', $utf8)
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Passing changed work created a routine second answer.'
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Stable second review did not finish.'
    $rulesPath = Join-Path $testRoot 'patterns/AGENTS_RUNTIME/03-rule-precedence.md'
    [System.IO.File]::AppendAllText($rulesPath, "`n- Additional fixture rule.`n", $utf8)
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Valid changed rules created a routine second answer.'
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Stable policy review did not finish.'
    $event.turn_id = 'turn-2'; $event.stop_hook_active = $false
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Another successful user turn created a visible continuation.'
    [System.IO.File]::WriteAllText((Join-Path $testRoot 'bad.txt'), "bad whitespace  `n", $utf8)
    & git -C $testRoot add -- bad.txt
    $event.stop_hook_active = $true
    $result = Invoke-Hook $event
    Assert-True ($result.decision -eq 'block' -and $result.reason.Contains('checks failed')) 'A failing automatic check was accepted.'
    Assert-True ($result.reason.Length -lt 700 -and -not $result.reason.Contains('MANDATORY TASK RULES')) 'Failure message repeated full policy.'
    # A fixed failure finishes silently and clears retries; a later failure
    # in a new turn gets its own full bounded repair opportunity.
    [System.IO.File]::WriteAllText((Join-Path $testRoot 'bad.txt'), "fixed whitespace`n", $utf8)
    & git -C $testRoot add -- bad.txt
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Repaired whitespace still requested a second final.'
    $event.turn_id = 'turn-3'; $event.stop_hook_active = $false
    [System.IO.File]::WriteAllText((Join-Path $testRoot 'bad.txt'), "bad whitespace  `n", $utf8)
    $result = Invoke-Hook $event
    Assert-True ($result.decision -eq 'block') 'Unstaged whitespace failure was accepted.'
    $event.stop_hook_active = $true
    $null = Invoke-Hook $event
    $null = Invoke-Hook $event
    $result = Invoke-Hook $event
    Assert-True ($result.continue -eq $false -and $result.stopReason.Contains('unverified')) 'Repeated failure did not stop visibly and finitely.'
    $result = Invoke-Hook -Raw '{malformed private input'
    Assert-True ($result.continue -eq $false -and -not (($result | ConvertTo-Json).Contains('private input'))) 'Invalid input leaked data or looked successful.'
    Remove-Item -LiteralPath (Join-Path $testRoot 'tools/get-gi-context.ps1')
    $service.tool_name = 'send_message_to_thread'
    $result = Invoke-Hook $service
    Assert-True ($result.hookSpecificOutput.permissionDecision -eq 'deny') 'Unavailable rules did not deny service forwarding.'
    $result = Invoke-Hook $event
    Assert-True ($result.continue -eq $false) 'Missing mandatory loader was accepted.'
    $audit = Get-Content -LiteralPath (Join-Path $testRoot '.codex/.gi-hook-state/events.jsonl') | ForEach-Object { $_ | ConvertFrom-Json }
    Assert-True (@($audit | Where-Object outcome -eq 'completion_check_failed').Count -gt 0) 'Failure audit is missing.'
    Assert-True (@($audit | Where-Object outcome -eq 'completion_allowed').Count -gt 0) 'Successful automatic review audit is missing.'
    Assert-True (@($audit | Where-Object { $_.outcome -eq 'service_rules_forwarded' -and $_.delivery -eq 'added' }).Count -eq 4) 'Automatic service additions are not independently recorded.'
    Assert-True (@($audit | Where-Object { $_.outcome -eq 'service_rules_forwarded' -and $_.delivery -eq 'reused' }).Count -eq 4) 'Idempotent service forwarding is not recorded.'
    Assert-True (-not ((Get-Content -LiteralPath (Join-Path $testRoot '.codex/.gi-hook-state/events.jsonl') -Raw).Contains('Original task'))) 'Service audit saved private prompt text.'
    'GI lifecycle hook checks passed: service delivery, pre-response rules, quiet successful Stop, changed work/rules, staged/unstaged failure, repair, bounded retries, and privacy.'
} finally {
    $resolved = [System.IO.Path]::GetFullPath($testRoot)
    $allowed = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase) -or [System.IO.Path]::GetFileName($resolved) -notlike 'gi-hooks-*') { throw 'Unsafe hook test cleanup target.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
