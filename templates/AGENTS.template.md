# Agent Instructions

## Project

Describe what this project is, who it serves, and the primary runtime or product
surface.

## Restore Context

Start here:

```powershell
.\tools\codex-start.ps1
```

If the startup script is unavailable, read:

- `AGENTS.md`
- latest file in `tools/summary/`
- `tools/CODEX_WORKING_AGREEMENTS.md`
- `tools/CODEX_RUNBOOK.md`
- relevant notes in `tools/project-memory/`

## Durable Memory

Durable project knowledge lives in:

```text
tools/project-memory/
```

Important findings should be written there or in a handoff summary, not only
left in chat.

## Common Commands

Install dependencies:

```powershell
# TODO
```

Run:

```powershell
# TODO
```

Test:

```powershell
# TODO
```

Build:

```powershell
# TODO
```

Inspect logs:

```powershell
# TODO
```

## Working Areas

- Source: `TODO`
- Tests: `TODO`
- Tools: `tools/`
- Summaries: `tools/summary/`
- Project memory: `tools/project-memory/`

## Rules

- Do not revert user changes unless explicitly requested.
- Treat dirty worktrees as normal.
- Keep changes scoped to the current task.
- Ask before destructive operations or broad refactors.
- Do not commit secrets, credentials, local databases, logs, or generated caches.
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
- Default git policy: agent edits and verifies; user reviews and commits unless
  the project says otherwise.
