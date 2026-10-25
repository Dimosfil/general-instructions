[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$NodePath = "",
    [string]$UnityPath = "",
    [string]$CodexPath = "",
    [switch]$CheckOnly,
    [switch]$SkipLiveCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$kitRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$result = [ordered]@{ status = 'not_unity'; configuration = 'not_checked'; pipeline = 'not_checked';
    editor = 'not_checked'; protocol = 'not_checked'; chat_tools = 'not_verified'; blockers = @() }
$operation = 'project_detection'

# Gate before reading any user configuration or looking for host dependencies.
if (-not (Test-Path -LiteralPath (Join-Path $project 'Assets') -PathType Container) -or
    -not (Test-Path -LiteralPath (Join-Path $project 'ProjectSettings/ProjectVersion.txt') -PathType Leaf)) {
    return [pscustomobject]$result
}

function Invoke-Tool {
    param([string]$Path, [string[]]$Arguments)
    $global:LASTEXITCODE = 0
    $output = @(& $Path @Arguments 2>$null) -join "`n"
    return [pscustomobject]@{ Code = $LASTEXITCODE; Text = $output }
}

function Resolve-Tool {
    param([string]$Explicit, [string]$Name, [string[]]$Candidates = @())
    foreach ($candidate in @($Explicit) + $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    $found = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.Source }
    return ''
}

function Sync-File {
    param([string]$Source, [string]$Target)
    if (-not (Test-Path -LiteralPath $Target) -or
        (Get-FileHash -LiteralPath $Source).Hash -ne (Get-FileHash -LiteralPath $Target).Hash) {
        Copy-Item -LiteralPath $Source -Destination $Target
    }
}

function Test-SamePath {
    param([string]$Left, [string]$Right)
    if (-not $Left -or -not $Right) { return $false }
    $comparison = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        [StringComparison]::OrdinalIgnoreCase
    } else { [StringComparison]::Ordinal }
    return [string]::Equals([IO.Path]::GetFullPath($Left), [IO.Path]::GetFullPath($Right), $comparison)
}

function Read-Server {
    $response = Invoke-Tool $CodexPath @('mcp', 'get', $settings.server_name, '--json')
    if ($response.Code -ne 0) { return $null }
    return ($response.Text | ConvertFrom-Json)
}

try {
    $operation = 'setup_policy'
    $settings = Get-Content -Raw -LiteralPath (Join-Path $kitRoot 'config/unity-mcp.json') | ConvertFrom-Json
    $metadataPath = Join-Path $project 'tools/project-memory/instruction-kit.json'
    $optedOut = $false
    if (Test-Path -LiteralPath $metadataPath) {
        $metadata = Get-Content -Raw -LiteralPath $metadataPath | ConvertFrom-Json
        if ($metadata.PSObject.Properties.Name -contains 'unity_mcp' -and $metadata.unity_mcp -and
            $metadata.unity_mcp.PSObject.Properties['enabled']) {
            $optedOut = $metadata.unity_mcp.enabled -eq $false
        }
    }
    if (-not $settings.enabled -or $optedOut) {
        $result.status = 'disabled'
        return [pscustomobject]$result
    }

    $clientHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else {
        Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
    }
    if (-not [IO.Path]::IsPathRooted($clientHome)) { throw 'client_home_must_be_absolute' }
    $clientHome = [IO.Path]::GetFullPath($clientHome)
    $operation = 'host_dependencies'
    $hostTools = Join-Path $clientHome 'tools'
    $isWindowsHost = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    $exeSuffix = if ($isWindowsHost) { '.exe' } else { '' }
    $CodexPath = Resolve-Tool $CodexPath 'codex' @((Join-Path $clientHome ('bin/codex' + $exeSuffix)))
    if (-not $CodexPath) { throw 'codex_cli_missing_or_other_client' }
    $NodePath = Resolve-Tool $NodePath 'node' @((Join-Path $clientHome ('bin/node' + $exeSuffix)),
        (Join-Path $hostTools ('unity-mcp-runtime/node' + $exeSuffix)))
    $unityCandidates = @((Join-Path $hostTools ('unity-cli/bin/unity' + $exeSuffix)))
    if ($env:UNITY_CLI_HOME) { $unityCandidates += Join-Path $env:UNITY_CLI_HOME ('bin/unity' + $exeSuffix) }
    if ($env:LOCALAPPDATA) { $unityCandidates += Join-Path $env:LOCALAPPDATA 'Unity/bin/unity.exe' }
    $UnityPath = Resolve-Tool $UnityPath 'unity' $unityCandidates
    if ($CheckOnly -and (-not $NodePath -or -not $UnityPath)) { throw 'host_dependencies_missing' }
    if ((-not $NodePath -or -not $UnityPath) -and -not $settings.install_missing_dependencies) {
        throw 'dependency_installation_disabled'
    }

    if (-not $NodePath) {
        $operation = 'node_installation'
        $architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
        if ($architecture -notin @('x64', 'arm64')) { throw 'unsupported_node_architecture' }
        Write-Host 'Unity MCP setup: downloading the official Node runtime and verifying SHA-256 (user tools only).'
        $nodeDir = Join-Path $hostTools 'unity-mcp-runtime'
        [void][IO.Directory]::CreateDirectory($nodeDir)
        $distribution = $settings.node_distribution
        $checksumText = Invoke-RestMethod -Uri ($distribution + '/SHASUMS256.txt') -TimeoutSec 120
        if ($isWindowsHost) {
            $relativeBinary = "win-$architecture/node.exe"
            $checksum = [regex]::Match($checksumText, '(?m)^([a-fA-F0-9]{64})\s+' + [regex]::Escape($relativeBinary) + '\s*$')
        } else {
            $platform = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::OSX)) { 'darwin' } else { 'linux' }
            $checksum = [regex]::Match($checksumText, '(?m)^([a-fA-F0-9]{64})\s+(node-v[0-9.]+-' + $platform + '-' + $architecture + '\.tar\.gz)\s*$')
            $relativeBinary = $checksum.Groups[2].Value
        }
        if (-not $checksum.Success) { throw 'node_checksum_missing' }
        $download = Join-Path $nodeDir ('node-' + [guid]::NewGuid().ToString('N') + '.download')
        try {
            Invoke-WebRequest -Uri ($distribution + '/' + $relativeBinary) -OutFile $download -TimeoutSec 120
            if ((Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash -ine $checksum.Groups[1].Value) {
                throw 'node_checksum_mismatch'
            }
            $NodePath = Join-Path $nodeDir ('node' + $exeSuffix)
            if ($isWindowsHost) {
                Move-Item -LiteralPath $download -Destination $NodePath
            } else {
                $tar = Resolve-Tool '' 'tar'
                if (-not $tar) { throw 'tar_missing_for_node_installation' }
                $archiveRoot = $relativeBinary -replace '\.tar\.gz$', ''
                $extracted = Invoke-Tool $tar @('-xzf', $download, '--strip-components=2', '-C', $nodeDir, ($archiveRoot + '/bin/node'))
                if ($extracted.Code -ne 0) { throw 'node_extraction_failed' }
            }
        } finally {
            if (Test-Path -LiteralPath $download) { Remove-Item -LiteralPath $download }
        }
    }
    if (-not $UnityPath) {
        $operation = 'unity_cli_installation'
        Write-Host 'Unity MCP setup: running the official Unity CLI installer under user tools; no Editor will be launched.'
        $installerExtension = if ($isWindowsHost) { '.ps1' } else { '.sh' }
        $installerUri = if ($isWindowsHost) { $settings.unity_windows_installer } else { $settings.unity_unix_installer }
        $installerFile = Join-Path ([IO.Path]::GetTempPath()) ('gi-unity-install-' + [guid]::NewGuid().ToString('N') + $installerExtension)
        $previousUnityHome = $env:UNITY_CLI_HOME
        try {
            Invoke-WebRequest -Uri $installerUri -OutFile $installerFile -TimeoutSec 120
            $env:UNITY_CLI_HOME = Join-Path $hostTools 'unity-cli'
            if ($isWindowsHost) {
                $shell = (Get-Process -Id $PID).Path
                $installation = Invoke-Tool $shell @('-NoProfile', '-File', $installerFile)
            } else {
                $bash = Resolve-Tool '' 'bash'
                if (-not $bash) { throw 'bash_missing_for_unity_installer' }
                $installation = Invoke-Tool $bash @($installerFile)
            }
            if ($installation.Code -ne 0) { throw 'unity_cli_install_failed' }
        } finally {
            $env:UNITY_CLI_HOME = $previousUnityHome
            if (Test-Path -LiteralPath $installerFile) { Remove-Item -LiteralPath $installerFile }
        }
        $UnityPath = Resolve-Tool '' 'unity' $unityCandidates
        if (-not $UnityPath) { throw 'unity_cli_not_found_after_install' }
    }

    $operation = 'host_tool_validation'
    $nodeVersion = Invoke-Tool $NodePath @('--version')
    if ($nodeVersion.Code -ne 0 -or $nodeVersion.Text -notmatch '^v(\d+)\.') { throw 'invalid_node_runtime' }
    if ([int]$Matches[1] -lt 18) { throw 'node_runtime_requires_18_or_newer' }
    $mcpHelp = Invoke-Tool $UnityPath @('mcp', '--help')
    if ($mcpHelp.Code -ne 0 -or -not $mcpHelp.Text.Contains('--project-path')) { throw 'unity_mcp_command_unsupported' }
    $routerTarget = Join-Path $hostTools 'unity-mcp-router.mjs'
    $probeTarget = Join-Path $hostTools 'verify-unity-mcp.mjs'
    $existing = Read-Server
    $operation = 'client_configuration'
    $managed = $existing -and $existing.transport.type -eq 'stdio' -and
        @($existing.transport.args).Count -eq 3 -and (Test-SamePath $existing.transport.args[0] $routerTarget)
    $official = $existing -and $existing.transport.type -eq 'stdio' -and
        (Test-SamePath $existing.transport.command $UnityPath) -and @($existing.transport.args).Count -eq 1 -and
        $existing.transport.args[0] -eq 'mcp' -and -not $existing.transport.cwd -and
        -not $existing.transport.env -and -not $existing.transport.env_vars -and
        -not $existing.enabled_tools -and -not $existing.disabled_tools
    if ($existing -and -not $managed -and -not $official) { throw 'unity_server_conflicts_with_existing_configuration' }
    if ($existing -and -not $existing.enabled) { throw 'unity_server_explicitly_disabled_in_client' }
    $matchesConfig = $managed -and (Test-SamePath $existing.transport.command $NodePath) -and
        (Test-SamePath $existing.transport.args[1] $UnityPath) -and $existing.transport.args[2] -eq 'mcp' -and -not $existing.transport.cwd
    if ($managed -and -not $matchesConfig -and ($existing.transport.env -or $existing.transport.env_vars -or
        $existing.enabled_tools -or $existing.disabled_tools -or $existing.tool_timeout_sec)) {
        throw 'managed_server_has_custom_policy_preserve_before_reconfiguration'
    }

    if (-not $CheckOnly) {
        [void][IO.Directory]::CreateDirectory($hostTools)
        Sync-File (Join-Path $PSScriptRoot 'unity-mcp-router.mjs') $routerTarget
        Sync-File (Join-Path $PSScriptRoot 'verify-unity-mcp.mjs') $probeTarget
        if (-not $matchesConfig) {
            $added = Invoke-Tool $CodexPath @('mcp', 'add', $settings.server_name, '--', $NodePath, $routerTarget, $UnityPath, 'mcp')
            if ($added.Code -ne 0) { throw 'codex_mcp_add_failed' }
        }
        $existing = Read-Server
    }
    if (-not $existing -or -not $existing.enabled -or -not (Test-SamePath $existing.transport.command $NodePath) -or
        @($existing.transport.args).Count -ne 3 -or -not (Test-SamePath $existing.transport.args[0] $routerTarget) -or
        -not (Test-SamePath $existing.transport.args[1] $UnityPath) -or $existing.transport.args[2] -ne 'mcp' -or $existing.transport.cwd) {
        throw 'unity_client_configuration_not_verified'
    }
    foreach ($file in @(@('unity-mcp-router.mjs', $routerTarget), @('verify-unity-mcp.mjs', $probeTarget))) {
        if (-not (Test-Path -LiteralPath $file[1]) -or
            (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $file[0])).Hash -ne (Get-FileHash -LiteralPath $file[1]).Hash) {
            throw 'host_tool_copy_missing_or_outdated'
        }
    }
    $result.configuration = 'verified'
    $result.status = if ($CheckOnly) { 'checked' } else { 'configured' }

    $operation = 'pipeline_package'
    $manifestPath = Join-Path $project 'Packages/manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'unity_package_manifest_missing' }
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if (@($manifest.dependencies.PSObject.Properties | ForEach-Object { $_.Name }) -notcontains $settings.pipeline_package) {
        $result.pipeline = 'missing'
        $versionText = Get-Content -Raw -LiteralPath (Join-Path $project 'ProjectSettings/ProjectVersion.txt')
        $versionMatch = [regex]::Match($versionText, 'm_EditorVersion:\s*(\d+)\.')
        if (-not $versionMatch.Success -or [int]$versionMatch.Groups[1].Value -lt $settings.minimum_editor_major) {
            throw 'pipeline_requires_supported_unity_editor'
        }
        if (-not $CheckOnly) {
            $installHelp = Invoke-Tool $UnityPath @('pipeline', 'install', '--help')
            if ($installHelp.Code -ne 0 -or -not $installHelp.Text.Contains('--project-path') -or
                -not $installHelp.Text.Contains('--non-interactive')) { throw 'pipeline_install_command_unsupported' }
            Write-Host 'Unity MCP setup: installing the official Pipeline package in the selected project; Unity may recompile scripts.'
            $installed = Invoke-Tool $UnityPath @('pipeline', 'install', '--project-path', $project, '--non-interactive', '--json')
            if ($installed.Code -ne 0) { throw 'pipeline_install_failed_check_unity_login_network_or_editor' }
            $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
        }
        if (@($manifest.dependencies.PSObject.Properties | ForEach-Object { $_.Name }) -notcontains $settings.pipeline_package) { throw 'pipeline_package_not_verified' }
    }
    $result.pipeline = 'present'
    if (-not $SkipLiveCheck) {
        $operation = 'protocol_verification'
        Write-Host 'Unity MCP check: starting the official Unity MCP backend temporarily for initialize/tools-list; no Editor writes.'
        $probe = Invoke-Tool $NodePath @($probeTarget, $routerTarget, $UnityPath, $project, [string]$settings.probe_timeout_ms)
        if ($probe.Code -ne 0) { throw 'mcp_probe_failed' }
        $result.protocol = $probe.Text | ConvertFrom-Json
        $result.editor = 'live_state_not_verified'
        if ($result.protocol.status -ne 'tools_discovered') { $result.blockers += 'editor_or_pipeline_not_ready' }
    }
} catch {
    $result.status = 'blocked'
    # Keep raw external output and user-home config contents out of reports.
    $reason = $_.Exception.Message
    if ($reason -notmatch '^[a-z0-9_]+$') { $reason = $operation + '_failed' }
    $result.blockers += $reason
}
[pscustomobject]$result
