[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BaseRef,
    [string]$SourceRoot = (Join-Path $PSScriptRoot '..')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $SourceRoot).Path

function Invoke-ReleaseGit {
    param([string[]]$GitArguments)
    $result = @(& git -C $root @GitArguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw ($result -join "`n") }
    return $result
}

function Read-ReleaseVersion {
    param([string]$Text)
    $match = [regex]::Match($Text, '`(?<version>\d{4}\.\d{2}\.\d{2}(?:\.\d+)?)`')
    if (-not $match.Success) { throw 'Missing instruction-kit release version.' }
    return [version]$match.Groups['version'].Value
}

$baseline = Read-ReleaseVersion ((Invoke-ReleaseGit -GitArguments @('show', "${BaseRef}:VERSION.md")) -join "`n")
$current = Read-ReleaseVersion ([System.IO.File]::ReadAllText((Join-Path $root 'VERSION.md')))
$migrationPathPattern = '^migrations/(?!README\.md$)[^/]+\.md$'
$removed = @(Invoke-ReleaseGit -GitArguments @('diff', '--name-only', '--diff-filter=D', '--no-renames', $BaseRef, '--', 'migrations')) |
    Where-Object { $_ -match $migrationPathPattern }
if ($removed) { throw "Released migration removed or renamed: $($removed -join ', '). Preserve released IDs and add a forward repair." }
$added = @(
    Invoke-ReleaseGit -GitArguments @('diff', '--name-only', '--diff-filter=A', '--no-renames', $BaseRef, '--', 'migrations')
    Invoke-ReleaseGit -GitArguments @('ls-files', '--others', '--exclude-standard', '--', 'migrations')
) | Where-Object { $_ -match $migrationPathPattern } | Sort-Object -Unique
foreach ($path in $added) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($path)
    if ($name -notmatch '^(?<version>\d{4}\.\d{2}\.\d{2}\.\d+)__.+$') {
        throw "Invalid migration ID: $path"
    }
    $migrationVersion = [version]$Matches.version
    if ($migrationVersion -le $baseline) {
        throw "Backdated migration: $path is not newer than published baseline $baseline. Add a forward migration; preserve released IDs."
    }
    if ($migrationVersion -gt $current) { throw "Migration exceeds VERSION.md: $path" }
    $body = [System.IO.File]::ReadAllText((Join-Path $root $path))
    $declared = [regex]::Match($body, '(?m)^Version: `(?<version>[^`]+)`\s*$')
    if (-not $declared.Success -or [version]$declared.Groups['version'].Value -ne $migrationVersion) {
        throw "Migration filename and declared version differ: $path"
    }
}
Write-Output "Migration release order passed: $(@($added).Count) new migration(s), published baseline $baseline, release $current."
