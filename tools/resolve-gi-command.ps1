[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CommandText,
    [string]$RouteFile = "config/gi-command-routes.json",
    [switch]$PathsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-CommandText {
    param([Parameter(Mandatory = $true)][string]$Value)

    return (($Value.Trim().ToLowerInvariant() -replace '\s+', ' '))
}

function Test-ProjectMarkdownFile {
    param([string]$Root, [string]$RelativePath)

    if ($RelativePath -notmatch '^[^:]+\.md$' -or
        [System.IO.Path]::IsPathRooted($RelativePath)) { return $false }

    $path = $Root
    $segments = $RelativePath -split '[/\\]'
    foreach ($segment in $segments) {
        if ($segment -in @('', '.', '..') -or $segment.TrimEnd(' ', '.') -ne $segment) { return $false }
        $path = Join-Path $path $segment
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if (-not $item -or ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) { return $false }
    }
    return -not $item.PSIsContainer
}

function Get-CustomIntegrationContext {
    param([string]$Root, [string]$Name)

    $registry = 'tools/project-memory/specs/integration-contracts/connected-projects.md'
    Write-Output "Integration registry: $registry"
    if (-not (Test-ProjectMarkdownFile -Root $Root -RelativePath $registry)) {
        Write-Output 'Custom integration status: registry unavailable'
        return
    }

    $contents = [System.IO.File]::ReadAllText((Join-Path $Root $registry))
    $sections = [regex]::Matches($contents, '(?m)^#{2,3} (?<name>[^\r\n]+)\r?\n(?<body>[\s\S]*?)(?=^#{1,3}[ \t]|\z)')
    $entries = @(foreach ($section in $sections) {
        $fields = @{}
        $body = $section.Groups['body'].Value
        foreach ($field in [regex]::Matches($body, '(?im)^- (?<key>GI custom aliases|API reference|API runbook|Credential source):[ \t]*(?<value>[^\r\n]*)')) {
            $key = $field.Groups['key'].Value
            if (-not $fields.ContainsKey($key)) { $fields[$key] = @() }
            $fields[$key] += $field.Groups['value'].Value.Trim()
        }
        if ($fields.ContainsKey('GI custom aliases')) {
            [pscustomobject]@{
                Name = $section.Groups['name'].Value.Trim()
                Line = [regex]::Matches($contents.Substring(0, $section.Index), '\n').Count + 1
                Aliases = $fields['GI custom aliases'] -split ','
                Fields = $fields
            }
        }
    })

    if (-not $Name) {
        Write-Output 'Custom integration status: list'
        foreach ($entry in $entries) { Write-Output "- $($entry.Name) (registry line $($entry.Line))" }
        return
    }

    $matchingEntries = @($entries | Where-Object {
        $names = @($_.Name) + $_.Aliases
        @($names | Where-Object { $_.Trim() -and (Normalize-CommandText -Value $_) -eq $Name }).Count -gt 0
    })
    if ($matchingEntries.Count -ne 1) {
        if ($matchingEntries.Count -eq 0) { Write-Output 'Custom integration status: unknown'; return }
        Write-Output 'Custom integration status: ambiguous'
        foreach ($entry in $matchingEntries) { Write-Output "- $($entry.Name) (registry line $($entry.Line))" }
        return
    }

    $selected = $matchingEntries[0]
    Write-Output 'Custom integration status: selected'
    Write-Output "Integration: $($selected.Name) (registry line $($selected.Line))"
    foreach ($key in @('API reference', 'API runbook', 'Credential source')) {
        $values = $selected.Fields[$key]
        if (-not $values -or $values.Count -ne 1) {
            Write-Output "${key}: missing or repeated in the registry"
            continue
        }
        $value = $values[0]
        $valid = switch ($key) {
            'API reference' {
                $uri = $null
                ([uri]::TryCreate($value, [UriKind]::Absolute, [ref]$uri) -and
                    $uri.Scheme -eq 'https' -and -not $uri.UserInfo -and -not $uri.Query) -or
                    (Test-ProjectMarkdownFile -Root $Root -RelativePath $value)
            }
            'API runbook' { Test-ProjectMarkdownFile -Root $Root -RelativePath $value }
            'Credential source' {
                $references = @($value -split ',')
                @($references | Where-Object {
                    $_.Trim() -notmatch '^(env:[a-z_][a-z0-9_]*|(?:connector|secret):[a-z0-9_][a-z0-9_./-]*)$'
                }).Count -eq 0
            }
        }
        if ($valid) { Write-Output "${key}: $value" }
        else { Write-Output "${key}: invalid or unavailable in the current project" }
    }
}

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$resolvedRouteFile = if ([System.IO.Path]::IsPathRooted($RouteFile)) {
    $RouteFile
}
else {
    Join-Path $projectRoot $RouteFile
}

if (-not (Test-Path -LiteralPath $resolvedRouteFile -PathType Leaf)) {
    throw "GI command route manifest is missing: $resolvedRouteFile"
}

$manifest = Get-Content -LiteralPath $resolvedRouteFile -Raw | ConvertFrom-Json
$normalizedCommand = Normalize-CommandText -Value $CommandText
$routeMatches = @()

foreach ($route in $manifest.routes) {
    foreach ($aliasValue in $route.aliases) {
        $alias = Normalize-CommandText -Value ([string]$aliasValue)
        $pattern = '^{0}(?:$|[\s:=])' -f [regex]::Escape($alias)
        if ($normalizedCommand -match $pattern) {
            $routeMatches += [pscustomobject]@{
                Route = $route
                Alias = $alias
                AliasLength = $alias.Length
            }
        }
    }
}

if ($routeMatches.Count -eq 0) {
    throw "No GI command route matched: $CommandText"
}

$selected = $routeMatches | Sort-Object AliasLength -Descending | Select-Object -First 1
$route = $selected.Route

Write-Output ("GI route: {0}" -f $route.id)
$requestedCommand = if ($route.id -eq 'custom-integration') { $selected.Alias } else { $CommandText.Trim() }
Write-Output ("Requested command: {0}" -f $requestedCommand)
Write-Output ("Matched alias: {0}" -f $selected.Alias)
Write-Output ("Contract: {0}" -f $route.contract)
Write-Output "Mandatory context files:"

foreach ($relativePathValue in $route.context_files) {
    $relativePath = [string]$relativePathValue
    $fullPath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Mandatory routed context file is missing: $relativePath"
    }

    Write-Output ("- {0}" -f $relativePath)
}

if ($PathsOnly) {
    exit 0
}

foreach ($relativePathValue in $route.context_files) {
    $relativePath = [string]$relativePathValue
    $fullPath = Join-Path $projectRoot $relativePath
    Write-Output ""
    Write-Output ("===== BEGIN {0} =====" -f $relativePath)
    Get-Content -LiteralPath $fullPath -Raw
    Write-Output ("===== END {0} =====" -f $relativePath)
}

if ($route.id -eq 'custom-integration') {
    $integrationName = $normalizedCommand.Substring($selected.AliasLength) -replace '^[\s:=]+', ''
    Write-Output ''
    Get-CustomIntegrationContext -Root $projectRoot -Name $integrationName
}
