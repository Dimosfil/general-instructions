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
    "tools/select-task-verification.ps1",
    "tools/project-memory/verification-preferences.json",
    "AGENTS.md",
    "BOOTSTRAP.md",
    "COMMANDS.md",
    "config/gi-command-routes.json",
    "config/gi-context-budgets.json",
    "config/unity-mcp.json",
    "tools/ensure-unity-mcp.ps1",
    "tools/unity-mcp-router.mjs",
    "tools/verify-unity-mcp.mjs",
    "docs/unity-mcp-router.md",
    "tools/AGENT_WORKING_AGREEMENTS.md",
    "tools/AGENT_RUNBOOK.md",
    "tools/agent-start.ps1",
    "tools/get-gi-context.ps1",
    ".codex/hooks.json",
    ".opencode/plugins/gi-lifecycle.js",
    "docs/gi-opencode-hooks.md",
    "tools/invoke-gi-lifecycle-hook.ps1",
    "tools/resolve-gi-command.ps1",
    "tools/project-memory/instruction-kit.json",
    "tools/project-memory/rag-system.json",
    "tools/project-memory/code_intelligence.py",
    "patterns/CODE_INTELLIGENCE_ADAPTERS.md",
    "patterns/GI_COMMAND_CONTRACTS.md",
    "patterns/GIT_WORKFLOW.md",
    "patterns/ARCHITECTURE_AND_CODE_QUALITY.md",
    "patterns/SENIOR_AGENT_ENGINEERING_STANDARD.md",
    "patterns/COHERENT_BATCH_VERIFICATION.md",
    "patterns/MODULAR_SERVICE_ENGINEERING.md",
    "templates/SYSTEM_MAP.template.md",
    "templates/MODULE_PASSPORT.template.md",
    "templates/MODULE_CONTRACT.template.md",
    "templates/PROJECT_TESTING.template.md",
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
    "patterns/AGENTS_RUNTIME/09-full-testing.md",
    "patterns/AGENTS_RUNTIME/09-build-and-install.md",
    "patterns/AGENTS_RUNTIME/09-project-memory-operations.md",
    "patterns/AGENTS_RUNTIME/20-unity-projects.md"
)

try {
    [void](New-Item -ItemType Directory -Path $testRoot)
    for ($index = 0; $index -lt $forms.Count; $index++) {
        $target = Join-Path $testRoot ("case-" + $index)
        [void](New-Item -ItemType Directory -Path $target)

        if ($index -eq 2) {
            [void][System.IO.Directory]::CreateDirectory((Join-Path $target '.opencode/plugins'))
            [System.IO.File]::WriteAllText((Join-Path $target '.opencode/plugins/project-owned.js'), 'export default async () => ({})')
            [void][System.IO.Directory]::CreateDirectory((Join-Path $target '.codex'))
            [System.IO.File]::WriteAllText((Join-Path $target '.codex/hooks.json'),
                '{"description":"project-owned","hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo project-owned"}]}]}}')
            [System.IO.File]::WriteAllText(
                (Join-Path $target "AGENTS.md"),
                "# Existing project instructions",
                [System.Text.UTF8Encoding]::new($false)
            )
        }

        & $installer -Source $forms[$index] -SourceRoot $repoRoot -TargetPath $target | Out-Null
        if ($index -eq 2 -and [System.IO.File]::ReadAllText((Join-Path $target '.opencode/plugins/project-owned.js')) -cne 'export default async () => ({})') {
            throw 'Bootstrap replaced a project-owned OpenCode plugin.'
        }
        $nativeHooks = Get-Content -LiteralPath (Join-Path $target '.codex/hooks.json') -Raw | ConvertFrom-Json
        if ($index -eq 2 -and ($nativeHooks.description -ne 'project-owned' -or $nativeHooks.hooks.Stop[0].hooks[0].command -ne 'echo project-owned')) {
            throw 'Bootstrap replaced a project-owned hook.'
        }
        foreach ($name in @('UserPromptSubmit', 'SessionStart', 'PreToolUse', 'Stop')) {
            $giHandlers = @($nativeHooks.hooks.$name.hooks | Where-Object command -like '*invoke-gi-lifecycle-hook.ps1*')
            if ($giHandlers.Count -ne 1) { throw "Missing or duplicated native hook: $name" }
        }

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
            $projectText = ($agentsText -replace '(?s)\s*<!--gi-->.*?<!--/gi-->\s*', '')
            if ($projectText -ne "# Existing project instructions") {
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
        $acceptedVersionText = [System.IO.File]::ReadAllText((Join-Path $repoRoot "VERSION.md"))
        $acceptedVersion = [regex]::Match($acceptedVersionText, '\d{4}\.\d{2}\.\d{2}\.\d+').Value
        if ($metadata.instruction_kit_version -ne $acceptedVersion -or
            -not $metadata.migration_state.applied_through.StartsWith($acceptedVersion + '__')) {
            throw "Bootstrap form '$($forms[$index])' did not record the accepted migration checkpoint."
        }
        if ($metadata.PSObject.Properties.Name -contains 'applied_migrations') {
            throw "Bootstrap form '$($forms[$index])' retained the legacy migration array."
        }

        $mechanismFiles = @(
            "patterns/ARCHITECTURE_AND_CODE_QUALITY.md",
            "patterns/SENIOR_AGENT_ENGINEERING_STANDARD.md",
            "patterns/COHERENT_BATCH_VERIFICATION.md"
        )
        foreach ($relativePath in $mechanismFiles) {
            if ($metadata.copied_files -notcontains $relativePath) {
                throw "Bootstrap omitted mechanism-gate dependency from metadata: $relativePath"
            }
        }
        $architectureText = [System.IO.File]::ReadAllText((Join-Path $target $mechanismFiles[0]))
        foreach ($needle in @('## System Mechanism And Responsibility Gate',
            'scenario -> mechanism -> contract owner -> change location ->',
            'removal', 'side effects')) {
            if (-not $architectureText.Contains($needle)) {
                throw "Bootstrap omitted mechanism-gate contract: $needle"
            }
        }
        if ($index -ne 2) {
            $entryText = [System.IO.File]::ReadAllText((Join-Path $target "AGENTS.md"))
            if (-not $entryText.Contains('Before implementation, bug fixes, or refactoring, load modules 04, 06, and 15.')) {
                throw "Fresh entrypoint does not require the mechanism gate for ordinary implementation."
            }
        }
        $mechanismBeforeReinstall = [System.IO.File]::ReadAllText((Join-Path $target $mechanismFiles[0]))

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
            'stop the update check without reading'
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
        $installedManifest = Get-Content -Raw -LiteralPath (Join-Path $target "config/gi-command-routes.json") | ConvertFrom-Json
        foreach ($route in $installedManifest.routes) {
            $routeOutput = (& (Join-Path $target "tools/resolve-gi-command.ps1") `
                -CommandText ([string]$route.aliases[0]) -PathsOnly | Out-String)
            if (-not $routeOutput.Contains("GI route: $($route.id)")) {
                throw "Bootstrap form '$($forms[$index])' could not resolve installed route '$($route.id)'."
            }
        }

        $installedGitPacket = (& (Join-Path $target "tools/resolve-gi-command.ps1") `
            -CommandText "ги пуш всё" | Out-String)
        foreach ($needle in @(
            "Requested command: ги пуш всё",
            "explicit all-changes selection overrides active task scope",
            "command-defined scope also applies in a new chat",
            "still pushes existing outgoing commits",
            "An eligible selected remainder makes the finish incomplete"
        )) {
            if (-not $installedGitPacket.Contains($needle)) {
                throw "Bootstrap form '$($forms[$index])' lost Git finish contract: $needle"
            }
        }
        $installedGitWorkflow = [System.IO.File]::ReadAllText((Join-Path $target "patterns/GIT_WORKFLOW.md"))
        $sourceGitWorkflow = [System.IO.File]::ReadAllText((Join-Path $repoRoot "patterns/GIT_WORKFLOW.md"))
        if ($installedGitWorkflow -cne $sourceGitWorkflow -or
            $metadata.copied_files -notcontains "patterns/GIT_WORKFLOW.md") {
            throw "Bootstrap form '$($forms[$index])' did not copy and record the accepted Git workflow."
        }
        $installedAgreements = [System.IO.File]::ReadAllText((Join-Path $target "tools/AGENT_WORKING_AGREEMENTS.md"))
        foreach ($needle in @("ги пуш всё", "still push existing outgoing commits", "Eligible selected residue")) {
            if (-not $installedAgreements.Contains($needle)) {
                throw "Bootstrap form '$($forms[$index])' lost Git working agreement: $needle"
            }
        }

        $summaryDirectory = Join-Path $target "tools/summary"
        $olderSummaryPath = Join-Path $summaryDirectory "2026-09-20_OLDER_AGENT_WORK_SUMMARY.md"
        $newerSummaryPath = Join-Path $summaryDirectory "2026-09-21_NEWER_AGENT_WORK_SUMMARY.md"
        $ignoredSummaryPath = Join-Path $summaryDirectory "9999-12-31_IGNORED.md"
        [System.IO.File]::WriteAllText($olderSummaryPath, "OLDER SUMMARY", [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText($newerSummaryPath, ("NEWER SUMMARY " + ("x" * 50000)), [System.Text.UTF8Encoding]::new($false))
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
        $contextOutput = $contextOutput.Replace("`r`n", "`n")
        $installedRules = [System.IO.File]::ReadAllText((Join-Path $target 'patterns/AGENTS_RUNTIME/03-rule-precedence.md')).Replace("`r`n", "`n").TrimEnd()
        if (-not $contextOutput.Contains($installedRules)) { throw 'Installed work context omitted mandatory task rules.' }
        $installedEntry = [System.IO.File]::ReadAllText((Join-Path $target 'AGENTS.md'))
        if (-not $installedEntry.Contains('-Phase Complete')) { throw 'Installed entrypoint omitted completion-phase invocation.' }
        $completionContext = (& (Join-Path $target 'tools/get-gi-context.ps1') -Phase Complete | Out-String).Replace("`r`n", "`n")
        if (-not $completionContext.Contains($installedRules) -or $completionContext.Contains('GI UPDATE STATUS')) { throw 'Installed completion phase omitted rules or ran startup.' }
        if ($completionContext.Length -gt [int]$contextBudgets.route_packet_default_max_chars) { throw 'Installed completion phase exceeded its unchanged budget.' }
        $entryBeforeReinstall = [System.IO.File]::ReadAllText((Join-Path $target 'AGENTS.md'))
        $hooksBeforeReinstall = [System.IO.File]::ReadAllText((Join-Path $target '.codex/hooks.json'))
        $openCodeBeforeReinstall = [System.IO.File]::ReadAllText((Join-Path $target '.opencode/plugins/gi-lifecycle.js'))
        & $installer -Source $forms[$index] -SourceRoot $repoRoot -TargetPath $target | Out-Null
        if ([System.IO.File]::ReadAllText((Join-Path $target 'AGENTS.md')) -cne $entryBeforeReinstall) { throw 'Reinstall duplicated or changed the mandatory context block.' }
        if ([System.IO.File]::ReadAllText((Join-Path $target '.codex/hooks.json')) -cne $hooksBeforeReinstall) { throw 'Reinstall duplicated or changed lifecycle hooks.' }
        if ([System.IO.File]::ReadAllText((Join-Path $target '.opencode/plugins/gi-lifecycle.js')) -cne $openCodeBeforeReinstall) { throw 'Reinstall changed the OpenCode plugin.' }
        if ($contextOutput.Length -gt [int]$contextBudgets.start_packet_max_chars) {
            throw "Bootstrap form '$($forms[$index])' exceeded the installed start-packet budget: $($contextOutput.Length) chars."
        }
        if (-not $contextOutput.Contains("context truncated:")) {
            throw "Bootstrap form '$($forms[$index])' did not mark truncated oversized startup context."
        }

        if ($index -eq 0) {
            $pluginPath = Join-Path $target '.opencode/plugins/gi-lifecycle.js'
            [System.IO.File]::WriteAllText($pluginPath, '// Project-owned GI customization')
            $pluginRejected = $false
            try { & $installer -Source $forms[$index] -SourceRoot $repoRoot -TargetPath $target | Out-Null }
            catch { $pluginRejected = $_.Exception.Message.Contains('OpenCode GI plugin differs') }
            if (-not $pluginRejected -or [System.IO.File]::ReadAllText($pluginPath) -cne '// Project-owned GI customization') {
                throw 'Conflicting OpenCode plugin was overwritten or silently accepted.'
            }
            [System.IO.File]::WriteAllText($pluginPath, $openCodeBeforeReinstall)
            $legacyTarget = Join-Path $testRoot 'legacy-context-target'
            [void](New-Item -ItemType Directory -Path (Join-Path $legacyTarget 'tools') -Force)
            [System.IO.File]::WriteAllText((Join-Path $legacyTarget 'AGENTS.md'), '# Legacy project content', [System.Text.UTF8Encoding]::new($false))
            $legacyBuilder = Join-Path $legacyTarget 'tools/get-gi-context.ps1'
            [System.IO.File]::WriteAllText($legacyBuilder, 'param([string]$CommandText)', [System.Text.UTF8Encoding]::new($false))
            $legacyRejected = $false
            try { & $installer -SourceRoot $repoRoot -TargetPath $legacyTarget | Out-Null }
            catch { $legacyRejected = $_.Exception.Message.Contains('context-delivery migration') }
            if (-not $legacyRejected -or [System.IO.File]::ReadAllText((Join-Path $legacyTarget 'AGENTS.md')) -cne '# Legacy project content' -or
                [System.IO.File]::ReadAllText($legacyBuilder) -cne 'param([string]$CommandText)' -or
                (Test-Path -LiteralPath (Join-Path $legacyTarget 'tools/project-memory/instruction-kit.json'))) {
                throw 'Legacy files were overwritten or bootstrap falsely reported current context delivery.'
            }
            $budgetFile = Join-Path $target "config/gi-context-budgets.json"
            $budgetText = [System.IO.File]::ReadAllText($budgetFile)
            $tightBudgets = $budgetText | ConvertFrom-Json
            $tightBudgets.start_packet_max_chars = 5000
            [System.IO.File]::WriteAllText(
                $budgetFile,
                (($tightBudgets | ConvertTo-Json -Depth 100) + [Environment]::NewLine),
                [System.Text.UTF8Encoding]::new($false)
            )
            try {
                $tightContext = (& (Join-Path $target "tools/get-gi-context.ps1") -CommandText "gi start" -SkipUpdateCheck | Out-String)
            }
            finally {
                [System.IO.File]::WriteAllText($budgetFile, $budgetText, [System.Text.UTF8Encoding]::new($false))
            }
            $tightContext = $tightContext.Replace("`r`n", "`n")
            if (-not $tightContext.Contains($installedRules)) { throw 'Final startup cap removed mandatory task rules.' }
            if ($tightContext.Length -gt 5000) { throw "Final startup packet hard cap was not enforced." }
            if (-not $tightContext.Contains("context packet truncated:") -or -not $tightContext.Contains("Startup restore complete.")) {
                throw "Hard-capped startup packet omitted its truncation or completion marker."
            }

            & git -C $target init --quiet
            & git -C $target config core.autocrlf true
            $crlfFixture = Join-Path $target "crlf-fixture.txt"
            [System.IO.File]::WriteAllText($crlfFixture, "first`r`nsecond`r`n", [System.Text.UTF8Encoding]::new($false))
            & git -C $target add -- crlf-fixture.txt
            & git -C $target -c user.name="GI Test" -c user.email="gi-test@example.invalid" commit --quiet -m "Add CRLF fixture"
            $crlfContext = (& (Join-Path $target "tools/get-gi-context.ps1") -CommandText "gi start" -SkipUpdateCheck | Out-String)
            if ($crlfContext.Contains(" M crlf-fixture.txt") -or $crlfContext.Contains("crlf-fixture.txt |")) {
                throw "Context builder reported a clean CRLF file as modified."
            }

            $metadataPath = Join-Path $target "tools/project-memory/instruction-kit.json"
            $metadataBeforeFailureTest = [System.IO.File]::ReadAllText($metadataPath)
            $brokenSource = Join-Path $testRoot "broken-update-source"
            [void](New-Item -ItemType Directory -Path $brokenSource -Force)
            $failureMetadata = $metadataBeforeFailureTest | ConvertFrom-Json
            $failureMetadata.update_check.shared_library_path = $brokenSource
            $failureMetadata.update_check.source_repo = ""
            [System.IO.File]::WriteAllText(
                $metadataPath,
                (($failureMetadata | ConvertTo-Json -Depth 100) + [Environment]::NewLine),
                [System.Text.UTF8Encoding]::new($false)
            )
            $failureText = ""
            try {
                $failureText = (& (Join-Path $target "tools/get-gi-context.ps1") -CommandText "gi start" *>&1 | Out-String)
                throw "Context builder did not fail when the update check failed."
            }
            catch {
                $failureText = ($failureText + "`n" + $_.Exception.Message)
            }
            finally {
                [System.IO.File]::WriteAllText($metadataPath, $metadataBeforeFailureTest, [System.Text.UTF8Encoding]::new($false))
            }
            if (-not $failureText.Contains("Instruction update check failed")) {
                throw "Context builder did not propagate the update-check failure."
            }
            if ($failureText.Contains("Startup restore complete.")) {
                throw "Context builder reported startup completion after a failed update check."
            }
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
        if ([System.IO.File]::ReadAllText((Join-Path $target $mechanismFiles[0])) -ne $mechanismBeforeReinstall) {
            throw "Reinstall changed the already installed mechanism-gate contract."
        }
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
