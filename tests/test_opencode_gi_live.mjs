// Real OpenCode loop against an isolated, local OpenAI-compatible provider.
// No credentials or external model requests. A fixed model answer verifies
// quiet host completion and context delivery, not semantic review by the model.
import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { spawn, execFileSync } from 'node:child_process';
import { mkdtemp, appendFile, writeFile, readFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';

const source = fileURLToPath(new URL('../', import.meta.url));

test('real OpenCode 1.15.7 completes once without a routine GI chat continuation', { timeout: 90_000 }, async (t) => {
  const root = await mkdtemp(path.join(tmpdir(), 'gi-opencode-live-'));
  t.after(() => {
    assert.ok(path.resolve(root).startsWith(path.resolve(tmpdir()) + path.sep));
    assert.ok(path.basename(root).startsWith('gi-opencode-live-'));
    return rm(root, { recursive: true, force: true });
  });
  // Exercise the actual distribution path, not a hand-assembled plugin fixture.
  execFileSync(process.env.GI_PWSH || 'pwsh', ['-NoProfile', '-NonInteractive', '-File',
    path.join(source, 'tools/install-instruction-kit.ps1'), '-Source', source,
    '-SourceRoot', source, '-TargetPath', root], { stdio: 'pipe' });
  await appendFile(path.join(root, '.gitignore'), '\n.isolated/\n');
  execFileSync('git', ['init', '--quiet', root]);
  const requests = [];
  const server = createServer(async (request, response) => {
    let text = '';
    for await (const chunk of request) text += chunk;
    const body = JSON.parse(text);
    requests.push(body);
    const answer = 'FINAL_ONCE';
    response.writeHead(200, { 'content-type': 'text/event-stream' });
    const chunk = (delta, finish_reason = null) => response.write(`data: ${JSON.stringify({
      id: 'local-fixture', object: 'chat.completion.chunk', created: 1, model: 'test',
      choices: [{ index: 0, delta, finish_reason }],
    })}\n\n`);
    chunk({ role: 'assistant', content: answer });
    chunk({}, 'stop');
    response.end('data: [DONE]\n\n');
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const config = {
    $schema: 'https://opencode.ai/config.json',
    provider: { 'gi-test': {
      npm: '@ai-sdk/openai-compatible', name: 'GI isolated test provider',
      options: { baseURL: `http://127.0.0.1:${server.address().port}/v1`, apiKey: 'local-fixture-only' },
      models: { test: { name: 'Test', limit: { context: 128000, output: 1024 } } },
    } },
    enabled_providers: ['gi-test'], autoupdate: false, share: 'disabled',
    permission: 'deny', agent: { title: { disable: true } },
  };
  await writeFile(path.join(root, 'opencode.json'), JSON.stringify(config));
  const windows = process.platform === 'win32';
  const command = windows ? (process.env.GI_PWSH || 'pwsh') : (process.env.GI_OPENCODE || 'opencode');
  const args = windows
    ? ['-NoProfile', '-NonInteractive', '-Command', '& opencode run --model gi-test/test --format json --title GI-hook-test "Return FINAL_ONCE; do not use tools."']
    : ['run', '--model', 'gi-test/test', '--format', 'json', '--title', 'GI-hook-test', 'Return FINAL_ONCE; do not use tools.'];
  const versionArgs = windows ? ['-NoProfile', '-NonInteractive', '-Command', '& opencode --version'] : ['--version'];
  assert.equal(execFileSync(command, versionArgs, { encoding: 'utf8' }).trim(), '1.15.7',
    'Revalidate the upstream loop contract before testing another OpenCode version.');
  const isolated = path.join(root, '.isolated');
  const env = { ...process.env, XDG_CONFIG_HOME: path.join(isolated, 'config'),
    XDG_DATA_HOME: path.join(isolated, 'data'), XDG_STATE_HOME: path.join(isolated, 'state'),
    XDG_CACHE_HOME: path.join(isolated, 'cache'), OPENCODE_DISABLE_AUTOUPDATE: '1',
    OPENCODE_DISABLE_CLAUDE_CODE: '1', OPENCODE_DISABLE_DEFAULT_PLUGINS: '1',
    OPENCODE_DISABLE_MODELS_FETCH: '1', OPENCODE_CONFIG_CONTENT: '{}' };
  delete env.OPENCODE_CONFIG;
  delete env.OPENCODE_CONFIG_DIR;
  delete env.OPENCODE_SERVER_PASSWORD;
  delete env.OPENCODE_SERVER_USERNAME;
  const child = spawn(command, args, { cwd: root, env, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  let output = '', errors = '';
  child.stdout.on('data', (data) => { output += data; });
  child.stderr.on('data', (data) => { errors += data; });
  const timer = setTimeout(() => child.kill(), 75_000);
  t.after(() => { clearTimeout(timer); if (child.exitCode === null) child.kill(); });
  const code = await new Promise((resolve, reject) => { child.on('error', reject); child.on('close', resolve); });
  clearTimeout(timer);
  assert.equal(code, 0, errors.slice(-3000));
  assert.equal(requests.length, 1, `Unexpected extra model request: ${output.slice(-3000)} ${errors.slice(-1500)}`);
  assert.ok(JSON.stringify(requests[0].messages).includes('MANDATORY TASK RULES (Work)'));
  assert.ok(JSON.stringify(requests[0].messages).includes('sending one final response'));
  assert.ok(!output.includes('[GI automatic final review]'));
  const textEvents = output.trim().split(/\r?\n/).map((line) => JSON.parse(line)).filter((event) => event.type === 'text');
  assert.equal(textEvents.length, 1, output.slice(-2000));
  assert.equal(textEvents[0].part.text, 'FINAL_ONCE');
  const audit = (await readFile(path.join(root, '.opencode/.gi-hook-state/events.jsonl'), 'utf8'))
    .trim().split('\n').map((line) => JSON.parse(line));
  assert.ok(!audit.some((entry) => entry.outcome === 'completion_check_failed' || entry.outcome === 'completion_review_required'));
  assert.equal(audit.at(-1).outcome, 'completion_allowed');
});
