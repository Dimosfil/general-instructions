#!/usr/bin/env node
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

// Probe the real stdio boundary without performing any Editor writes.
export async function verify({ router, unity, project, timeout = 15000 }) {
  const child = spawn(process.execPath, [router, unity, 'mcp'], {
    cwd: project, windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'],
  });
  const lines = createInterface({ input: child.stdout });
  let nextId = 1;
  let initialized = false;
  const pending = new Map();
  const fail = () => {
    for (const entry of pending.values()) entry.reject(new Error('transport_failed'));
    pending.clear();
  };
  child.on('error', fail);
  child.on('exit', fail);
  child.stdin.on('error', fail);
  child.stderr.resume(); // Never forward connection descriptors or tokens.
  lines.on('line', line => {
    let message;
    try { message = JSON.parse(line); } catch { return; }
    const entry = pending.get(message.id);
    if (!entry) return;
    pending.delete(message.id);
    if (message.error) entry.reject(new Error('protocol_error'));
    else entry.resolve(message.result);
  });
  const request = (method, params = {}) => new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    child.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
  });
  let timer;
  try {
    return await Promise.race([
      (async () => {
        const handshake = await request('initialize', {
          protocolVersion: '2024-11-05', capabilities: {},
          clientInfo: { name: 'gi-unity-mcp-check', version: '1' },
        });
        if (!handshake?.serverInfo || !handshake?.protocolVersion) throw new Error('invalid_initialize');
        initialized = true;
        child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
        const catalog = await request('tools/list');
        if (!Array.isArray(catalog?.tools)) throw new Error('invalid_catalog');
        return { initialize: true, tool_count: catalog.tools.length,
          status: catalog.tools.length ? 'tools_discovered' : 'no_tools',
          live_editor_state: 'not_verified', chat_tools: 'not_verified' };
      })(),
      new Promise((_, reject) => { timer = setTimeout(() => reject(new Error('timeout')), timeout); }),
    ]);
  } catch (error) {
    return { initialize: initialized, tool_count: 0, status: error.message,
      live_editor_state: 'not_verified', chat_tools: 'not_verified' };
  } finally {
    clearTimeout(timer);
    lines.close();
    child.stdin.end();
    // Closing input lets the router stop its backend, including on Windows,
    // where forcibly killing the router would skip its signal handlers.
    if (child.exitCode === null && child.signalCode === null) await new Promise(resolve => {
      const cleanup = setTimeout(() => { child.kill(); resolve(); }, 3500);
      child.once('exit', () => { clearTimeout(cleanup); resolve(); });
    });
    fail();
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const [router, unity, project, timeout] = process.argv.slice(2);
  if (!router || !unity || !project) {
    console.error('Usage: node verify-unity-mcp.mjs <router> <unity> <project> [timeout-ms]');
    process.exitCode = 1;
  } else {
    console.log(JSON.stringify(await verify({ router, unity, project, timeout: Number(timeout) || 15000 })));
  }
}
