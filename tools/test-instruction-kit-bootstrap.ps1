[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$installer = Join-Path $repoRoot "tools/install-instruction-kit.ps1"
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("gi-bootstrap-test-" + [guid]::NewGuid().ToString("N"))
$forms = @(
    "https://github.com/Dimosfil/general-instructions.git",
    "Dimosfil/general-instructions.git",
    "[Dimosfil/general-instructions.git](https://github.com/Dimosfil/general-instructions.git)",
    $repoRoot
)
$requiredFiles = @(
    "AGENTS.md",
    "COMMANDS.md",
    "config/gi-command-routes.json",
    "config/gi-context-budgets.json",
    "tools/AGENT_WORKING_AGREEMENTS.md",
    "tools/AGENT_RUNBOOK.md",
    "tools/agent-start.ps1",
    "tools/get-gi-context.ps1",
    "tools/resolve-gi-command.ps1",
    "tools/project-memory/instruction-kit.json",
    "tools/project-memory/rag-system.json",
    "tools/project-memory/code_intelligence.py",
    "patterns/CODE_INTELLIGENCE_ADAPTERS.md",
    "patterns/GI_COMMAND_CONTRACTS.md",
    "patterns/AGENTS_RUNTIME/07-startup.md",
    "patterns/AGENTS_RUNTIME/07-scope-and-evidence.md",
    "patterns/AGENTS_RUNTIME/08-config-service.md",
    "patterns/AGENTS_RUNTIME/08-task-manager.md",
    "patterns/AGENTS_RUNTIME/08-sprint.md",
    "patterns/AGENTS_RUNTIME/09-production.md",
    "patterns/AGENTS_RUNTIME/09-deploy-gateway.md",
    "patterns/AGENTS_RUNTIME/09-ftp.md",
    "patterns/AGENTS_RUNTIME/09-runtime-and-defaults.md",
    "patterns/AGENTS_RUNTIME/09-testing.md",
    "patterns/AGENTS_RUNTIME/09-build-and-install.md",
    "patterns/AGENTS_RUNTIME/09-project-memory-operations.md"
)

try {
    [void](New-Item -ItemType Directory -Path $testRoot)
    for ($index = 0; $index -lt $forms.Count; $index++) {
        $target = Join-Path $testRoot ("case-" + $index)
        [void](New-Item -ItemType Directory -Path $target)

        if ($index -eq 2) {
            [System.IO.File]::WriteAllText(
                (Join-Path $target "AGENTS.md"),
                "# Existing project instructions",
                [System.Text.UTF8Encoding]::new($false)
            )
        }

        & $installer -Source $forms[$index] -SourceRoot $repoRoot -TargetPath $target | Out-Null

        foreach ($requiredFile in $requiredFiles) {
            $requiredPath = Join-Path $target $requiredFile
            if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
                throw "Bootstrap form '$($forms[$index])' did not create '$requiredFile'."
            }
        }
        if (Test-Path -LiteralPath (Join-Path $target ".git")) {
            throw "Bootstrap form '$($forms[$index])' created a Git repository."
        }
        if ($index -eq 2) {
            $agentsText = [System.IO.File]::ReadAllText((Join-Path $target "AGENTS.md"))
            if ($agentsText -ne "# Existing project instructions") {
                throw "The installer overwrote existing project instructions."
            }
        }

        $metadata = Get-Content -Raw -LiteralPath (Join-Path $target "tools/project-memory/instruction-kit.json") | ConvertFrom-Json
        if ($metadata.update_check.source_repo -ne "https://github.com/Dimosfil/general-instructions.git") {
            throw "Bootstrap form '$($forms[$index])' did not record the canonical source repository."
        }
        if ($metadata.update_check.auto_apply_pending_migrations -ne $true) {
            throw "Bootstrap form '$($forms[$index])' did not enable startup migration auto-application."
        }
        if ($metadata.config_service.enabled -ne $false) {
            throw "Bootstrap form '$($forms[$index])' did not default config-service integration to off."
        }
        if ($metadata.migration_state.schema_version -ne 2) {
            throw "Bootstrap form '$($forms[$index])' did not install migration-state schema v2."
        }
        if ($metadata.migration_state.applied_through -ne '2026.09.22.3__restore_lazy_startup_context') {
            throw "Bootstrap form '$($forms[$index])' did not record the accepted migration checkpoint."
        }
        if ($metadata.PSObject.Properties.Name -contains 'applied_migrations') {
            throw "Bootstrap form '$($forms[$index])' retained the legacy migration array."
        }

        $ragConfig = Get-Content -Raw -LiteralPath (Join-Path $target "tools/project-memory/rag-system.json") | ConvertFrom-Json
        if ($ragConfig.code_intelligence.enabled -ne $false) {
            throw "Bootstrap form '$($forms[$index])' did not default code intelligence to off."
        }

        $configRuleText = [System.IO.File]::ReadAllText(
            (Join-Path $target "patterns/AGENTS_RUNTIME/08-config-service.md")
        )
        $commandsText = [System.IO.File]::ReadAllText((Join-Path $target "COMMANDS.md"))
        foreach ($needle in @(
            'config_service.enabled',
            'Fresh GI bootstraps must create',
            'gi config on',
            'gi config off'
        )) {
            if (-not (($configRuleText + "`n" + $commandsText).Contains($needle))) {
                throw "Bootstrap form '$($forms[$index])' is missing config-service toggle rule text: $needle"
            }
        }

        $startupRuleText = [System.IO.File]::ReadAllText(
            (Join-Path $target "patterns/AGENTS_RUNTIME/07-startup.md")
        )
        foreach ($needle in @(
            'update_check.enabled: true',
            'auto_apply_pending_migrations',
            'Finding a newer version is not a completed startup',
            'If the versions are equal',
            'without reading `CHANGELOG.md`'
        )) {
            if (-not $startupRuleText.Contains($needle)) {
                throw "Bootstrap form '$($forms[$index])' is missing startup auto-application rule text: $needle"
            }
        }

        $agentStartText = [System.IO.File]::ReadAllText((Join-Path $target "tools/agent-start.ps1"))
        if (-not $agentStartText.Contains('tools/get-gi-context.ps1')) {
            throw "Bootstrap form '$($forms[$index])' did not delegate startup to the one-call context builder."
        }

        $resolverOutput = (& (Join-Path $target "tools/resolve-gi-command.ps1") `
            -CommandText "gi start sprint" -PathsOnly | Out-String)
        if (-not $resolverOutput.Contains("GI route: start-sprint")) {
            throw "Bootstrap form '$($forms[$index])' did not install a working longest-prefix GI resolver."
        }

        $summaryDirectory = Join-Path $target "tools/summary"
        $olderSummaryPath = Join-Path $summaryDirectory "2026-09-20_OLDER_AGENT_WORK_SUMMARY.md"
        $newerSummaryPath = Join-Path $summaryDirectory "2026-09-21_NEWER_AGENT_WORK_SUMMARY.md"
        $ignoredSummaryPath = Join-Path $summaryDirectory "9999-12-31_IGNORED.md"
        [System.IO.File]::WriteAllText($olderSummaryPath, "OLDER SUMMARY", [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText($newerSummaryPath, "NEWER SUMMARY", [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText($ignoredSummaryPath, "IGNORED SUMMARY", [System.Text.UTF8Encoding]::new($false))
        (Get-Item -LiteralPath $olderSummaryPath).LastWriteTime = (Get-Date).AddHours(-2)
        (Get-Item -LiteralPath $newerSummaryPath).LastWriteTime = (Get-Date).AddHours(-1)
        (Get-Item -LiteralPath $ignoredSummaryPath).LastWriteTime = Get-Date
        [System.IO.File]::WriteAllText(
            (Join-Path $target "tools/project-memory/index_project.py"),
            "# startup hint fixture",
            [System.Text.UTF8Encoding]::new($false)
        )

        Push-Location $testRoot
        try {
            $contextOutput = (& (Join-Path $target "tools/get-gi-context.ps1") `
                -CommandText "gi start" -SkipUpdateCheck | Out-String)
        }
        finally {
            Pop-Location
        }
        foreach ($needle in @(
            "GI route: start",
            "===== PROJECT ENTRYPOINT =====",
            "===== WORKING AGREEMENTS =====",
            "showing first 80 lines only.",
            "===== GIT COMMIT PREFERENCES =====",
            "===== AGENT SYSTEM LANGUAGE =====",
            "===== LATEST HANDOFF SUMMARY =====",
            "NEWER SUMMARY",
            "===== GIT SNAPSHOT =====",
            "===== RUNBOOK COMMAND HINTS =====",
            "===== PROJECT MEMORY =====",
            "Startup restore complete."
        )) {
            if (-not $contextOutput.Contains($needle)) {
                throw "Bootstrap form '$($forms[$index])' context builder omitted: $needle"
            }
        }
        if ($contextOutput.Contains("IGNORED SUMMARY")) {
            throw "Bootstrap form '$($forms[$index])' selected an unrelated summary Markdown file."
        }
        $contextBudgets = Get-Content -LiteralPath (Join-Path $target "config/gi-context-budgets.json") -Raw | ConvertFrom-Json
        if ($contextOutput.Length -gt [int]$contextBudgets.start_packet_max_chars) {
            throw "Bootstrap form '$($forms[$index])' exceeded the installed start-packet budget: $($contextOutput.Length) chars."
        }

        $secretRuleText = [System.IO.File]::ReadAllText(
            (Join-Path $target "patterns/API_KEY_SECRET_SAFETY.md")
        )
        $workingAgreementsText = [System.IO.File]::ReadAllText(
            (Join-Path $target "tools/AGENT_WORKING_AGREEMENTS.md")
        )
        foreach ($needle in @(
            'but do not treat that fact',
            'mark only the affected authenticated operation blocked or unverified'
        )) {
            if (-not $secretRuleText.Contains($needle)) {
                throw "Bootstrap form '$($forms[$index])' is missing non-blocking secret rule text: $needle"
            }
        }
        if (-not $workingAgreementsText.Contains('Do not treat a credential pasted into chat as an automatic blocker')) {
            throw "Bootstrap form '$($forms[$index])' is missing the working-agreement secret rule."
        }

        $gitIgnorePath = Join-Path $target ".gitignore"
        $gitIgnoreBefore = [System.IO.File]::ReadAllText($gitIgnorePath)
        $metadata.PSObject.Properties.Remove("config_service")
        $metadataJson = $metadata | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText(
            (Join-Path $target "tools/project-memory/instruction-kit.json"),
            $metadataJson + [Environment]::NewLine,
            [System.Text.UTF8Encoding]::new($false)
        )
        & $installer -Source $forms[$index] -SourceRoot $repoRoot -TargetPath $target | Out-Null
        $gitIgnoreAfter = [System.IO.File]::ReadAllText($gitIgnorePath)
        if ($gitIgnoreAfter -ne $gitIgnoreBefore) {
            throw "Bootstrap form '$($forms[$index])' is not idempotent for .gitignore."
        }
        $legacyMetadata = Get-Content -Raw -LiteralPath (Join-Path $target "tools/project-memory/instruction-kit.json") | ConvertFrom-Json
        if ($legacyMetadata.PSObject.Properties.Name -contains "config_service") {
            throw "Bootstrap form '$($forms[$index])' changed a legacy project's absent config-service toggle."
        }
    }

    $readmeText = [System.IO.File]::ReadAllText((Join-Path $repoRoot "README.md"))
    $bootstrapText = [System.IO.File]::ReadAllText((Join-Path $repoRoot "BOOTSTRAP.md"))
    foreach ($needle in @(
        '[Dimosfil/general-instructions.git](https://github.com/Dimosfil/general-instructions.git)',
        'patterns/SHARED_INSTRUCTIONS_BOOTSTRAP.md',
        'never means ordinary `git init`'
    )) {
        if (-not ($readmeText + "`n" + $bootstrapText).Contains($needle)) {
            throw "Bootstrap entrypoint is missing required text: $needle"
        }
    }

    Write-Output "GI bootstrap contract checks passed for $($forms.Count) source forms."
} finally {
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        $resolvedTestRoot = (Resolve-Path -LiteralPath $testRoot).Path
        $resolvedTempRoot = (Resolve-Path -LiteralPath ([System.IO.Path]::GetTempPath())).Path
        if (-not $resolvedTestRoot.StartsWith($resolvedTempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove test data outside the system temp directory: $resolvedTestRoot"
        }
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
