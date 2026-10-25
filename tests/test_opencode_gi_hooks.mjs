import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, copyFile, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const source = fileURLToPath(new URL('../', import.meta.url));
const files = [
  '.opencode/plugins/gi-lifecycle.js', 'tools/invoke-gi-lifecycle-hook.ps1',
  'tools/get-gi-context.ps1', 'config/gi-context-budgets.json',
  'patterns/AGENTS_RUNTIME/03-rule-precedence.md',
];

async function fixture(t) {
  const root = await mkdtemp(path.join(tmpdir(), 'gi-opencode-hooks-'));
  t.after(() => {
    assert.ok(path.resolve(root).startsWith(path.resolve(tmpdir()) + path.sep));
    assert.ok(path.basename(root).startsWith('gi-opencode-hooks-'));
    return rm(root, { recursive: true, force: true });
  });
  for (const file of files) {
    await mkdir(path.dirname(path.join(root, file)), { recursive: true });
    await copyFile(path.join(source, file), path.join(root, file));
  }
  await writeFile(path.join(root, '.gitignore'), '.opencode/.gi-hook-state/\n.codex/.gi-hook-state/\n');
  execFileSync('git', ['init', '--quiet', root]);
  const { default: plugin } = await import(pathToFileURL(path.join(root, files[0])).href);
  const reviews = [];
  let sequence = 0;
  const id = () => `msg_${String(++sequence).padStart(8, '0')}`;
  const model = { providerID: 'fixture', modelID: 'model' };
  let hooks;
  const client = { session: { message: async () => ({ data: { info: { role: 'assistant' } } }), prompt: async (request) => {
    reviews.push(request);
    const message = { id: id(), agent: request.body.agent, model: request.body.model };
    await hooks['chat.message']({ sessionID: request.path.id }, { message, parts: request.body.parts });
    return { data: { info: message, parts: request.body.parts } };
  } } };
  hooks = await plugin({ directory: root, client });
  const sessionID = 'test-session';
  const user = async () => {
    const message = { id: id(), agent: 'build', model };
    await hooks['chat.message']({ sessionID }, { message, parts: [{ type: 'text', text: 'private original task' }] });
    await hooks['chat.params']({ sessionID, agent: 'build', message });
  };
  const finish = async () => hooks['experimental.text.complete']({ sessionID, messageID: id(), partID: id() });
  const audit = async () => (await readFile(path.join(root, '.opencode/.gi-hook-state/events.jsonl'), 'utf8'))
    .trim().split('\n').map((line) => JSON.parse(line));
  await user();
  return { root, hooks, reviews, user, finish, audit, sessionID, model, client };
}

test('OpenCode loads actual rules, restores compaction and forwards task arguments intact', async (t) => {
  const f = await fixture(t);
  const rules = (await readFile(path.join(f.root, files[4]), 'utf8')).replaceAll('\r\n', '\n').trimEnd();
  const system = { system: ['existing system'] };
  await f.hooks['experimental.chat.system.transform']({ sessionID: f.sessionID }, system);
  assert.ok(system.system[1].includes(rules));
  const compact = { context: ['existing compact context'] };
  await f.hooks['experimental.session.compacting']({ sessionID: f.sessionID }, compact);
  assert.ok(compact.context[1].includes(rules));
  const original = { prompt: 'Original — задача\r\nsecond line', subagent_type: 'explore', task_id: 'existing-session', description: 'unchanged' };
  const output = { args: { ...original } };
  await f.hooks['tool.execute.before']({ sessionID: f.sessionID, tool: 'task' }, output);
  assert.ok(output.args.prompt.includes(rules));
  assert.ok(output.args.prompt.endsWith(original.prompt));
  assert.ok(!output.args.prompt.includes('TASK COMPLETION REVIEW'));
  assert.deepEqual({ ...output.args, prompt: original.prompt }, original);
  const forwarded = structuredClone(output);
  await f.hooks['tool.execute.before']({ sessionID: f.sessionID, tool: 'task' }, output);
  assert.deepEqual(output, forwarded);
  const unrelated = { args: { prompt: 'keep' } };
  await f.hooks['tool.execute.before']({ sessionID: f.sessionID, tool: 'other' }, unrelated);
  assert.equal(unrelated.args.prompt, 'keep');
});

test('OpenCode finishes successful turns without synthetic messages and stores no prompt', async (t) => {
  const f = await fixture(t);
  await f.finish();
  assert.equal(f.reviews.length, 0);
  await f.finish();
  assert.equal(f.reviews.length, 0);
  await writeFile(path.join(f.root, 'new-source.txt'), 'changed after review');
  await f.finish();
  assert.equal(f.reviews.length, 0);
  await f.finish();
  assert.equal(f.reviews.length, 0);
  await f.user();
  await f.finish();
  assert.equal(f.reviews.length, 0);
  const entries = await f.audit();
  assert.ok(entries.some((entry) => entry.outcome === 'completion_allowed'));
  assert.ok(!JSON.stringify(entries).includes('private original task'));
});

test('OpenCode fails visibly and finitely on bad checks; missing rules deny task forwarding', async (t) => {
  const f = await fixture(t);
  await writeFile(path.join(f.root, 'bad.txt'), 'bad whitespace  \n');
  execFileSync('git', ['-C', f.root, 'add', '--', 'bad.txt']);
  await f.finish();
  assert.equal(f.reviews[0].body.noReply, true);
  assert.equal(f.reviews[0].body.parts[0].synthetic, true);
  assert.equal(f.reviews[0].body.agent, 'build');
  assert.deepEqual(f.reviews[0].body.model, f.model);
  assert.ok(f.reviews[0].body.parts[0].text.includes('[GI completion check failed]'));
  await f.finish();
  await f.finish();
  await assert.rejects(f.finish(), /unverified/);
  assert.equal(f.reviews.length, 3);
  await rm(path.join(f.root, 'tools/get-gi-context.ps1'));
  await assert.rejects(f.hooks['tool.execute.before']({ sessionID: f.sessionID, tool: 'task' }, { args: { prompt: 'private' } }), /unverified/);
  await assert.rejects(f.hooks['experimental.chat.system.transform']({ sessionID: f.sessionID }, { system: [] }), /unverified/);
});

test('OpenCode completes silently after a real failure is repaired', async (t) => {
  const f = await fixture(t);
  await writeFile(path.join(f.root, 'bad.txt'), 'bad whitespace  \n');
  execFileSync('git', ['-C', f.root, 'add', '--', 'bad.txt']);
  await f.finish();
  assert.equal(f.reviews.length, 1);
  await writeFile(path.join(f.root, 'bad.txt'), 'fixed\n');
  execFileSync('git', ['-C', f.root, 'add', '--', 'bad.txt']);
  await f.finish();
  assert.equal(f.reviews.length, 1);
  assert.equal((await f.audit()).at(-1).outcome, 'completion_allowed');
});

test('OpenCode excludes compaction summaries and rejects unsupported structured output', async (t) => {
  const f = await fixture(t);
  f.client.session.message = async () => ({ data: { info: { summary: true } } });
  await f.finish();
  assert.equal(f.reviews.length, 0);
  await assert.rejects(f.hooks['chat.message']({ sessionID: f.sessionID }, {
    message: { id: 'structured', format: { type: 'json_schema' } }, parts: [],
  }), /supports text responses/);
});
