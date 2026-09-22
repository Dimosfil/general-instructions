[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $repoRoot "config/gi-command-routes.json"
$resolverPath = Join-Path $repoRoot "tools/resolve-gi-command.ps1"
$updaterTemplate = Join-Path $repoRoot "templates/check-instruction-kit-updates.template.ps1"
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("gi-context-routing-" + [guid]::NewGuid().ToString("N"))

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Failure
    )

    if (-not $Text.Contains($Expected)) {
        throw $Failure
    }
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
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
        foreach ($relativePathValue in $route.context_files) {
            $relativePath = [string]$relativePathValue
            if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf)) {
                throw "Route '$($route.id)' references missing context file '$relativePath'."
            }
        }
    }

    $routeCases = @(
        @{ Command = "ги старт оптимизация подумать"; Route = "start" },
        @{ Command = "gi start sprint"; Route = "start-sprint" },
        @{ Command = "gi config service off"; Route = "config-self-registration" },
        @{ Command = "gi restart"; Route = "restart" },
        @{ Command = "gi error fix"; Route = "error-fix" },
        @{ Command = "gi tools rebuild vector"; Route = "rag-rebuild" },
        @{ Command = "gi only push"; Route = "git-finish" }
    )
    foreach ($case in $routeCases) {
        $output = (& $resolverPath -CommandText $case.Command -PathsOnly | Out-String)
        Assert-Contains -Text $output -Expected ("GI route: {0}" -f $case.Route) -Failure "Command '$($case.Command)' resolved to the wrong route."
    }

    $startOutput = (& $resolverPath -CommandText "ги старт новая задача" | Out-String)
    Assert-Contains -Text $startOutput -Expected "patterns/AGENTS_RUNTIME/07-startup-and-scope.md" -Failure "Start route omitted its startup module."
    if ($startOutput.Contains("GI Help / Command Index") -or $startOutput.Contains("09-project-operation-commands.md")) {
        throw "Start route loaded unrelated command-index or operation context."
    }

    $commandsLength = (Get-Item -LiteralPath (Join-Path $repoRoot "COMMANDS.md")).Length
    if ($commandsLength -gt 10000) {
        throw "COMMANDS.md exceeded the 10 KB compact-index budget: $commandsLength bytes."
    }

    [void](New-Item -ItemType Directory -Path $testRoot)
    $equalSource = Join-Path $testRoot "equal-source"
    $equalProject = Join-Path $testRoot "equal-project"
    [void](New-Item -ItemType Directory -Path $equalSource)
    [void](New-Item -ItemType Directory -Path (Join-Path $equalProject "tools/project-memory") -Force)
    [System.IO.File]::WriteAllText(
        (Join-Path $equalSource "VERSION.md"),
        "Current accepted version: ``2026.09.22.1``",
        [System.Text.UTF8Encoding]::new($false)
    )
    [System.IO.File]::WriteAllText(
        (Join-Path $equalProject "tools/project-memory/instruction-kit.json"),
        '{"instruction_kit_version":"2026.09.22.1","applied_migrations":[],"update_check":{"enabled":true}}',
        [System.Text.UTF8Encoding]::new($false)
    )

    $equalOutput = (& $updaterTemplate `
        -InstructionKitPath (Join-Path $equalProject "tools/project-memory/instruction-kit.json") `
        -SharedLibraryPath $equalSource *>&1 | Out-String)
    Assert-Contains -Text $equalOutput -Expected "Pending instruction migrations: 0" -Failure "Equal-version update check did not return the zero-pending fast path."
    if ($equalOutput.Contains("No migrations folder found")) {
        throw "Equal-version update check inspected the migrations directory."
    }

    $newerSource = Join-Path $testRoot "newer-source"
    $newerProject = Join-Path $testRoot "newer-project"
    [void](New-Item -ItemType Directory -Path (Join-Path $newerSource "migrations") -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $newerProject "tools/project-memory") -Force)
    [System.IO.File]::WriteAllText(
        (Join-Path $newerSource "VERSION.md"),
        "Current accepted version: ``2026.09.22.1``",
        [System.Text.UTF8Encoding]::new($false)
    )
    [System.IO.File]::WriteAllText(
        (Join-Path $newerSource "migrations/2026.09.22.1__test.md"),
        "# Test migration",
        [System.Text.UTF8Encoding]::new($false)
    )
    [System.IO.File]::WriteAllText(
        (Join-Path $newerProject "tools/project-memory/instruction-kit.json"),
        '{"instruction_kit_version":"2026.09.05.1","applied_migrations":[],"update_check":{"enabled":true}}',
        [System.Text.UTF8Encoding]::new($false)
    )

    $newerOutput = (& $updaterTemplate `
        -InstructionKitPath (Join-Path $newerProject "tools/project-memory/instruction-kit.json") `
        -SharedLibraryPath $newerSource *>&1 | Out-String)
    Assert-Contains -Text $newerOutput -Expected "Pending instruction migrations: 1" -Failure "Newer-version update check did not enumerate pending migrations."
    Assert-Contains -Text $newerOutput -Expected "2026.09.22.1__test" -Failure "Newer-version update check omitted the pending migration id."

    Write-Output "GI command routing and staged update checks passed."
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
