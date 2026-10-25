[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $repoRoot "config/gi-command-routes.json"
$budgetPath = Join-Path $repoRoot "config/gi-context-budgets.json"
$resolverPath = Join-Path $repoRoot "tools/resolve-gi-command.ps1"
$builderPath = Join-Path $repoRoot "tools/get-gi-context.ps1"
$updaterTemplate = Join-Path $repoRoot "templates/check-instruction-kit-updates.template.ps1"
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("gi-context-routing-" + [guid]::NewGuid().ToString("N"))
$compatibilityModules = @(
    "patterns/AGENTS_RUNTIME/07-startup-and-scope.md",
    "patterns/AGENTS_RUNTIME/08-config-service-and-task-manager.md",
    "patterns/AGENTS_RUNTIME/09-project-operation-commands.md"
)

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Failure
    )
    if (-not $Text.Contains($Expected)) { throw $Failure }
}

function Assert-FileBudget {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][long]$Maximum,
        [string]$RootPath = $repoRoot
    )
    $text = [System.IO.File]::ReadAllText((Join-Path $RootPath $RelativePath)).Replace("`r`n", "`n")
    $length = [System.Text.Encoding]::UTF8.GetByteCount($text)
    if ($length -gt $Maximum) {
        throw "$RelativePath exceeded its context budget: $length > $Maximum bytes."
    }
}

function New-UpdateFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$MetadataJson,
        [switch]$WithoutMigrations
    )
    $source = Join-Path $testRoot "$Name-source"
    $project = Join-Path $testRoot "$Name-project"
    [void](New-Item -ItemType Directory -Path $source -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $project "tools/project-memory") -Force)
    [System.IO.File]::WriteAllText(
        (Join-Path $source "VERSION.md"),
        "Current accepted version: ``2026.09.22.2``",
        [System.Text.UTF8Encoding]::new($false)
    )
    if (-not $WithoutMigrations) {
        [void](New-Item -ItemType Directory -Path (Join-Path $source "migrations") -Force)
        Copy-Item -LiteralPath (Join-Path $repoRoot 'migrations/README.md') -Destination (Join-Path $source 'migrations/README.md')
        foreach ($id in @("2026.09.22.1__already", "2026.09.22.2__pending")) {
            [System.IO.File]::WriteAllText(
                (Join-Path $source "migrations/$id.md"),
                "# $id",
                [System.Text.UTF8Encoding]::new($false)
            )
        }
    }
    [System.IO.File]::WriteAllText(
        (Join-Path $project "tools/project-memory/instruction-kit.json"),
        $MetadataJson,
        [System.Text.UTF8Encoding]::new($false)
    )
    return [pscustomobject]@{ Source = $source; Project = $project }
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $budgets = Get-Content -LiteralPath $budgetPath -Raw | ConvertFrom-Json
    $mandatoryRules = [System.IO.File]::ReadAllText((Join-Path $repoRoot 'patterns/AGENTS_RUNTIME/03-rule-precedence.md')).Replace("`r`n", "`n").TrimEnd()
    $aliases = @{}
    foreach ($route in $manifest.routes) {
        if (-not $route.id -or -not $route.contract -or @($route.aliases).Count -eq 0) {
            throw "Route is missing id, contract, or aliases."
        }
        foreach ($aliasValue in $route.aliases) {
            $alias = ([string]$aliasValue).Trim().ToLowerInvariant()
            if ($aliases.ContainsKey($alias) -and $aliases[$alias] -ne $route.id) {
                throw "Alias '$alias' is assigned to both '$($aliases[$alias])' and '$($route.id)'."
            }
            $aliases[$alias] = [string]$route.id
        }
        $routeAliases = @($route.aliases | ForEach-Object { ([string]$_).Trim().ToLowerInvariant() })
        foreach ($alias in $routeAliases) {
            if ($alias -match '^gi (?<tail>.*[А-Яа-яЁё].*)$') {
                $cyrillicPrefixAlias = "ги $($Matches.tail)"
                if ($routeAliases -notcontains $cyrillicPrefixAlias) {
                    throw "Route '$($route.id)' is missing Cyrillic-prefix alias '$cyrillicPrefixAlias' for '$alias'."
                }
            }
        }
        foreach ($relativePathValue in $route.context_files) {
            $relativePath = [string]$relativePathValue
            if ($compatibilityModules -contains $relativePath) {
                throw "Route '$($route.id)' loads compatibility-only module '$relativePath'."
            }
            if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf)) {
                throw "Route '$($route.id)' references missing context file '$relativePath'."
            }
        }

        $packet = (& $resolverPath -CommandText ([string]$route.aliases[0]) | Out-String).Replace("`r`n", "`n")
        $maximum = [int]$budgets.route_packet_default_max_chars
        $override = $budgets.route_packet_overrides.PSObject.Properties[[string]$route.id]
        if ($override) { $maximum = [int]$override.Value }
        if ($packet.Length -gt $maximum) {
            throw "Route '$($route.id)' exceeded its packet budget: $($packet.Length) > $maximum chars."
        }
        $workPacket = (& $builderPath -CommandText ([string]$route.aliases[0]) -SkipUpdateCheck | Out-String).Replace("`r`n", "`n")
        Assert-Contains $workPacket $mandatoryRules "Route '$($route.id)' omitted complete mandatory task rules."
        $workMaximum = if ($route.id -eq 'start') { [int]$budgets.start_packet_max_chars } else { $maximum }
        if ($workPacket.Length -gt $workMaximum) { throw "Protected work context exceeded its unchanged budget: $($route.id)" }
    }

    $routeCases = @(
        @{ Command = "ги проверка"; Route = "task-verification" },
        @{ Command = "gi проверка выкл"; Route = "task-verification" },
        @{ Command = "gi verification on"; Route = "task-verification" },
        @{ Command = "gi check"; Route = "task-verification" },
        @{ Command = "ги старт оптимизация подумать"; Route = "start" },
        @{ Command = "gi start sprint"; Route = "start-sprint" },
        @{ Command = "gi plan"; Route = "task-plan" },
        @{ Command = "gi test"; Route = "test" },
        @{ Command = "ги тест"; Route = "test" },
        @{ Command = "gi тест"; Route = "test" },
        @{ Command = "gi testing"; Route = "test" },
        @{ Command = "ги тест старт выбранный сценарий"; Route = "test-start" },
        @{ Command = "gi test start selected scenario"; Route = "test-start" },
        @{ Command = "gi тест старт"; Route = "test-start" },
        @{ Command = "gi testing start"; Route = "test-start" },
        @{ Command = "gi test plan"; Route = "test-plan" },
        @{ Command = "ги тест таск выбранный сценарий"; Route = "test-task" },
        @{ Command = "gi full test"; Route = "test-full" },
        @{ Command = "gi release test"; Route = "test-full" },
        @{ Command = "gi system test"; Route = "test-full" },
        @{ Command = "gi testing task"; Route = "test-task" },
        @{ Command = "gi задача теста"; Route = "test-task" },
        @{ Command = "ги менеджер"; Route = "task-manager" },
        @{ Command = "ги манагер"; Route = "task-manager" },
        @{ Command = "ги менеджер тест"; Route = "task-manager-test" },
        @{ Command = "gi config service off"; Route = "config-self-registration" },
        @{ Command = "gi restart"; Route = "restart" },
        @{ Command = "gi error fix"; Route = "error-fix" },
        @{ Command = "gi tools rebuild vector"; Route = "rag-rebuild" },
        @{ Command = "gi only push"; Route = "git-finish" },
        @{ Command = "ги пуш"; Route = "git-finish" },
        @{ Command = "ги пуш всё"; Route = "git-finish" },
        @{ Command = "ги пуш все"; Route = "git-finish" },
        @{ Command = "gi push all"; Route = "git-finish" },
        @{ Command = "ги коммит всё"; Route = "git-finish" },
        @{ Command = "gi commit push all"; Route = "git-finish" },
        @{ Command = "ги пуш src/example.ps1"; Route = "git-finish" },
        @{ Command = "gi only push all"; Route = "git-finish" }
    )
    foreach ($case in $routeCases) {
        $output = (& $resolverPath -CommandText $case.Command -PathsOnly | Out-String)
        $routeLine = @($output -split '\r?\n' | Where-Object { $_ -like 'GI route:*' })
        if ($routeLine.Count -ne 1 -or $routeLine[0] -ne ("GI route: {0}" -f $case.Route)) {
            throw "Command '$($case.Command)' resolved incorrectly."
        }
        Assert-Contains $output ("Requested command: {0}" -f $case.Command) "Resolver discarded command modifiers or selection."
    }

    $testInfoRoute = @($manifest.routes | Where-Object { $_.id -eq "test" })[0]
    if (@($testInfoRoute.context_files).Count -ne 1 -or
        $testInfoRoute.context_files[0] -ne "patterns/AGENTS_RUNTIME/09-testing.md") {
        throw "Tester information must load only the shared tester rule."
    }
    Assert-Contains $testInfoRoute.contract "do not execute tests or mutate runtime state" "Tester information became executable."
    $testStartPacket = (& $resolverPath -CommandText "ги тест старт выбранный сценарий" | Out-String)
    Assert-Contains $testStartPacket "project-local scenario" "Test start lost local scenario ownership."
    Assert-Contains $testStartPacket "restoration-required" "Test start lost restoration state."
    if ($testStartPacket.Contains("===== BEGIN patterns/AGENTS_RUNTIME/09-full-testing.md =====") -or
        $testStartPacket.Contains("===== BEGIN patterns/AGENTS_RUNTIME/09-runtime-and-defaults.md =====")) {
        throw "Ordinary test start must not inherit full-system reset instructions."
    }
    $testFullPacket = (& $resolverPath -CommandText "gi full test" | Out-String)
    Assert-Contains $testFullPacket "===== BEGIN patterns/AGENTS_RUNTIME/09-full-testing.md =====" "Full-system test lost its dedicated flow."
    Assert-Contains $testFullPacket "default/factory baseline" "Full-system test lost baseline reset."
    Assert-Contains $testFullPacket "Exercise live required" "Full-system test lost live-surface checks."

    $gitFinishPacket = (& $resolverPath -CommandText "ги пуш" | Out-String)
    $gitFinishRoute = @($manifest.routes | Where-Object { $_.id -eq "git-finish" })
    if ($gitFinishRoute.Count -ne 1 -or
        @($gitFinishRoute[0].context_files) -contains "patterns/AGENTS_RUNTIME/15-verification.md") {
        throw "Git-finish route must not load feature-contract verification."
    }
    foreach ($needle in @(
        "Perform only the requested Git finish",
        "standalone repository scope",
        "command-defined scope also applies in a new chat",
        "exclude secrets",
        "inseparable excluded",
        '`gi only push` never selects working-tree files',
        "never classify the whole dirty",
        "does not by itself authorize product fixes",
        "does not start a project-memory audit"
    )) {
        Assert-Contains $gitFinishPacket $needle "Git-finish route is missing scope boundary text: $needle"
    }
    $gitAllPacket = (& $builderPath -CommandText "ги пуш всё" -SkipUpdateCheck | Out-String)
    foreach ($needle in @(
        "Requested command: ги пуш всё",
        "explicit all-changes selection overrides active task scope",
        "including staged, unstaged",
        "old summaries alone do not create an active task",
        "still pushes existing outgoing commits",
        "Do not create an empty commit",
        "git status --short --untracked-files=all",
        "Account for every selected eligible change",
        "report remaining changes by directory/reason with counts",
        "An eligible selected remainder makes the finish incomplete",
        "gi only push all",
        "git check-ignore"
    )) {
        Assert-Contains $gitAllPacket $needle "Git all-changes context is incomplete: $needle"
    }
    $onlyPushAllPacket = (& $resolverPath -CommandText "gi only push all" -PathsOnly | Out-String)
    Assert-Contains $onlyPushAllPacket "Matched alias: gi only push" "All modifier changed push-only operation."
    if ($gitFinishPacket.Contains("===== patterns/AGENTS_RUNTIME/15-verification.md =====") -or
        $gitFinishPacket.Contains("compare the scoped diff with the relevant durable")) {
        throw "Git-finish route loaded the feature-contract verification workflow."
    }
    $featureVerificationText = [System.IO.File]::ReadAllText((Join-Path $repoRoot "patterns/AGENTS_RUNTIME/15-verification.md"))
    Assert-Contains $featureVerificationText "before calling the task complete" "Development-time contract verification disappeared."
    $refactorContext = (& $resolverPath -CommandText "gi refactor" | Out-String)
    Assert-Contains $refactorContext 'scenario -> mechanism' 'Refactor context omitted the pre-edit mechanism mapping.'
    Assert-Contains $refactorContext 'contract owner -> change location -> verification' 'Refactor context omitted responsibility and verification.'
    Assert-Contains $refactorContext 'side effects' 'Refactor context omitted observable side-effect verification.'
    Assert-Contains $refactorContext 'patterns/ARCHITECTURE_AND_CODE_QUALITY.md' 'Refactor context omitted its mechanism-gate dependency.'
    $gitWorkflowText = [System.IO.File]::ReadAllText((Join-Path $repoRoot "patterns/GIT_WORKFLOW.md"))
    foreach ($needle in @(
        "Never infer that all dirty files",
        "authorize unrelated code or test repairs",
        "rebuilds/restarts"
    )) {
        Assert-Contains $gitWorkflowText $needle "Git workflow is missing finish-only guard text: $needle"
    }
    $agreementsText = [System.IO.File]::ReadAllText((Join-Path $repoRoot "templates/AGENT_WORKING_AGREEMENTS.template.md"))
    $gitContractsText = [System.IO.File]::ReadAllText((Join-Path $repoRoot "patterns/GI_COMMAND_CONTRACTS.md"))
    foreach ($obsolete in @(
        "instead of falling back to push-only behavior",
        "running a push-only fallback",
        "Push без нового`r`ncommit выполняется только",
        "Push без нового`ncommit выполняется только"
    )) {
        if (($gitWorkflowText + $agreementsText + $gitContractsText).Contains($obsolete)) {
            throw "Git guidance retained obsolete no-new-commit push prohibition: $obsolete"
        }
    }

    Assert-FileBudget "AGENTS.md" ([long]$budgets.entrypoint_max_bytes)
    Assert-FileBudget "templates/AGENTS.template.md" ([long]$budgets.template_entrypoint_max_bytes)
    Assert-FileBudget "COMMANDS.md" ([long]$budgets.command_index_max_bytes)
    Assert-FileBudget "tools/project-memory/instruction-kit.json" ([long]$budgets.metadata_max_bytes)
    Assert-FileBudget "templates/instruction-kit.template.json" ([long]$budgets.metadata_max_bytes)
    foreach ($module in Get-ChildItem -LiteralPath (Join-Path $repoRoot "patterns/AGENTS_RUNTIME") -File -Filter "*.md") {
        Assert-FileBudget ("patterns/AGENTS_RUNTIME/" + $module.Name) ([long]$budgets.runtime_module_max_bytes)
    }

    $startPacket = (& $builderPath -CommandText "gi start" -SkipUpdateCheck | Out-String).Replace("`r`n", "`n")
    Assert-Contains $startPacket "Instruction update check: skipped by caller" "Context builder omitted update status."
    Assert-Contains $startPacket "GI route: start" "Context builder omitted the start route."
    Assert-Contains $startPacket "===== PROJECT ENTRYPOINT =====" "Context builder omitted the project entrypoint."
    Assert-Contains $startPacket "===== GIT COMMIT PREFERENCES =====" "Context builder omitted commit preferences."
    Assert-Contains $startPacket "===== AGENT SYSTEM LANGUAGE =====" "Context builder omitted system-language preferences."
    Assert-Contains $startPacket "===== LATEST HANDOFF SUMMARY =====" "Context builder omitted summary state."
    Assert-Contains $startPacket "===== GIT SNAPSHOT =====" "Context builder omitted Git state."
    Assert-Contains $startPacket "Startup restore complete." "Context builder omitted the restore completion marker."
    if ($startPacket.Length -gt [int]$budgets.start_packet_max_chars) {
        throw "gi start context packet exceeded budget: $($startPacket.Length) chars."
    }
    $nonStartPacket = (& $builderPath -CommandText "gi stack" -SkipUpdateCheck | Out-String)
    if ($nonStartPacket.Contains("===== PROJECT ENTRYPOINT =====") -or
        $nonStartPacket.Contains("===== LATEST HANDOFF SUMMARY =====") -or
        $nonStartPacket.Contains("===== RUNBOOK COMMAND HINTS =====")) {
        throw "Non-start route received startup-only context sections."
    }

    [void](New-Item -ItemType Directory -Path $testRoot)
    # Publication must reject late additions below the compact checkpoint,
    # regardless of whether they are untracked, staged or already committed.
    $releaseCheck = Join-Path $repoRoot 'tools/test-instruction-kit-release.ps1'
    foreach ($case in @('valid', 'equal', 'backdated', 'staged', 'committed', 'future', 'malformed', 'removed')) {
        $releaseRoot = Join-Path $testRoot "release-$case"
        [void](New-Item -ItemType Directory -Path (Join-Path $releaseRoot 'migrations') -Force)
        function Invoke-FixtureGit {
            param([string[]]$GitArguments)
            $result = @(& git -C $releaseRoot @GitArguments 2>&1)
            if ($LASTEXITCODE -ne 0) { throw ($result -join "`n") }
            return $result
        }
        Invoke-FixtureGit -GitArguments @('init', '-q') | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $releaseRoot 'VERSION.md'), 'Current accepted version: `2026.10.25.3`')
        if ($case -eq 'removed') {
            [System.IO.File]::WriteAllText((Join-Path $releaseRoot 'migrations/2026.10.25.3__released.md'), "# Released`n`nVersion: ``2026.10.25.3```n")
        }
        Invoke-FixtureGit -GitArguments @('add', '.') | Out-Null
        Invoke-FixtureGit -GitArguments @('-c', 'user.name=GI fixture', '-c', 'user.email=fixture@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-qm', 'published baseline') | Out-Null
        $baselineRef = [string](Invoke-FixtureGit -GitArguments @('rev-parse', 'HEAD'))
        [System.IO.File]::WriteAllText((Join-Path $releaseRoot 'VERSION.md'), 'Current accepted version: `2026.10.25.4`')
        if ($case -eq 'removed') { Remove-Item -LiteralPath (Join-Path $releaseRoot 'migrations/2026.10.25.3__released.md') }
        $version = switch ($case) {
            'valid' { '2026.10.25.4' }
            'removed' { '2026.10.25.4' }
            'malformed' { 'invalid' }
            'equal' { '2026.10.25.3' }
            'future' { '2026.10.25.5' }
            default { '2026.10.18.1' }
        }
        [System.IO.File]::WriteAllText((Join-Path $releaseRoot "migrations/${version}__fixture.md"), "# Fixture`n`nVersion: ``$version```n")
        if ($case -in @('staged', 'committed')) {
            Invoke-FixtureGit -GitArguments @('add', '.') | Out-Null
        }
        if ($case -eq 'committed') {
            Invoke-FixtureGit -GitArguments @('-c', 'user.name=GI fixture', '-c', 'user.email=fixture@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-qm', 'late addition') | Out-Null
        }
        $failure = ''
        try { & $releaseCheck -BaseRef $baselineRef -SourceRoot $releaseRoot | Out-Null }
        catch { $failure = $_.Exception.Message }
        if ($case -eq 'valid') {
            if ($failure) { throw "Valid forward release rejected: $failure" }
        } else {
            $expected = switch ($case) {
                'future' { 'Migration exceeds VERSION.md' }
                'malformed' { 'Invalid migration ID' }
                'removed' { 'Released migration removed or renamed' }
                default { 'Backdated migration' }
            }
            Assert-Contains $failure $expected "Release guard accepted invalid $case publication or failed for an unrelated reason."
        }
    }
    $equal = New-UpdateFixture -Name "equal" -WithoutMigrations -MetadataJson `
        '{"instruction_kit_version":"2026.09.22.2","migration_state":{"schema_version":2,"applied_through":"2026.09.22.2__pending","additional_applied_migrations":[],"skipped_migrations":[]},"update_check":{"enabled":true}}'
    $equalOutput = (& $updaterTemplate -InstructionKitPath (Join-Path $equal.Project "tools/project-memory/instruction-kit.json") -SharedLibraryPath $equal.Source *>&1 | Out-String)
    Assert-Contains $equalOutput "Pending instruction migrations: 0" "Equal-version fast path failed."
    if ($equalOutput.Contains("No migrations folder found")) { throw "Equal-version check inspected migrations." }

    $v2 = New-UpdateFixture -Name "v2" -MetadataJson `
        '{"instruction_kit_version":"2026.09.22.1","migration_state":{"schema_version":2,"applied_through":"2026.09.22.1__already","additional_applied_migrations":[],"skipped_migrations":[]},"update_check":{"enabled":true}}'
    $v2Path = Join-Path $v2.Project "tools/project-memory/instruction-kit.json"
    $v2Output = (& $updaterTemplate -InstructionKitPath $v2Path -SharedLibraryPath $v2.Source *>&1 | Out-String)
    Assert-Contains $v2Output "Pending instruction migrations: 1" "Schema-v2 metadata did not filter the checkpoint."
    Assert-Contains $v2Output "2026.09.22.2__pending" "Schema-v2 metadata omitted the pending id."
    Assert-Contains $v2Output 'Automatic migration application: enabled' 'Missing auto-apply setting did not default to enabled.'
    Assert-Contains $v2Output 'absent; default=true' 'Default policy evidence was omitted.'
    Assert-Contains $v2Output 'Required agent action: apply pending accepted migrations now' 'Checker stopped at availability instead of handing off application.'
    Assert-Contains $v2Output "Migration source: $(Join-Path $v2.Source 'migrations')" 'Agent cannot resolve migration instructions.'
    if ((Get-Content $v2Path -Raw | ConvertFrom-Json).instruction_kit_version -ne '2026.09.22.1') {
        throw 'Checking updates advanced metadata before file application.'
    }

    # Exercise the real builder/checker handoff in an isolated project.
    New-Item -ItemType Directory -Path (Join-Path $v2.Project 'config') -Force | Out-Null
    Copy-Item $builderPath, $resolverPath -Destination (Join-Path $v2.Project 'tools')
    [void](New-Item -ItemType Directory -Path (Join-Path $v2.Project 'patterns/AGENTS_RUNTIME') -Force)
    Copy-Item -LiteralPath (Join-Path $repoRoot 'patterns/AGENTS_RUNTIME/03-rule-precedence.md') -Destination (Join-Path $v2.Project 'patterns/AGENTS_RUNTIME/03-rule-precedence.md')
    Copy-Item $updaterTemplate -Destination (Join-Path $v2.Project 'tools/check-instruction-kit-updates.ps1')
    Copy-Item $budgetPath -Destination (Join-Path $v2.Project 'config/gi-context-budgets.json')
    '{"routes":[{"id":"fixture","aliases":["gi fixture"],"contract":"Update handoff fixture","context_files":[]}]}' |
        Set-Content (Join-Path $v2.Project 'config/gi-command-routes.json')
    $v2Metadata = Get-Content $v2Path -Raw | ConvertFrom-Json
    $v2Metadata.update_check | Add-Member -NotePropertyName shared_library_path -NotePropertyValue $v2.Source
    $v2Metadata | ConvertTo-Json -Depth 8 | Set-Content $v2Path
    $handoff = (& (Join-Path $v2.Project 'tools/get-gi-context.ps1') -CommandText 'gi fixture' *>&1 | Out-String)
    Assert-Contains $handoff 'Required agent action: apply pending accepted migrations now' 'Context builder lost automatic application handoff.'
    Assert-Contains $handoff 'Automatic migration application: enabled' 'Context builder lost policy evidence.'
    Assert-Contains $handoff 'verify installation separately from host activation' 'Context builder lost the installation/runtime boundary.'
    Assert-Contains $handoff 'Codex trust/CLI/Desktop checks are Codex-only; OpenCode plugin/response-loop checks are OpenCode-only.' 'Context builder lost host applicability.'
    Assert-Contains $handoff "Read accepted applicability contract: $(Join-Path $v2.Source 'migrations/README.md')" 'Historical migrations lack an authoritative applicability contract.'
    Assert-Contains $handoff 'whole batch including later host adapters' 'Handoff can still stop before a later host adapter.'

    foreach ($policyCase in @(
        @{ Name = 'explicit-on'; Json = '{"enabled":true,"auto_apply_pending_migrations":true}'; Expected = 'auto_apply_pending_migrations=true' },
        @{ Name = 'explicit-off'; Json = '{"enabled":true,"auto_apply_pending_migrations":false}'; Expected = 'auto_apply_pending_migrations=false' },
        @{ Name = 'check-off'; Json = '{"enabled":false}'; Expected = 'update_check.enabled=false' }
    )) {
        $policyFixture = New-UpdateFixture -Name $policyCase.Name -MetadataJson ('{"instruction_kit_version":"2026.09.22.1","applied_migrations":["2026.09.22.1__already"],"update_check":' + $policyCase.Json + '}')
        $policyPath = Join-Path $policyFixture.Project 'tools/project-memory/instruction-kit.json'
        $beforePolicy = [IO.File]::ReadAllText($policyPath)
        $policyOutput = (& $updaterTemplate -InstructionKitPath $policyPath -SharedLibraryPath $policyFixture.Source *>&1 | Out-String)
        Assert-Contains $policyOutput $policyCase.Expected 'Policy report omitted the exact metadata value.'
        Assert-Contains $policyOutput $policyPath 'Policy report omitted its evidence path.'
        if ($policyCase.Name -ne 'explicit-on' -and $policyOutput.Contains('Required agent action: apply')) { throw 'Explicit opt-out still required automatic application.' }
        if ($policyCase.Name -eq 'check-off') { Assert-Contains $policyOutput 'Pending instruction migrations: unknown' 'Disabled check invented a pending count.' }
        if ([IO.File]::ReadAllText($policyPath) -cne $beforePolicy) { throw 'Policy check changed migration state.' }
    }
    foreach ($invalidPolicy in @('{"auto_apply_pending_migrations":"false"}', '{"enabled":null}')) {
        $invalid = New-UpdateFixture -Name ('invalid-' + [guid]::NewGuid().ToString('N')) -MetadataJson ('{"instruction_kit_version":"2026.09.22.1","update_check":' + $invalidPolicy + '}')
        $policyFailure = ''
        try { & $updaterTemplate -InstructionKitPath (Join-Path $invalid.Project 'tools/project-memory/instruction-kit.json') -SharedLibraryPath $invalid.Source *> $null }
        catch { $policyFailure = $_.ToString() }
        Assert-Contains $policyFailure 'expected a JSON boolean' 'Invalid policy was silently interpreted.'
    }
    $noPolicy = New-UpdateFixture -Name 'no-policy' -MetadataJson '{"instruction_kit_version":"2026.09.22.1","applied_migrations":["2026.09.22.1__already"]}'
    $noPolicyOutput = (& $updaterTemplate -InstructionKitPath (Join-Path $noPolicy.Project 'tools/project-memory/instruction-kit.json') -SharedLibraryPath $noPolicy.Source *>&1 | Out-String)
    Assert-Contains $noPolicyOutput 'Required agent action: apply pending accepted migrations now' 'Legacy metadata without update_check lost automatic application.'

    $applyNotice = (& $updaterTemplate -InstructionKitPath $v2Path -SharedLibraryPath $v2.Source -Apply *>&1 | Out-String)
    if ($LASTEXITCODE -ne 1) { throw 'Unsupported helper -Apply did not fail safely.' }
    Assert-Contains $applyNotice 'Automatic migration application: enabled' 'Helper limitation changed the reported policy.'
    Assert-Contains $applyNotice 'does not disable the automatic application policy' 'Helper limitation was presented as an opt-out.'
    Assert-Contains $applyNotice 'unavailable runtime checks do not block installed migrations' 'Legacy -Apply handoff lost host applicability.'
    if ((Get-Content $v2Path -Raw | ConvertFrom-Json).instruction_kit_version -ne '2026.09.22.1') { throw 'Unsupported -Apply advanced metadata.' }
    $missingSource = New-UpdateFixture -Name 'missing-migrations' -WithoutMigrations -MetadataJson '{"instruction_kit_version":"2026.09.22.1","update_check":{"enabled":true}}'
    $missingFailure = ''
    try { & $updaterTemplate -InstructionKitPath (Join-Path $missingSource.Project 'tools/project-memory/instruction-kit.json') -SharedLibraryPath $missingSource.Source *> $null }
    catch { $missingFailure = $_.ToString() }
    Assert-Contains $missingFailure 'Pending instruction migrations: unknown' 'Missing migration source was reported as zero pending.'

    & $updaterTemplate -InstructionKitPath $v2Path -SharedLibraryPath $v2.Source -RecordApplied *>&1 | Out-Null
    $recorded = Get-Content -LiteralPath $v2Path -Raw | ConvertFrom-Json
    if ($recorded.migration_state.applied_through -ne "2026.09.22.2__pending") {
        throw "Recording did not advance the schema-v2 checkpoint."
    }
    if ($recorded.PSObject.Properties.Name -contains "applied_migrations") {
        throw "Recording retained the legacy migration array."
    }
    $afterRecording = (& $updaterTemplate -InstructionKitPath $v2Path -SharedLibraryPath $v2.Source *>&1 | Out-String)
    Assert-Contains $afterRecording 'Pending instruction migrations: 0' 'Verified recording did not complete the update flow.'

    # Recover the reported historical batch using the public checker, without
    # native host APIs. File installation is verified by the caller; recording
    # must neither probe host trust nor turn unverified runtime evidence into success.
    $recovery = New-UpdateFixture -Name 'host-recovery' -MetadataJson `
        '{"instruction_kit_version":"2026.10.24.5","migration_state":{"schema_version":2,"applied_through":"2026.10.24.5__forward_mandatory_rules_with_service_messages","additional_applied_migrations":[],"skipped_migrations":["2026.10.24.4__automate_mandatory_lifecycle_hooks","2026.10.24.5__forward_mandatory_rules_with_service_messages"]},"update_check":{"enabled":true},"project_runtime_evidence":{"codex":"unverified: trust unavailable","opencode":"unverified: reload required"}}'
    $recoveryPath = Join-Path $recovery.Project 'tools/project-memory/instruction-kit.json'
    $batch = @(
        '2026.10.24.4__automate_mandatory_lifecycle_hooks',
        '2026.10.24.5__forward_mandatory_rules_with_service_messages',
        '2026.10.25.1__add_opencode_gi_lifecycle_hooks',
        '2026.10.25.2__separate_migration_installation_from_host_activation'
    )
    foreach ($id in $batch) {
        Copy-Item -LiteralPath (Join-Path $repoRoot "migrations/$id.md") -Destination (Join-Path $recovery.Source "migrations/$id.md")
    }
    [System.IO.File]::WriteAllText((Join-Path $recovery.Source 'VERSION.md'), 'Current accepted version: `2026.10.25.2`')
    $beforeRecovery = [System.IO.File]::ReadAllText($recoveryPath)
    $recoveryNotice = (& $updaterTemplate -InstructionKitPath $recoveryPath -SharedLibraryPath $recovery.Source *>&1 | Out-String)
    Assert-Contains $recoveryNotice 'Pending instruction migrations: 4' 'Skipped historical migrations and later adapters did not form one pending batch.'
    foreach ($id in $batch) { Assert-Contains $recoveryNotice "- $id" 'Recovery lost a pending migration.' }
    if ([System.IO.File]::ReadAllText($recoveryPath) -cne $beforeRecovery) { throw 'Recovery check prematurely recorded installation or changed runtime evidence.' }
    & $updaterTemplate -InstructionKitPath $recoveryPath -SharedLibraryPath $recovery.Source -RecordApplied *>&1 | Out-Null
    $recovered = Get-Content -LiteralPath $recoveryPath -Raw | ConvertFrom-Json
    if ($recovered.instruction_kit_version -ne '2026.10.25.2' -or
        $recovered.migration_state.applied_through -ne $batch[-1] -or
        @($recovered.migration_state.skipped_migrations).Count -ne 0) { throw 'Verified recovery did not record the entire pending batch.' }
    if ($recovered.project_runtime_evidence.codex -cne 'unverified: trust unavailable' -or
        $recovered.project_runtime_evidence.opencode -cne 'unverified: reload required') { throw 'Recording installation fabricated or erased runtime readiness.' }
    $recoveryAfter = (& $updaterTemplate -InstructionKitPath $recoveryPath -SharedLibraryPath $recovery.Source *>&1 | Out-String)
    Assert-Contains $recoveryAfter 'Pending instruction migrations: 0' 'Unverified host activation kept installed migrations pending.'

    $exceptions = New-UpdateFixture -Name "exceptions" -MetadataJson `
        '{"instruction_kit_version":"2026.09.22.1","migration_state":{"schema_version":2,"applied_through":"2026.09.22.1__already","additional_applied_migrations":["2026.09.22.2__pending"],"skipped_migrations":["2026.09.22.1__already"]},"update_check":{"enabled":true}}'
    $exceptionOutput = (& $updaterTemplate -InstructionKitPath (Join-Path $exceptions.Project "tools/project-memory/instruction-kit.json") -SharedLibraryPath $exceptions.Source *>&1 | Out-String)
    Assert-Contains $exceptionOutput "Pending instruction migrations: 1" "Migration-state exceptions were not applied."
    Assert-Contains $exceptionOutput "- 2026.09.22.1__already" "Explicit skipped migration was not returned as pending."
    if ($exceptionOutput.Contains("- 2026.09.22.2__pending")) {
        throw "Explicit additional applied migration was returned as pending."
    }

    $equalSkipped = New-UpdateFixture -Name "equal-skipped" -MetadataJson `
        '{"instruction_kit_version":"2026.09.22.2","migration_state":{"schema_version":2,"applied_through":"2026.09.22.2__pending","additional_applied_migrations":[],"skipped_migrations":["2026.09.22.2__pending"]},"update_check":{"enabled":true}}'
    $equalSkippedOutput = (& $updaterTemplate -InstructionKitPath (Join-Path $equalSkipped.Project "tools/project-memory/instruction-kit.json") -SharedLibraryPath $equalSkipped.Source *>&1 | Out-String)
    Assert-Contains $equalSkippedOutput "Pending instruction migrations: 1" "Equal-version fast path ignored an explicit skipped migration."
    Assert-Contains $equalSkippedOutput "2026.09.22.2__pending" "Equal-version skipped migration id was omitted."

    $semanticSource = Join-Path $testRoot "semantic-source"
    $semanticProject = Join-Path $testRoot "semantic-project"
    [void](New-Item -ItemType Directory -Path (Join-Path $semanticSource "migrations") -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $semanticProject "tools/project-memory") -Force)
    [System.IO.File]::WriteAllText((Join-Path $semanticSource "VERSION.md"), 'Current accepted version: `2026.09.22.10`', [System.Text.UTF8Encoding]::new($false))
    foreach ($id in @("2026.09.22.9__old", "2026.09.22.10__new")) {
        [System.IO.File]::WriteAllText((Join-Path $semanticSource "migrations/$id.md"), "# $id", [System.Text.UTF8Encoding]::new($false))
    }
    $semanticMetadataPath = Join-Path $semanticProject "tools/project-memory/instruction-kit.json"
    [System.IO.File]::WriteAllText(
        $semanticMetadataPath,
        '{"instruction_kit_version":"2026.09.22.9","migration_state":{"schema_version":2,"applied_through":"2026.09.22.9__old","additional_applied_migrations":[],"skipped_migrations":[]},"update_check":{"enabled":true}}',
        [System.Text.UTF8Encoding]::new($false)
    )
    $semanticOutput = (& $updaterTemplate -InstructionKitPath $semanticMetadataPath -SharedLibraryPath $semanticSource *>&1 | Out-String)
    Assert-Contains $semanticOutput "Pending instruction migrations: 1" "Migration ids were not compared by semantic version."
    Assert-Contains $semanticOutput "2026.09.22.10__new" "Semantic migration ordering omitted version .10."
    if ($semanticOutput.Contains("- 2026.09.22.9__old")) { throw "Semantic migration ordering returned version .9 after checkpoint .9." }
    & $updaterTemplate -InstructionKitPath $semanticMetadataPath -SharedLibraryPath $semanticSource -RecordApplied *>&1 | Out-Null
    $semanticRecorded = Get-Content -LiteralPath $semanticMetadataPath -Raw | ConvertFrom-Json
    if ($semanticRecorded.migration_state.applied_through -ne "2026.09.22.10__new") {
        throw "Recording did not select the semantically latest migration id."
    }

    $legacy = New-UpdateFixture -Name "legacy" -MetadataJson `
        '{"instruction_kit_version":"2026.09.22.1","applied_migrations":["2026.09.22.1__already"],"update_check":{"enabled":true}}'
    $legacyOutput = (& $updaterTemplate -InstructionKitPath (Join-Path $legacy.Project "tools/project-memory/instruction-kit.json") -SharedLibraryPath $legacy.Source *>&1 | Out-String)
    Assert-Contains $legacyOutput "Pending instruction migrations: 1" "Legacy metadata compatibility failed."
    Assert-Contains $legacyOutput "2026.09.22.2__pending" "Legacy metadata omitted the pending id."

    # Exercise file limits and both builder caps through the public entrypoint.
    $newlineRoot = Join-Path $testRoot 'line-endings'
    foreach ($directory in @('tools', 'config', 'patterns/AGENTS_RUNTIME', 'tools/project-memory')) {
        [void](New-Item -ItemType Directory -Path (Join-Path $newlineRoot $directory) -Force)
    }
    Copy-Item -LiteralPath $builderPath -Destination (Join-Path $newlineRoot 'tools/get-gi-context.ps1')
    Copy-Item -LiteralPath $resolverPath -Destination (Join-Path $newlineRoot 'tools/resolve-gi-command.ps1')
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $fixtureRulesPath = Join-Path $newlineRoot 'patterns/AGENTS_RUNTIME/03-rule-precedence.md'
    $fixtureRules = "## Simplicity And Material Complexity`nAgree material complexity first.`n## Whole-Task Completion Gate`nVerify all requirements and report gaps.`n"
    [System.IO.File]::WriteAllText($fixtureRulesPath, $fixtureRules, $utf8)
    $newlineManifest = '{"routes":[{"id":"start","aliases":["gi start"],"contract":"Line-ending fixture","context_files":["patterns/body.md"]}]}'
    [System.IO.File]::WriteAllText((Join-Path $newlineRoot 'config/gi-command-routes.json'), $newlineManifest, $utf8)
    $lfBody = "пример boundary`n" * 100
    $fileBytes = $utf8.GetByteCount($lfBody)
    $bodies = @($lfBody, $lfBody.Replace("`n", "`r`n"), ("пример boundary`r`nпример boundary`n" * 50))
    foreach ($cap in @(10000, 900)) {
        $newlineBudgets = @{ section_max_chars = 320; git_snapshot_max_chars = 4000; start_packet_max_chars = $cap; route_packet_default_max_chars = 36000; route_packet_overrides = @{} }
        [System.IO.File]::WriteAllText((Join-Path $newlineRoot 'config/gi-context-budgets.json'), ($newlineBudgets | ConvertTo-Json), $utf8)
        $expectedPacket = $null
        foreach ($body in $bodies) {
            foreach ($file in @('patterns/body.md', 'AGENTS.md')) {
                [System.IO.File]::WriteAllText((Join-Path $newlineRoot $file), $body, $utf8)
            }
            Assert-FileBudget -RelativePath 'AGENTS.md' -RootPath $newlineRoot -Maximum $fileBytes
            $rejected = $false
            try { Assert-FileBudget -RelativePath 'AGENTS.md' -RootPath $newlineRoot -Maximum ($fileBytes - 1) }
            catch { $rejected = $true }
            if (-not $rejected) { throw 'A real UTF-8 byte-budget overflow was accepted.' }
            $newlinePacket = (& (Join-Path $newlineRoot 'tools/get-gi-context.ps1') -CommandText 'gi start' -SkipUpdateCheck | Out-String).Replace("`r`n", "`n")
            Assert-Contains $newlinePacket $fixtureRules.TrimEnd() 'Truncation removed mandatory rules.'
            if ($null -eq $expectedPacket) { $expectedPacket = $newlinePacket }
            elseif ($newlinePacket -cne $expectedPacket) { throw 'LF, CRLF, and mixed inputs produced different bounded context.' }
            if ($newlinePacket.Length -gt $cap) { throw 'Normalized context exceeded its unchanged cap.' }
            if ($cap -eq 900) {
                if ($newlinePacket.Length -ne $cap) { throw 'The final packet cap has an off-by-one error.' }
                Assert-Contains $newlinePacket 'context packet truncated:' 'Missing final truncation marker.'
            }
            else { Assert-Contains $newlinePacket 'context truncated:' 'Missing section truncation marker.' }
        }
    }
    foreach ($phase in @('Work', 'Complete')) {
        $phasePacket = (& $builderPath -Phase $phase -SkipUpdateCheck | Out-String).Replace("`r`n", "`n")
        Assert-Contains $phasePacket $mandatoryRules "Phase $phase omitted mandatory rules."
        Assert-Contains $phasePacket "MANDATORY TASK RULES ($phase)" 'Missing phase identity.'
        if ($phasePacket.Length -gt [int]$budgets.route_packet_default_max_chars) { throw 'Phase context exceeded its unchanged budget.' }
    }
    $servicePacket = (& $builderPath -Phase Work -MandatoryOnly -CommandText 'not a GI route' | Out-String).Replace("`r`n", "`n").TrimEnd()
    if ($servicePacket -cne ("===== MANDATORY TASK RULES (Work) =====`n" + $mandatoryRules)) { throw 'Mandatory-only context omitted rules or included sender-specific state.' }
    $fixtureBuilder = Join-Path $newlineRoot 'tools/get-gi-context.ps1'
    [System.IO.File]::WriteAllText($fixtureRulesPath, $mandatoryRules, $utf8)
    [System.IO.File]::WriteAllText((Join-Path $newlineRoot 'tools/project-memory/verification-preferences.json'), '{"task_completion_review":{"enabled":false}}', $utf8)
    $newlineBudgets.route_packet_default_max_chars = 5000
    [System.IO.File]::WriteAllText((Join-Path $newlineRoot 'config/gi-context-budgets.json'), ($newlineBudgets | ConvertTo-Json), $utf8)
    foreach ($phase in @('Work', 'Complete')) {
        $phasePacket = (& $fixtureBuilder -Phase $phase -SkipUpdateCheck | Out-String).Replace("`r`n", "`n")
        Assert-Contains $phasePacket $mandatoryRules 'Optional review Off suppressed mandatory rules.'
    }
    $completionPacket = (& $fixtureBuilder -Phase Complete -CommandText 'not a GI route' | Out-String)
    if ($completionPacket.Contains('GI UPDATE STATUS') -or $completionPacket.Contains('GI ROUTE PACKET')) { throw 'Completion phase triggered startup or route work.' }
    foreach ($failure in @('missing', 'incomplete', 'too-large', 'too-small-budget')) {
        $fixtureText = switch ($failure) {
            'missing' { $null }
            'incomplete' { 'No mandatory sections here.' }
            'too-large' { $mandatoryRules + ("oversized rule`n" * 1000) }
            'too-small-budget' { $mandatoryRules }
        }
        if ($null -eq $fixtureText) { Remove-Item -LiteralPath $fixtureRulesPath }
        else { [System.IO.File]::WriteAllText($fixtureRulesPath, $fixtureText, $utf8) }
        if ($failure -eq 'too-small-budget') {
            $newlineBudgets.route_packet_default_max_chars = $mandatoryRules.Length - 1
            [System.IO.File]::WriteAllText((Join-Path $newlineRoot 'config/gi-context-budgets.json'), ($newlineBudgets | ConvertTo-Json), $utf8)
        }
        $emitted = [System.Collections.Generic.List[string]]::new()
        $rejected = $false
        try { & $fixtureBuilder -Phase Complete | ForEach-Object { $emitted.Add([string]$_) } }
        catch { $rejected = $true }
        if (-not $rejected -or $emitted.Count -ne 0) { throw "Unsafe partial rules packet accepted: $failure" }
    }
    Write-Output "GI routing, budgets, protected Work/Complete rules, migration-state, and line-ending checks passed."
}
finally {
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        $resolvedTestRoot = (Resolve-Path -LiteralPath $testRoot).Path
        $resolvedTempRoot = (Resolve-Path -LiteralPath ([System.IO.Path]::GetTempPath())).Path
        if (-not $resolvedTestRoot.StartsWith($resolvedTempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove test data outside the system temp directory: $resolvedTestRoot"
        }
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
