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
- Do not read large files in full by default, including large `index.html`,
  bundled JS/CSS, logs, lockfiles, generated files, and build artifacts. Prefer
  targeted searches, heads, tails, or small line ranges.
- For verification, count or query HTML elements programmatically instead of
  printing the whole HTML document.
- Do not build zip archives or run every available check unless the user
  explicitly asks for that scope.
- Do not read large files in full by default. Start with targeted searches,
  `Get-Content -TotalCount`, `Get-Content -Tail`, or small line ranges.
- Final responses should summarize only the changes, checks, and current status;
  do not restate the full investigation context.
- Search for specific symbols, paths, errors, or patterns before doing broad
  repository scans.
- Do not print large logs. Prefer tails and targeted error searches.
- Launch applications in the background so focus does not jump away from the
  user's current window.
- Treat the first user message in a new chat as the chat title when it looks like
  a short title or project name. In that case, run only the documented startup
  context restore, then stop and ask what the user wants to do next. Do not
  execute the title text as a task.
- For web applications, assume the user will inspect the UI manually. Do not
  open, browse, screenshot, or visually inspect the UI automatically unless the
  user explicitly asks for that.

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
