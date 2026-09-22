[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CommandText,
    [switch]$SkipUpdateCheck,
    [ValidateRange(1, 500)][int]$MaxSummaryLines = 80
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
        & $checkerPath -InstructionKitPath $metadataPath
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
    Write-Output ""
    Write-Output "===== LATEST HANDOFF SUMMARY ====="
    $summaryDirectory = Join-Path $projectRoot "tools/summary"
    $latestSummary = if (Test-Path -LiteralPath $summaryDirectory -PathType Container) {
        Get-ChildItem -LiteralPath $summaryDirectory -File -Filter "*.md" |
            Sort-Object Name -Descending |
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
}
