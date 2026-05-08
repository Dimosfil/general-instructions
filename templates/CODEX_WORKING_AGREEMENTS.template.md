# Codex Working Agreements

## Scope

- Keep changes small and tied to the current request.
- Ask before expanding into unrelated modules.
- If a task requires files outside the agreed working area, say so first.

## User Changes

- Do not revert user changes unless explicitly requested.
- Treat dirty worktrees as normal.
- If user changes affect the task, work with them.

## Git

- Default: the agent edits and verifies; the user reviews and commits.
- Branch naming: `TODO`.
- Generated files policy: `TODO`.
- Never commit secrets, credentials, local databases, logs, or caches.
- Do not print full `git diff` output by default. Prefer `git diff --stat` and
  targeted `Select-String` queries for relevant files or patterns.
- Do not read large chunks of `index.html` unless necessary. Prefer targeted
  searches and small excerpts around the relevant UI, script, or markup.
- For verification, count or query HTML elements programmatically instead of
  printing the whole HTML document.
- Do not build zip archives or run every available check unless the user
  explicitly asks for that scope.

## Editing

- Prefer patch-style edits for manual changes.
- Avoid unrelated formatting churn.
- Add comments only when they clarify non-obvious behavior.

## Verification

- Reread edited files after changes.
- Run the fastest relevant check first.
- Record checks run and failures in the handoff summary.

## Processes

- Ask before closing editors, apps, servers, or other visible processes.
- Launch GUI tools quietly in the background when possible.
