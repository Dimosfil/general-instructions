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
    $result = Invoke-Hook $event
    Assert-True ($result.hookSpecificOutput.additionalContext.Contains($rules)) 'UserPromptSubmit did not inject the actual mandatory rules.'
    $event.hook_event_name = 'SessionStart'; $event.source = 'compact'
    $result = Invoke-Hook $event
    Assert-True ($result.hookSpecificOutput.additionalContext.Contains($rules)) 'Compaction did not restore mandatory rules.'
    $event.hook_event_name = 'Stop'; $event.stop_hook_active = $false
    $result = Invoke-Hook $event
    Assert-True ($result.decision -eq 'block' -and $result.reason.Contains($rules)) 'Skipping Complete did not force automatic review.'
    $event.stop_hook_active = $true
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Unchanged reviewed result was not allowed.'
    [System.IO.File]::WriteAllText((Join-Path $testRoot 'new-file.txt'), 'changed after review', $utf8)
    $result = Invoke-Hook $event
    Assert-True ($result.decision -eq 'block') 'Changes after review reused a stale receipt.'
    $result = Invoke-Hook $event
    Assert-True (@($result.PSObject.Properties).Count -eq 0) 'Stable second review did not finish.'
    $event.turn_id = 'turn-2'; $event.stop_hook_active = $false
    $result = Invoke-Hook $event
    Assert-True ($result.decision -eq 'block') 'Another user turn reused a previous completion receipt.'
    [System.IO.File]::WriteAllText((Join-Path $testRoot 'bad.txt'), "bad whitespace  `n", $utf8)
    & git -C $testRoot add -- bad.txt
    $event.stop_hook_active = $true
    $result = Invoke-Hook $event
    Assert-True ($result.decision -eq 'block' -and $result.reason.Contains('checks failed')) 'A failing automatic check was accepted.'
    $null = Invoke-Hook $event
    $result = Invoke-Hook $event
    Assert-True ($result.continue -eq $false -and $result.stopReason.Contains('unverified')) 'Repeated failure did not stop visibly and finitely.'
    $result = Invoke-Hook -Raw '{malformed private input'
    Assert-True ($result.continue -eq $false -and -not (($result | ConvertTo-Json).Contains('private input'))) 'Invalid input leaked data or looked successful.'
    Remove-Item -LiteralPath (Join-Path $testRoot 'tools/get-gi-context.ps1')
    $result = Invoke-Hook $event
    Assert-True ($result.continue -eq $false) 'Missing mandatory loader was accepted.'
    $audit = Get-Content -LiteralPath (Join-Path $testRoot '.codex/.gi-hook-state/events.jsonl') | ForEach-Object { $_ | ConvertFrom-Json }
    Assert-True (@($audit | Where-Object outcome -eq 'completion_review_required').Count -gt 0) 'Review audit is missing.'
    Assert-True (@($audit | Where-Object outcome -eq 'completion_allowed').Count -gt 0) 'Successful automatic review audit is missing.'
    'GI lifecycle hook checks passed: automatic injection, omitted Complete, stale receipts, failures, bounded retries, and privacy.'
} finally {
    $resolved = [System.IO.Path]::GetFullPath($testRoot)
    $allowed = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase) -or [System.IO.Path]::GetFileName($resolved) -notlike 'gi-hooks-*') { throw 'Unsafe hook test cleanup target.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
