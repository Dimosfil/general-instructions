[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CommandText,
    [switch]$SkipUpdateCheck,
    [ValidateRange(1, 500)][int]$MaxSummaryLines = 80,
    [ValidateRange(1, 500)][int]$MaxStartupFileLines = 80,
    [ValidateRange(1, 200)][int]$MaxRunbookHintLines = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$resolverPath = Join-Path $projectRoot "tools/resolve-gi-command.ps1"
$metadataPath = Join-Path $projectRoot "tools/project-memory/instruction-kit.json"
$checkerCandidates = @(
    (Join-Path $projectRoot "tools/check-instruction-kit-updates.ps1"),
    (Join-Path $projectRoot "templates/check-instruction-kit-updates.template.ps1")
)

if (-not (Test-Path -LiteralPath $resolverPath -PathType Leaf)) {
    throw "GI command resolver is missing: $resolverPath"
}

function Write-BoundedFileSection {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][int]$Limit
    )

    $fullPath = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { return }

    Write-Output ""
    Write-Output ("===== {0} =====" -f $Title)
    $lineCount = (Get-Content -LiteralPath $fullPath | Measure-Object -Line).Lines
    if ($lineCount -gt $Limit) {
        Write-Output ("{0} has {1} lines; showing first {2} lines only." -f $RelativePath, $lineCount, $Limit)
    }
    Get-Content -LiteralPath $fullPath -TotalCount $Limit
}

function Write-GitCommitPreferences {
    Write-Output ""
    Write-Output "===== GIT COMMIT PREFERENCES ====="
    $relativePath = "tools/project-memory/git-preferences.json"
    $fullPath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Write-Output "No git commit language preferences found."
        Write-Output "Default: English; configure with tools/select-git-commit-languages.ps1"
        return
    }

    try {
        $preferences = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
        $primary = [string]$preferences.commit_message_languages.primary
        $additional = @($preferences.commit_message_languages.additional | ForEach-Object { [string]$_ })
        if (-not $primary) { $primary = "English" }
        Write-Output ("Primary: {0}" -f $primary)
        Write-Output ("Additional: {0}" -f $(if ($additional.Count) { $additional -join ", " } else { "none" }))
        Write-Output "Change with: tools/select-git-commit-languages.ps1"
    }
    catch {
        Write-Output ("Could not read {0}; reconfigure with tools/select-git-commit-languages.ps1" -f $relativePath)
    }
}

function Write-SystemLanguagePreferences {
    Write-Output ""
    Write-Output "===== AGENT SYSTEM LANGUAGE ====="
    $relativePath = "tools/project-memory/system-preferences.json"
    $fullPath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Write-Output "Agent working language: match the user's language"
        Write-Output "Configure with: tools/select-system-language.ps1"
        return
    }

    try {
        $preferences = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
        $response = $preferences.agent_response_language
        $mode = [string]$response.mode
        $language = [string]$response.language
        $languages = @($response.project_environment_languages | ForEach-Object { [string]$_ })
        if ($languages.Count -eq 0) {
            $languages = @($response.languages | ForEach-Object { [string]$_ })
        }
        $taskLanguages = @($response.task_languages | ForEach-Object { [string]$_ })
        if ($mode -eq "fixed" -and $languages.Count -gt 0) {
            Write-Output ("Project working environment: {0}" -f ($languages -join ", "))
            if ($taskLanguages.Count -gt 0) {
                Write-Output ("Tasks: {0}" -f ($taskLanguages -join ", "))
            }
        }
        elseif ($mode -eq "fixed" -and $language) {
            Write-Output ("Agent working language: {0}" -f $language)
        }
        else {
            Write-Output "Agent working language: match the user's language"
        }
        Write-Output "Change with: tools/select-system-language.ps1"
    }
    catch {
        Write-Output ("Could not read {0}; reconfigure with tools/select-system-language.ps1" -f $relativePath)
    }
}

Write-Output "===== GI UPDATE STATUS ====="
if ($SkipUpdateCheck) {
    Write-Output "Instruction update check: skipped by caller"
}
elseif (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    Write-Output "Instruction update check: metadata missing at tools/project-memory/instruction-kit.json"
}
else {
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    $updateEnabled = -not (
        $metadata.update_check -and
        ($metadata.update_check.PSObject.Properties.Name -contains "enabled") -and
        $metadata.update_check.enabled -eq $false
    )
    if (-not $updateEnabled) {
        Write-Output "Instruction update check: disabled by metadata"
    }
    else {
        $checkerPath = $checkerCandidates | Where-Object {
            Test-Path -LiteralPath $_ -PathType Leaf
        } | Select-Object -First 1
        if (-not $checkerPath) {
            throw "Instruction update checker is missing."
        }
        Push-Location $projectRoot
        try {
            & $checkerPath -InstructionKitPath $metadataPath
        }
        finally {
            Pop-Location
        }
    }
}

Write-Output ""
Write-Output "===== GI ROUTE PACKET ====="
$routeHeader = (& $resolverPath -CommandText $CommandText -PathsOnly | Out-String)
$routeMatch = [regex]::Match($routeHeader, '(?m)^GI route:\s*(?<id>[^\r\n]+)')
if (-not $routeMatch.Success) {
    throw "GI resolver did not return a route id."
}
$routeId = $routeMatch.Groups['id'].Value.Trim()
& $resolverPath -CommandText $CommandText

if ($routeId -eq "start") {
    Write-BoundedFileSection -RelativePath "AGENTS.md" -Title "PROJECT ENTRYPOINT" -Limit $MaxStartupFileLines
    Write-BoundedFileSection -RelativePath "tools/AGENT_WORKING_AGREEMENTS.md" -Title "WORKING AGREEMENTS" -Limit $MaxStartupFileLines
    Write-GitCommitPreferences
    Write-SystemLanguagePreferences

    Write-Output ""
    Write-Output "===== LATEST HANDOFF SUMMARY ====="
    $summaryDirectory = Join-Path $projectRoot "tools/summary"
    $latestSummary = if (Test-Path -LiteralPath $summaryDirectory -PathType Container) {
        Get-ChildItem -LiteralPath $summaryDirectory -File -Filter "*_AGENT_WORK_SUMMARY.md" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    }
    else {
        $null
    }
    if ($latestSummary) {
        Write-Output ("Summary file: tools/summary/{0}" -f $latestSummary.Name)
        Get-Content -LiteralPath $latestSummary.FullName -TotalCount $MaxSummaryLines
    }
    else {
        Write-Output "No handoff summary found."
    }

    Write-Output ""
    Write-Output "===== GIT SNAPSHOT ====="
    if (Test-Path -LiteralPath (Join-Path $projectRoot ".git")) {
        git -c core.autocrlf=false -C $projectRoot status --short --branch
        git -c core.autocrlf=false -C $projectRoot diff --stat
    }
    else {
        Write-Output "No Git worktree found at the project root."
    }

    $runbookPath = Join-Path $projectRoot "tools/AGENT_RUNBOOK.md"
    if (Test-Path -LiteralPath $runbookPath -PathType Leaf) {
        Write-Output ""
        Write-Output "===== RUNBOOK COMMAND HINTS ====="
        Select-String -Path $runbookPath -Pattern "```|Install|Run|Test|Build|Smoke|Logs|powershell|npm|pnpm|yarn|dotnet|pytest|cargo|go test" -CaseSensitive:$false |
            Select-Object -First $MaxRunbookHintLines |
            ForEach-Object { $_.Line }
    }

    $projectMemorySearch = Join-Path $projectRoot "tools/project-memory/index_project.py"
    if (Test-Path -LiteralPath $projectMemorySearch -PathType Leaf) {
        Write-Output ""
        Write-Output "===== PROJECT MEMORY ====="
        Write-Output "Search memory with:"
        Write-Output 'python .\tools\project-memory\index_project.py search "query" --limit 10'
    }

    Write-Output ""
    Write-Output "Startup restore complete. Use targeted searches before reading large files."
}
