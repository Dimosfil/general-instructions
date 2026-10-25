#!/usr/bin/env node
// Global stdio entrypoint. Only the selected workspace may start Unity MCP.
import { statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { pathToFileURL } from 'node:url';

function isKind(path, kind) {
  try {
    const value = statSync(path);
    return kind === 'directory' ? value.isDirectory() : value.isFile();
  } catch (error) {
    if (error.code === 'ENOENT' || error.code === 'ENOTDIR') return false;
    throw error;
  }
}

export function findUnityProject(workspace) {
  let current = resolve(workspace);
  for (;;) {
    if (isKind(join(current, 'ProjectSettings', 'ProjectVersion.txt'), 'file') &&
        isKind(join(current, 'Assets'), 'directory')) return current;
    // A nested independent repository must not inherit a parent's Unity Editor.
    if (isKind(join(current, '.git'), 'directory') ||
        isKind(join(current, '.git'), 'file')) return null;
    const parent = dirname(current);
    if (parent === current) return null;
    current = parent;
  }
}

function serveInactive() {
  // Codex has no file-based enable condition. An empty catalog avoids startup
  // errors outside Unity without launching Unity, inspecting Editors, or polling.
  const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
  input.on('line', line => {
    let request;
    try { request = JSON.parse(line); }
    catch {
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: null,
        error: { code: -32700, message: 'Parse error' } }) + '\n');
      return;
    }
    if (!request || typeof request !== 'object' || Array.isArray(request) ||
        request.jsonrpc !== '2.0' || typeof request.method !== 'string') {
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: null,
        error: { code: -32600, message: 'Invalid Request' } }) + '\n');
      return;
    }
    if (!Object.hasOwn(request, 'id')) return;
    let result;
    switch (request.method) {
      case 'initialize':
        result = { protocolVersion: request.params?.protocolVersion ?? '2024-11-05',
          capabilities: { tools: {} },
          serverInfo: { name: 'unity-workspace-router', version: '1.0.0' },
          instructions: 'Unity tools are inactive because this workspace is not a Unity project.' };
        break;
      case 'ping': result = {}; break;
      case 'tools/list': result = { tools: [] }; break;
      default:
        process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id,
          error: { code: -32601, message: 'Method not found' } }) + '\n');
        return;
    }
    process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id, result }) + '\n');
  });
}

export function main(args = process.argv.slice(2)) {
  const project = findUnityProject(process.cwd());
  if (args.length === 1 && args[0] === '--check') {
    process.stdout.write(JSON.stringify({ active: project !== null, project }) + '\n');
    return;
  }
  // Backend executable and prefix arguments come from the host's MCP config.
  const [command, ...backendArgs] = args;
  if (!command || backendArgs.includes('--project-path') ||
      backendArgs.some(value => value.startsWith('--project-path='))) {
    throw new Error('Provide the Unity executable and mcp arguments without a fixed project selector.');
  }
  if (!project) {
    serveInactive();
    return;
  }
  const child = spawn(command, [...backendArgs, '--project-path', project], {
    cwd: project, stdio: ['pipe', 'inherit', 'inherit'], windowsHide: true,
  });
  process.stdin.pipe(child.stdin);
  child.stdin.on('error', error => {
    if (error.code !== 'EPIPE' && error.code !== 'ERR_STREAM_DESTROYED') {
      console.error('Unity MCP input failed:', error.message);
      child.kill();
    }
  });
  process.stdin.once('end', () => {
    // Let the server finish cleanly; don't leave a backend after the client exits.
    const timer = setTimeout(() => child.kill(), 2000);
    timer.unref();
  });
  for (const signal of ['SIGINT', 'SIGTERM']) {
    process.once(signal, () => child.kill());
  }
  child.once('error', error => {
    console.error('Unable to start Unity MCP:', error.message);
    process.exit(1);
  });
  child.once('exit', code => process.exit(code ?? 1));
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try { main(); }
  catch (error) {
    console.error('Unity MCP routing failed:', error.message);
    process.exitCode = 1;
  }
}
