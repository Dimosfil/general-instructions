import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { verify } from '../tools/verify-unity-mcp.mjs';

const root = fileURLToPath(new URL('..', import.meta.url));
const helper = join(root, 'tools', 'ensure-unity-mcp.ps1');
const shell = process.env.GI_TEST_PWSH || 'pwsh';
const quote = value => "'" + value.replaceAll("'", "''") + "'";

function context(t, unity = true) {
  const temp = mkdtempSync(join(tmpdir(), 'gi-unity-setup-'));
  t.after(() => rmSync(temp, { recursive: true, force: true }));
  const project = join(temp, 'Проект Unity');
  const home = join(temp, 'client');
  mkdirSync(project);
  mkdirSync(home);
  if (unity) {
    mkdirSync(join(project, 'Assets'));
    mkdirSync(join(project, 'ProjectSettings'));
    mkdirSync(join(project, 'Packages'));
    writeFileSync(join(project, 'ProjectSettings', 'ProjectVersion.txt'), 'm_EditorVersion: 6000.3.1f1\n');
    writeFileSync(join(project, 'Packages', 'manifest.json'), JSON.stringify({ dependencies: { 'com.example.keep': '1.2.3' } }));
  }
  const backend = join(temp, 'unity.ps1');
  writeFileSync(backend, `
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$CliArgs)
[IO.File]::AppendAllText((Join-Path $env:CODEX_HOME 'unity-calls.txt'), ($CliArgs -join '|') + "\n")
if ($CliArgs -contains '--help') { '--project-path --non-interactive'; exit 0 }
if ($CliArgs[0] -eq 'pipeline') {
 if ($env:GI_TEST_PIPELINE_FAIL -eq 'true') { exit 1 }
 $index = [Array]::IndexOf($CliArgs, '--project-path')
 $manifest = Join-Path $CliArgs[$index+1] 'Packages/manifest.json'
 $value = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
 $value.dependencies | Add-Member -NotePropertyName 'com.unity.pipeline' -NotePropertyValue '0.8.0'
 [IO.File]::WriteAllText($manifest, ($value | ConvertTo-Json -Depth 20))
 '{}'; exit 0
}
exit 1
`);
  return { temp, project, home, backend };
}

function run(ctx, { checkOnly = false, installer = false, failPipeline = false, command } = {}) {
  const invocation = command ?? (installer
    ? `& ${quote(join(root, 'tools/install-instruction-kit.ps1'))} -Source ${quote(root)} -TargetPath ${quote(ctx.project)} | ConvertTo-Json -Depth 12 -Compress`
    : `& ${quote(helper)} -ProjectPath ${quote(ctx.project)} -NodePath ${quote(process.execPath)} -UnityPath ${quote(ctx.backend)} -SkipLiveCheck ${checkOnly ? '-CheckOnly' : ''} | ConvertTo-Json -Depth 12 -Compress`);
  const result = spawnSync(shell, ['-NoProfile', '-NonInteractive', '-Command', invocation], {
    encoding: 'utf8', timeout: 30000, windowsHide: true,
    env: { ...process.env, CODEX_HOME: ctx.home, LOCALAPPDATA: ctx.temp,
      UNITY_CLI_HOME: '', GI_TEST_PIPELINE_FAIL: String(failPipeline) },
  });
  assert.equal(result.status, 0, result.stderr || result.error?.message);
  const json = result.stdout.trim().split(/\r?\n/).findLast(line => line.startsWith('{'));
  assert.ok(json, result.stdout + result.stderr);
  return JSON.parse(json);
}

test('non-Unity bootstrap copies portable tools without touching client config', t => {
  const ctx = context(t, false);
  const result = run(ctx, { installer: true });
  assert.equal(result.unity_mcp.status, 'not_unity');
  assert.equal(existsSync(join(ctx.home, 'config.toml')), false);
  assert.equal(existsSync(join(ctx.project, 'tools/ensure-unity-mcp.ps1')), true);
  assert.equal(existsSync(join(ctx.project, 'config/unity-mcp.json')), true);
});

test('fresh host configures once, installs missing Pipeline, and preserves other settings', t => {
  const ctx = context(t);
  const config = join(ctx.home, 'config.toml');
  writeFileSync(config, '# Keep this comment\nmodel = "existing-model"\n[mcp_servers.keep]\nurl = "https://example.invalid/mcp"\nenabled = false\n');
  const result = run(ctx);
  assert.equal(result.configuration, 'verified', JSON.stringify(result));
  assert.equal(result.pipeline, 'present', JSON.stringify(result));
  assert.equal(result.chat_tools, 'not_verified');
  const manifest = JSON.parse(readFileSync(join(ctx.project, 'Packages/manifest.json')));
  assert.equal(manifest.dependencies['com.example.keep'], '1.2.3');
  assert.ok(manifest.dependencies['com.unity.pipeline']);
  assert.match(readFileSync(config, 'utf8'), /model = "existing-model"/);
  assert.match(readFileSync(config, 'utf8'), /# Keep this comment/);
  assert.match(readFileSync(config, 'utf8'), /https:\/\/example.invalid\/mcp/);
  const before = readFileSync(config, 'utf8');
  const router = join(ctx.home, 'tools/unity-mcp-router.mjs');
  const modified = statSync(router).mtimeMs;
  const repeated = run(ctx);
  assert.equal(repeated.configuration, 'verified', JSON.stringify(repeated));
  assert.equal(readFileSync(config, 'utf8'), before);
  assert.equal(statSync(router).mtimeMs, modified);
  assert.equal(readFileSync(join(ctx.home, 'unity-calls.txt'), 'utf8').split('\n').filter(line => line.startsWith('pipeline|install|--project-path')).length, 1);
  const checked = run(ctx, { checkOnly: true });
  assert.equal(checked.status, 'checked', JSON.stringify(checked));
  assert.equal(readFileSync(config, 'utf8'), before);
});

test('custom server and opt-out survive automatic setup', t => {
  const ctx = context(t);
  const config = join(ctx.home, 'config.toml');
  const original = '[mcp_servers.unity]\nurl = "https://example.invalid/custom"\n';
  writeFileSync(config, original);
  const conflict = run(ctx);
  assert.equal(conflict.status, 'blocked');
  assert.ok(conflict.blockers.includes('unity_server_conflicts_with_existing_configuration'), JSON.stringify(conflict));
  assert.equal(readFileSync(config, 'utf8'), original);
  mkdirSync(join(ctx.project, 'tools/project-memory'), { recursive: true });
  writeFileSync(join(ctx.project, 'tools/project-memory/instruction-kit.json'), '{"unity_mcp":{"enabled":false}}');
  const bootstrap = run(ctx, { installer: true });
  assert.equal(bootstrap.unity_mcp.status, 'disabled');
  assert.equal(readFileSync(config, 'utf8'), original);
});

test('a valid project with an empty package manifest receives Pipeline', t => {
  const ctx = context(t);
  writeFileSync(join(ctx.project, 'Packages/manifest.json'), '{"dependencies":{}}');
  mkdirSync(join(ctx.project, 'tools/project-memory'), { recursive: true });
  writeFileSync(join(ctx.project, 'tools/project-memory/instruction-kit.json'), '{"unity_mcp":{}}');
  const result = run(ctx);
  assert.equal(result.configuration, 'verified', JSON.stringify(result));
  assert.equal(result.pipeline, 'present', JSON.stringify(result));
});

test('failed Pipeline install preserves completed host setup and reports the blocked layer', t => {
  const ctx = context(t);
  const result = run(ctx, { failPipeline: true });
  assert.equal(result.configuration, 'verified', JSON.stringify(result));
  assert.equal(result.pipeline, 'missing');
  assert.equal(result.status, 'blocked');
  assert.ok(result.blockers.includes('pipeline_install_failed_check_unity_login_network_or_editor'), JSON.stringify(result));
});

test('disabled client entries and unsupported Editor versions are preserved', t => {
  const ctx = context(t);
  writeFileSync(join(ctx.project, 'ProjectSettings/ProjectVersion.txt'), 'm_EditorVersion: 2022.3.1f1');
  const unsupported = run(ctx);
  assert.equal(unsupported.configuration, 'verified', JSON.stringify(unsupported));
  assert.ok(unsupported.blockers.includes('pipeline_requires_supported_unity_editor'));
  assert.equal(readFileSync(join(ctx.home, 'unity-calls.txt'), 'utf8').includes('pipeline|install|--project-path'), false);
  const config = join(ctx.home, 'config.toml');
  const disabled = readFileSync(config, 'utf8').replace('[mcp_servers.unity]', '[mcp_servers.unity]\nenabled = false');
  writeFileSync(config, disabled);
  const result = run(ctx);
  assert.ok(result.blockers.includes('unity_server_explicitly_disabled_in_client'), JSON.stringify(result));
  assert.equal(readFileSync(config, 'utf8'), disabled);
});

test('Unity bootstrap and zero-pending update provision a second host automatically', t => {
  const ctx = context(t);
  const mockDiscovery = `
function Get-Command {
 [CmdletBinding()]param([string]$Name)
 if ($Name -eq 'unity') { return [pscustomobject]@{Source=${quote(ctx.backend)}} }
 Microsoft.PowerShell.Core\\Get-Command -Name $Name -ErrorAction SilentlyContinue
}
`;
  const installed = run(ctx, { command: mockDiscovery + `& ${quote(join(root, 'tools/install-instruction-kit.ps1'))} -Source ${quote(root)} -TargetPath ${quote(ctx.project)} | ConvertTo-Json -Depth 12 -Compress` });
  assert.equal(installed.unity_mcp.configuration, 'verified', JSON.stringify(installed.unity_mcp));
  assert.equal(installed.unity_mcp.pipeline, 'present');
  const secondHome = join(ctx.temp, 'second-computer');
  mkdirSync(secondHome);
  const second = { ...ctx, home: secondHome };
  const builder = join(ctx.project, 'tools/get-gi-context.ps1');
  const command = mockDiscovery + `$packet = & ${quote(builder)} -CommandText 'gi update' | Out-String; [pscustomobject]@{ zeroPending=$packet.Contains('Pending instruction migrations: 0'); setupReported=$packet.Contains('UNITY MCP SETUP'); verified=$packet.Contains('"configuration":"verified"') } | ConvertTo-Json -Compress`;
  const updated = run(second, { command });
  assert.equal(updated.zeroPending, true);
  assert.equal(updated.setupReported, true);
  assert.equal(updated.verified, true);
  assert.equal(existsSync(join(secondHome, 'config.toml')), true);
  assert.equal(readFileSync(join(secondHome, 'tools/unity-mcp-router.mjs'), 'utf8'), readFileSync(join(root, 'tools/unity-mcp-router.mjs'), 'utf8'));
  const calls = readFileSync(join(secondHome, 'unity-calls.txt'), 'utf8');
  assert.equal(calls.includes('pipeline|install|--project-path'), false);
});

test('a failed runtime checksum prevents execution and client configuration', t => {
  const ctx = context(t);
  const command = `
$codexExecutable = (Get-Command codex).Source
function Get-Command { [CmdletBinding()]param([string]$Name) if ($Name -eq 'node') { return }; Microsoft.PowerShell.Core\\Get-Command -Name $Name -ErrorAction SilentlyContinue }
function Invoke-RestMethod { param($Uri) return ('0' * 64) + '  win-x64/node.exe' }
function Invoke-WebRequest { param($Uri,$OutFile) [IO.File]::WriteAllText($OutFile, 'corrupt fixture') }
& ${quote(helper)} -ProjectPath ${quote(ctx.project)} -UnityPath ${quote(ctx.backend)} -CodexPath $codexExecutable -SkipLiveCheck | ConvertTo-Json -Depth 12 -Compress
`;
  const result = run(ctx, { command });
  assert.ok(result.blockers.includes('node_checksum_mismatch'), JSON.stringify(result));
  assert.equal(existsSync(join(ctx.home, 'config.toml')), false);
  assert.equal(existsSync(join(ctx.home, 'tools/unity-mcp-runtime/node.exe')), false);
});

test('protocol probe distinguishes discovery from live Editor and chat verification', async t => {
  const ctx = context(t);
  // The Node binary acts as a fixture backend; its mcp file implements stdio.
  writeFileSync(join(ctx.project, 'mcp'), `
const {createInterface}=require('node:readline');
createInterface({input:process.stdin}).on('line',line=>{
 const r=JSON.parse(line);if(!Object.hasOwn(r,'id'))return;
 const result=r.method==='initialize'?{serverInfo:{name:'fixture',version:'1'},protocolVersion:r.params.protocolVersion,capabilities:{tools:{}}}:{tools:[{name:'test_status',inputSchema:{type:'object'}}]};
 process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:r.id,result})+'\\n');
});
`);
  const result = await verify({ router: join(root, 'tools/unity-mcp-router.mjs'), unity: process.execPath, project: ctx.project, timeout: 4000 });
  assert.equal(result.initialize, true);
  assert.equal(result.tool_count, 1);
  assert.equal(result.live_editor_state, 'not_verified');
  assert.equal(result.chat_tools, 'not_verified');
});
