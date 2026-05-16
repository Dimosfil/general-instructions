param(
    [int]$MaxLines = 160
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-InstructionKitVersion {
    param(
        [Parameter(Mandatory = $true)][string]$VersionFile
    )

    if (-not (Test-Path -LiteralPath $VersionFile)) {
        return $null
    }

    $match = Select-String -Path $VersionFile -Pattern '`([0-9]{4}\.[0-9]{2}\.[0-9]{2})`' | Select-Object -First 1
    if ($match -and $match.Matches.Count -gt 0) {
        return $match.Matches[0].Groups[1].Value
    }

    return $null
}

function Write-InstructionKitUpdateNotice {
    $provenancePath = "tools/project-memory/instruction-kit.json"
    if (-not (Test-Path -LiteralPath $provenancePath)) {
        return
    }

    try {
        $kit = Get-Content -LiteralPath $provenancePath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host ""
        Write-Host "== Instruction Kit =="
        Write-Host "Could not read $provenancePath; skipping update check."
        return
    }

    if ($kit.update_check -and $kit.update_check.PSObject.Properties.Name -contains "enabled" -and -not $kit.update_check.enabled) {
        return
    }

    $sharedPath = $null
    if ($kit.update_check -and $kit.update_check.shared_library_path) {
        $sharedPath = [string]$kit.update_check.shared_library_path
    }
    elseif ($env:GENERAL_INSTRUCTIONS_HOME) {
        $sharedPath = $env:GENERAL_INSTRUCTIONS_HOME
    }

    if (-not $sharedPath) {
        return
    }

    $sharedVersionFile = Join-Path $sharedPath "VERSION.md"
    $latestVersion = Get-InstructionKitVersion -VersionFile $sharedVersionFile
    if (-not $latestVersion) {
        return
    }

    $installedVersion = [string]$kit.instruction_kit_version
    $updateAvailable = $false
    if ($installedVersion) {
        try {
            $updateAvailable = ([version]$installedVersion) -lt ([version]$latestVersion)
        }
        catch {
            $updateAvailable = $installedVersion -ne $latestVersion
        }
    }

    if ($updateAvailable) {
        Write-Host ""
        Write-Host "== Instruction Kit Update =="
        Write-Host "Installed: $installedVersion"
        Write-Host "Available: $latestVersion"
        Write-Host "Review $sharedPath\CHANGELOG.md and refresh copied instruction files if needed."
    }
}

function Write-SmallFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Title,
        [int]$Limit = $MaxLines
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $lineCount = (Get-Content -LiteralPath $Path | Measure-Object -Line).Lines
    Write-Host ""
    Write-Host "== $Title =="

    if ($lineCount -le $Limit) {
        Get-Content -LiteralPath $Path
        return
    }

    Write-Host "$Path has $lineCount lines; showing first $Limit lines only."
    Get-Content -LiteralPath $Path -TotalCount $Limit
}

Write-InstructionKitUpdateNotice

Write-SmallFile -Path "AGENTS.md" -Title "AGENTS.md"
Write-SmallFile -Path "tools/CODEX_WORKING_AGREEMENTS.md" -Title "Working Agreements"

$summaryDir = "tools/summary"
if (Test-Path -LiteralPath $summaryDir) {
    $latestSummary = Get-ChildItem -LiteralPath $summaryDir -Filter "*_CODEX_WORK_SUMMARY.md" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latestSummary) {
        Write-SmallFile -Path $latestSummary.FullName -Title "Latest Summary" -Limit $MaxLines
    }
}

Write-Host ""
Write-Host "== Git Status =="
git status --short

Write-Host ""
Write-Host "== Git Diff Stat =="
git diff --stat

if (Test-Path -LiteralPath "tools/CODEX_RUNBOOK.md") {
    Write-Host ""
    Write-Host "== Runbook Command Hints =="
    Select-String -Path "tools/CODEX_RUNBOOK.md" -Pattern "```|Install|Run|Test|Build|Smoke|Logs|powershell|npm|pnpm|yarn|dotnet|pytest|cargo|go test" -CaseSensitive:$false |
        Select-Object -First 80 |
        ForEach-Object { $_.Line }
}

if (Test-Path -LiteralPath "tools/project-memory/index_project.py") {
    Write-Host ""
    Write-Host "== Project Memory =="
    Write-Host "Search memory with:"
    Write-Host "python .\tools\project-memory\index_project.py search `"query`" --limit 10"
}

Write-Host ""
Write-Host "Startup restore complete. Use targeted searches before reading large files."
