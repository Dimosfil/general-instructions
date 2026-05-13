param(
    [int]$MaxLines = 160
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
