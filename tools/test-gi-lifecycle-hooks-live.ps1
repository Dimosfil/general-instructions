[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$FixturePath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixture = [IO.Path]::GetFullPath($FixturePath)
$shell = (Get-Process -Id $PID).Path
$codex = (Get-Command codex -ErrorAction Stop).Source
$utf8 = [Text.UTF8Encoding]::new($false)

function Start-CodexProcess {
    param([string[]]$Arguments)
    $start = [Diagnostics.ProcessStartInfo]::new($shell)
    # Launch the resolved, vetted CLI wrapper without interpolating shell text.
    foreach ($arg in @('-NoProfile', '-NonInteractive', '-File', $codex) + $Arguments) { $start.ArgumentList.Add($arg) }
    $start.WorkingDirectory = $fixture
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    return [Diagnostics.Process]::Start($start)
}

function Read-RpcReply {
    param($Process, [int]$Id)
    do {
        $line = $Process.StandardOutput.ReadLineAsync()
        if (-not $line.Wait(30000) -or -not $line.Result) { throw 'Native hook inventory timed out.' }
        $reply = $line.Result | ConvertFrom-Json -AsHashtable
    } while ($reply['id'] -ne $Id)
    if ($reply.Contains('error')) { throw 'Native hook inventory failed.' }
    return $reply.result
}

# Retain the owned fixture for normal host trust and repeatable tests.
if ((Test-Path -LiteralPath $fixture) -and -not (Test-Path -LiteralPath (Join-Path $fixture '.gi-live-fixture'))) { throw 'Existing directory is not an owned GI live-test fixture.' }
[void][IO.Directory]::CreateDirectory($fixture)
[IO.File]::WriteAllText((Join-Path $fixture '.gi-live-fixture'), 'Disposable GI lifecycle test fixture.', $utf8)
& (Join-Path $source 'tools/install-instruction-kit.ps1') -Source $source -TargetPath $fixture | Out-Null
& git -C $fixture init --quiet
# No inherited project's AGENTS instructions can cause a manual Complete call.
[IO.File]::WriteAllText((Join-Path $fixture 'AGENTS.md'), '# Controlled native lifecycle test. Follow the test prompt.', $utf8)
# Reject ALL other hooks and require normal persisted host trust.
# No persisted trust/auth/config files are read, copied, or modified by this test.
$inventory = Start-CodexProcess -Arguments @('app-server', '--stdio')
try {
    $inventoryErrors = $inventory.StandardError.ReadToEndAsync()
    $inventory.StandardInput.WriteLine('{"id":1,"method":"initialize","params":{"clientInfo":{"name":"gi-hook-live-test","version":"1"},"capabilities":{"experimentalApi":true}}}')
    $null = Read-RpcReply $inventory 1
    $inventory.StandardInput.WriteLine('{"method":"initialized","params":{}}')
    $inventory.StandardInput.WriteLine((@{id=2;method='hooks/list';params=@{cwds=@($fixture)}} | ConvertTo-Json -Depth 8 -Compress))
    $listed = Read-RpcReply $inventory 2
    $hooks = @($listed.data | ForEach-Object { $_['hooks'] } | Where-Object { $null -ne $_ })
    $expected = (Join-Path $fixture '.codex/hooks.json')
    $loadErrors = @($listed.data | ForEach-Object { $_['errors'] } | Where-Object { $null -ne $_ })
    if ($loadErrors.Count -gt 0 -or $hooks.Count -ne 3) { throw "Trust the isolated test project and its three GI hooks in Codex /hooks first: $fixture" }
    if ((Get-FileHash -LiteralPath $expected).Hash -ne (Get-FileHash -LiteralPath (Join-Path $source '.codex/hooks.json')).Hash) {
        # Installer formatting can differ; compare the event definitions.
        $installed = Get-Content -LiteralPath $expected -Raw | ConvertFrom-Json -AsHashtable
        $approved = Get-Content -LiteralPath (Join-Path $source '.codex/hooks.json') -Raw | ConvertFrom-Json -AsHashtable
        if (($installed.hooks | ConvertTo-Json -Depth 20 -Compress) -cne ($approved.hooks | ConvertTo-Json -Depth 20 -Compress)) { throw 'Fixture hooks differ from the reviewed source.' }
    }
    foreach ($hook in $hooks) {
        if ($hook.sourcePath -ine $expected -or -not $hook.enabled -or $hook.trustStatus -ne 'trusted' -or $hook.command -notlike '*invoke-gi-lifecycle-hook.ps1*') {
            throw 'An unvetted hook source prevents the isolated native test.'
        }
    }
} finally { if (-not $inventory.HasExited) { $inventory.Kill($true) }; $inventory.WaitForExit(); $inventory.Dispose() }

$prompt = @'
Controlled native hook test. Do not use any tools, read files, modify files, or call get-gi-context.ps1 or Complete. The entire task is this two-step response protocol. In your FIRST final response, write INITIAL_WITHOUT_COMPLETE and quote the heading of the whole-task completion rule received in developer context. If an automatic GI final review then makes you continue, review this response protocol and answer VERIFIED_BY_HOOK. Do not claim a continuation occurred until it actually does. No manual Complete invocation is permitted in either step.
'@
$auditPath = Join-Path $fixture '.codex/.gi-hook-state/events.jsonl'
$auditOffset = if (Test-Path -LiteralPath $auditPath) { @(Get-Content -LiteralPath $auditPath).Count } else { 0 }
$process = Start-CodexProcess -Arguments @('exec', '--ephemeral', '--json', '--sandbox', 'read-only', '-C', $fixture, '-')
try {
    $output = $process.StandardOutput.ReadToEndAsync(); $errors = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.WriteLine($prompt); $process.StandardInput.Close()
    if (-not $process.WaitForExit(240000)) { $process.Kill($true); throw 'Native Codex test timed out.' }
    if ($process.ExitCode -ne 0) { throw ('Native Codex test failed: ' + $errors.Result) }
    $events = @($output.Result -split '\r?\n' | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json -AsHashtable })
    $items = @($events | Where-Object { $_['type'] -eq 'item.completed' } | ForEach-Object { $_.item })
    $toolItems = @($items | Where-Object { $_['type'] -notin @('agent_message', 'reasoning', 'error') })
    $messages = @($items | Where-Object { $_['type'] -eq 'agent_message' } | ForEach-Object { $_.text })
    if ($toolItems.Count -ne 0 -or ($messages -join "`n") -notmatch 'INITIAL_WITHOUT_COMPLETE' -or ($messages -join "`n") -notmatch 'Whole-Task Completion Gate' -or $messages[-1] -notmatch 'VERIFIED_BY_HOOK') {
        $auditPath = Join-Path $fixture '.codex/.gi-hook-state/events.jsonl'
        $outcomeText = if (Test-Path -LiteralPath $auditPath) { (Get-Content -LiteralPath $auditPath) -join ' ' } else { 'NO HOOK AUDIT' }
        throw ('Native omission test failed: tool count=' + $toolItems.Count + '; responses=' + ($messages -join ' | ') + '; errors=' + (@($items | Where-Object { $_.type -eq 'error' }) | ConvertTo-Json -Depth 8 -Compress) + '; audit=' + $outcomeText + '; diagnostics=' + $errors.Result)
    }
    $audit = @(Get-Content -LiteralPath $auditPath | Select-Object -Skip $auditOffset | ForEach-Object { $_ | ConvertFrom-Json })
    $outcomes = @($audit.outcome)
    if ($outcomes -notcontains 'rules_injected' -or $outcomes -notcontains 'completion_review_required' -or $outcomes[-1] -ne 'completion_allowed') {
        throw ('Native hooks did not finish the required lifecycle: ' + ($outcomes -join ', '))
    }
    [pscustomobject]@{ cli = (& codex --version); manual_complete_calls = 0; tool_calls = 0; automatic_review = $true; outcomes = $outcomes; trust = 'normal persisted project and exact hook trust; no bypass' }
} finally { if (-not $process.HasExited) { $process.Kill($true) }; $process.WaitForExit(); $process.Dispose() }
