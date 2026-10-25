[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('gi-verification-' + [guid]::NewGuid().ToString('N'))
$utf8 = [System.Text.UTF8Encoding]::new($false)
$selector = Join-Path $repoRoot 'templates/select-task-verification.template.ps1'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-RejectedWithoutWrite {
    param([string]$Path, [string]$Choice)
    $before = [System.IO.File]::ReadAllText($Path)
    $rejected = $false
    try { & $selector -OutputPath $Path -Selection $Choice | Out-Null }
    catch { $rejected = $true }
    Assert-True $rejected 'Invalid input/state must be rejected.'
    Assert-True ([System.IO.File]::ReadAllText($Path) -ceq $before) 'Rejected input changed preferences.'
}

try {
    [void](New-Item -ItemType Directory -Path $testRoot)
    $path = Join-Path $testRoot 'preferences.json'
    & $selector -OutputPath $path -Selection 'отмена'
    Assert-True (-not (Test-Path -LiteralPath $path)) 'Cancel created a preference file.'
    & $selector -OutputPath $path -Selection 'выкл'
    $saved = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($saved.task_completion_review.enabled -eq $false) 'Off was not saved.'
    [System.IO.File]::WriteAllText($path, '{"task_completion_review":{"enabled":false,"custom":"сохранить"},"other":42}', $utf8)
    $beforeCancel = [System.IO.File]::ReadAllText($path)
    & $selector -OutputPath $path -Selection '3'
    Assert-True ([System.IO.File]::ReadAllText($path) -ceq $beforeCancel) 'Cancel rewrote existing settings.'
    foreach ($choice in @('1 2', 'unknown', '4')) { Assert-RejectedWithoutWrite $path $choice }
    foreach ($choice in @('1', 'off', 'on', '2', 'вкл')) {
        & $selector -OutputPath $path -Selection $choice
        $saved = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        $expected = $choice -in @('1', 'on', 'вкл')
        Assert-True ($saved.task_completion_review.enabled -is [bool] -and $saved.task_completion_review.enabled -eq $expected) "Wrong state for $choice."
        Assert-True ($saved.other -eq 42 -and $saved.task_completion_review.custom -ceq 'сохранить') 'Unrelated settings or UTF-8 text changed.'
    }
    foreach ($invalid in @('{broken', 'null', '[]', '{"task_completion_review":false}', '{"task_completion_review":{"enabled":"false"}}')) {
        [System.IO.File]::WriteAllText($path, $invalid, $utf8)
        Assert-RejectedWithoutWrite $path 'on'
    }

    # Exercise delivered mechanisms through the installed public entrypoints.
    $project = Join-Path $testRoot 'project'
    [void](New-Item -ItemType Directory -Path $project)
    $installer = Join-Path $repoRoot 'tools/install-instruction-kit.ps1'
    & $installer -Source $repoRoot -SourceRoot $repoRoot -TargetPath $project | Out-Null
    $installedSelector = Join-Path $project 'tools/select-task-verification.ps1'
    $installedPath = Join-Path $project 'tools/project-memory/verification-preferences.json'
    $builder = Join-Path $project 'tools/get-gi-context.ps1'
    $packet = (& $builder -CommandText 'ги проверка' -SkipUpdateCheck | Out-String)
    Assert-True ($packet.Contains('GI route: task-verification') -and $packet.Contains('Task completion review: On')) 'Installed route/default state missing.'
    & $installedSelector -OutputPath $installedPath -Selection '2'
    $systemPath = Join-Path $project 'tools/project-memory/system-preferences.json'
    & (Join-Path $project 'tools/select-system-language.ps1') -OutputPath $systemPath -Selection 'Russian' | Out-Null
    & $installer -Source $repoRoot -SourceRoot $repoRoot -TargetPath $project | Out-Null
    $packet = (& $builder -CommandText 'gi stack' -SkipUpdateCheck | Out-String)
    Assert-True ($packet.Contains('Task completion review: Off')) 'Language change, reinstall, or non-start context lost the opt-out.'
    [System.IO.File]::WriteAllText($installedPath, '{}', $utf8)
    $packet = (& $builder -CommandText 'gi stack' -SkipUpdateCheck | Out-String)
    Assert-True ($packet.Contains('Task completion review: On')) 'Absent field must default to On.'
    Remove-Item -LiteralPath $installedPath
    $packet = (& $builder -CommandText 'gi stack' -SkipUpdateCheck | Out-String)
    Assert-True ($packet.Contains('Task completion review: On')) 'Absent file must default to On.'
    [System.IO.File]::WriteAllText($installedPath, '{"task_completion_review":{"enabled":"false"}}', $utf8)
    $packet = (& $builder -CommandText 'gi stack' -SkipUpdateCheck | Out-String)
    Assert-True ($packet.Contains('Invalid verification preferences') -and -not $packet.Contains('Task completion review: Off')) 'Malformed preference was treated as a valid choice.'
    # Reproduce late-published historical IDs below an installed checkpoint.
    # The forward repair must be discoverable from both affected boundaries.
    $repairId = '2026.10.25.4__repair_task_review_delivery'
    $repairSource = Join-Path $testRoot 'repair-source'
    [void](New-Item -ItemType Directory -Path (Join-Path $repairSource 'migrations') -Force)
    foreach ($name in @('README', '2026.10.18.1__configure_task_completion_review', '2026.10.18.2__verify_document_conclusions_with_quotes', $repairId)) {
        Copy-Item -LiteralPath (Join-Path $repoRoot "migrations/$name.md") -Destination (Join-Path $repairSource "migrations/$name.md")
    }
    [System.IO.File]::WriteAllText((Join-Path $repairSource 'VERSION.md'), 'Current accepted version: `2026.10.25.4`', $utf8)
    $checker = Join-Path $repoRoot 'templates/check-instruction-kit-updates.template.ps1'
    $routePath = Join-Path $project 'config/gi-command-routes.json'
    $modulePath = Join-Path $project 'patterns/AGENTS_RUNTIME/15-final-review.md'
    $ownedPaths = @('patterns/AGENTS_RUNTIME/15-final-review.md', 'tools/select-task-verification.ps1', 'tools/project-memory/verification-preferences.json')
    foreach ($checkpoint in @('2026.10.23.1', '2026.10.25.3')) {
        $metadataPath = Join-Path $project 'tools/project-memory/instruction-kit.json'
        $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
        $metadata.instruction_kit_version = $checkpoint
        $metadata.migration_state.applied_through = "${checkpoint}__previous"
        $metadata.copied_files = @($metadata.copied_files | Where-Object { $_ -notin $ownedPaths })
        [System.IO.File]::WriteAllText($metadataPath, ($metadata | ConvertTo-Json -Depth 10), $utf8)
        Remove-Item -LiteralPath $modulePath, $installedSelector
        if ($checkpoint -eq '2026.10.23.1') { Remove-Item -LiteralPath $installedPath }
        else { [System.IO.File]::WriteAllText($installedPath, '{"task_completion_review":{"enabled":false,"custom":"сохранить"},"other":42}', $utf8) }
        $preferencesBefore = if (Test-Path -LiteralPath $installedPath) { [System.IO.File]::ReadAllText($installedPath) } else { $null }
        $manifest = Get-Content -LiteralPath $routePath -Raw | ConvertFrom-Json
        $manifest.routes = @($manifest.routes | Where-Object { $_.id -ne 'task-verification' })
        [System.IO.File]::WriteAllText($routePath, ($manifest | ConvertTo-Json -Depth 100), $utf8)
        $notice = (& $checker -InstructionKitPath $metadataPath -SharedLibraryPath $repairSource *>&1 | Out-String)
        Assert-True ($notice.Contains('Pending instruction migrations: 1') -and $notice.Contains("- $repairId")) 'Forward repair was skipped by an older checkpoint.'
        Assert-True (-not $notice.Contains('- 2026.10.18.1__')) 'Fixture no longer reproduces the historical checkpoint failure.'
        # Apply the migration delivery contract, preserving unrelated routes/settings.
        Copy-Item -LiteralPath (Join-Path $repoRoot 'patterns/AGENTS_RUNTIME/15-final-review.md') -Destination $modulePath
        Copy-Item -LiteralPath $selector -Destination $installedSelector
        if (-not (Test-Path -LiteralPath $installedPath)) {
            Copy-Item -LiteralPath (Join-Path $repoRoot 'templates/verification-preferences.template.json') -Destination $installedPath
        }
        $sourceManifest = Get-Content -LiteralPath (Join-Path $repoRoot 'config/gi-command-routes.json') -Raw | ConvertFrom-Json
        $manifest.routes = @($manifest.routes) + @($sourceManifest.routes | Where-Object { $_.id -eq 'task-verification' })
        [System.IO.File]::WriteAllText($routePath, ($manifest | ConvertTo-Json -Depth 100), $utf8)
        $metadata.copied_files = @($metadata.copied_files) + $ownedPaths
        [System.IO.File]::WriteAllText($metadataPath, ($metadata | ConvertTo-Json -Depth 10), $utf8)
        foreach ($alias in @('ги проверка', 'gi проверка', 'gi verification', 'gi check')) {
            $packet = (& $builder -CommandText $alias -SkipUpdateCheck | Out-String)
            Assert-True ($packet.Contains('GI route: task-verification') -and $packet.Contains('15-final-review.md')) 'Restored command cannot load the delivered review module.'
        }
        $state = if ($null -eq $preferencesBefore) { 'On' } else { 'Off' }
        Assert-True ($packet.Contains("Task completion review: $state")) 'Repair lost default state or existing opt-out.'
        if ($null -ne $preferencesBefore) { Assert-True ([System.IO.File]::ReadAllText($installedPath) -ceq $preferencesBefore) 'Repair rewrote existing preferences.' }
        $unrelatedPacket = (& $builder -CommandText 'gi stack' -SkipUpdateCheck | Out-String)
        Assert-True ($unrelatedPacket.Contains('GI route: stack')) 'Repair lost an unrelated route.'
        $complete = (& $builder -Phase Complete | Out-String)
        Assert-True ($complete.Contains('Whole-Task Completion Gate')) 'Repaired installation cannot load Complete rules.'
        & $checker -InstructionKitPath $metadataPath -SharedLibraryPath $repairSource -RecordApplied *>&1 | Out-Null
        $after = (& $checker -InstructionKitPath $metadataPath -SharedLibraryPath $repairSource *>&1 | Out-String)
        Assert-True ($after.Contains('Pending instruction migrations: 0')) 'Verified repair did not finish recording.'
        $recorded = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
        Assert-True ($recorded.migration_state.applied_through -eq $repairId) 'Repair checkpoint was not recorded.'
    }
    Write-Output 'Task completion review and forward-repair scenarios passed.'
}
finally {
    $resolved = [System.IO.Path]::GetFullPath($testRoot)
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
        [System.IO.Path]::GetFileName($resolved) -notlike 'gi-verification-*') { throw 'Unsafe test cleanup target.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
