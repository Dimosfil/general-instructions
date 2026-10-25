import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { findUnityProject } from '../tools/unity-mcp-router.mjs';

const router = fileURLToPath(new URL('../tools/unity-mcp-router.mjs', import.meta.url));
const requests = [
  { jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-03-26', capabilities: {}, clientInfo: { name: 'router-test', version: '1' } } },
  { jsonrpc: '2.0', method: 'notifications/initialized' },
  { jsonrpc: '2.0', id: 2, method: 'tools/list', params: {} },
];

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'unity-mcp-router-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  return root;
}

function unity(root) {
  mkdirSync(join(root, 'Assets'), { recursive: true });
  mkdirSync(join(root, 'ProjectSettings'), { recursive: true });
  writeFileSync(join(root, 'ProjectSettings', 'ProjectVersion.txt'), 'm_EditorVersion: test\n');
}

function session(cwd, backend, input = requests) {
  return new Promise((fulfill, reject) => {
    const child = spawn(process.execPath, [router, ...backend], { cwd, windowsHide: true });
    let stdout = '', stderr = '';
    const timer = setTimeout(() => { child.kill(); reject(new Error('Router timed out')); }, 8000);
    child.stdout.on('data', data => { stdout += data; });
    child.stderr.on('data', data => { stderr += data; });
    child.on('error', reject);
    child.on('exit', code => {
      clearTimeout(timer);
      fulfill({ code, stderr, messages: stdout.trim().split('\n').filter(Boolean).map(line => JSON.parse(line)) });
    });
    child.stdin.on('error', () => {});
    child.stdin.end(input.map(value => JSON.stringify(value)).join('\n') + '\n');
  });
}

test('ordinary projects return an empty MCP catalog without starting any backend', async t => {
  const root = fixture(t);
  // A nonexistent executable proves no backend is even attempted.
  const result = await session(root, [join(root, 'must-not-start.exe'), 'mcp']);
  assert.equal(result.code, 0);
  assert.equal(result.stderr, '');
  assert.equal(result.messages[0].result.protocolVersion, '2025-03-26');
  assert.deepEqual(result.messages[1].result, { tools: [] });
  const unavailable = await session(root, [join(root, 'must-not-start.exe'), 'mcp'], [
    ...requests, { jsonrpc: '2.0', id: 3, method: 'tools/call', params: { name: 'status' } },
  ]);
  assert.equal(unavailable.messages[2].error.code, -32601);
});

test('Unity roots, subdirectories, worktrees, and repository boundaries', t => {
  const root = fixture(t);
  unity(root);
  writeFileSync(join(root, '.git'), 'gitdir: ignored-for-routing');
  const nested = join(root, 'Assets', 'Scripts');
  mkdirSync(nested);
  assert.equal(findUnityProject(root), root);
  assert.equal(findUnityProject(nested), root);
  mkdirSync(join(nested, '.git'));
  assert.equal(findUnityProject(nested), null);
  unity(nested);
  assert.equal(findUnityProject(nested), nested);
});

test('partial markers and sibling Unity projects do not activate the backend', t => {
  const root = fixture(t);
  mkdirSync(join(root, 'Assets'));
  assert.equal(findUnityProject(root), null);
  unity(join(root, 'sibling'));
  assert.equal(findUnityProject(root), null);
  assert.equal(findUnityProject(join(root, 'sibling')), join(root, 'sibling'));
});

test('Unity sessions transparently forward MCP and select the current project', async t => {
  const root = fixture(t);
  const project = join(root, 'Unity space Кириллица');
  unity(project);
  const backend = join(root, 'backend.mjs');
  writeFileSync(backend, `
    import { createInterface } from 'node:readline';
    const input = createInterface({ input: process.stdin });
    input.on('line', line => {
      const request = JSON.parse(line);
      if (!Object.hasOwn(request, 'id')) return;
      const result = request.method === 'initialize'
        ? { protocolVersion: request.params.protocolVersion, capabilities: { tools: {} }, serverInfo: { name: 'fixture', version: '1' } }
        : request.method === 'tools/list' ? { tools: [{ name: 'status', inputSchema: { type: 'object' } }] }
        : { content: [{ type: 'text', text: JSON.stringify({ cwd: process.cwd(), args: process.argv.slice(2) }) }] };
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id, result }) + '\\n');
    });
  `);
  const result = await session(join(project, 'Assets'), [process.execPath, backend, 'mcp'], [
    ...requests, { jsonrpc: '2.0', id: 3, method: 'tools/call', params: { name: 'status', arguments: {} } },
  ]);
  assert.equal(result.code, 0);
  assert.equal(result.stderr, '');
  assert.equal(result.messages[0].result.serverInfo.name, 'fixture');
  assert.equal(result.messages[1].result.tools[0].name, 'status');
  const state = JSON.parse(result.messages[2].result.content[0].text);
  assert.equal(resolve(state.cwd), resolve(project));
  assert.deepEqual(state.args, ['mcp', '--project-path', project]);
});

test('backend startup errors and fixed project selectors fail clearly', async t => {
  const root = fixture(t);
  unity(root);
  const missing = await session(root, [join(root, 'missing.exe'), 'mcp']);
  assert.equal(missing.code, 1);
  assert.match(missing.stderr, /Unable to start Unity MCP/);
  const pinned = await session(root, ['unity', 'mcp', '--project-path', root]);
  assert.equal(pinned.code, 1);
  assert.match(pinned.stderr, /without a fixed project selector/);
});

test('client EOF stops an unresponsive backend without leaving a process', async t => {
  const root = fixture(t);
  unity(root);
  const backend = join(root, 'waiting-backend.mjs');
  // Keep the backend alive even after stdin closes, as a real server might do.
  writeFileSync(backend, 'setInterval(() => {}, 1000); process.stdin.resume();');
  const result = await session(root, [process.execPath, backend]);
  assert.notEqual(result.code, 0);
  assert.deepEqual(result.messages, []);
});
