# Agent Instructions

## Project

Describe what this project is, who it serves, and the primary runtime or product
surface.

## Restore Context

Start here:

```powershell
.\tools\agent-start.ps1
```

If the startup script is unavailable, read:

- `AGENTS.md`
- latest file in `tools/summary/`
- `tools/AGENT_WORKING_AGREEMENTS.md`
- `tools/AGENT_RUNBOOK.md`
- relevant notes in `tools/project-memory/`

Use the RAG startup flow: retrieve only task-relevant context, search memory by
specific terms, and query SQLite memory only with small `LIMIT`s.

## Durable Memory

Durable project knowledge lives in:

```text
tools/project-memory/
```

Important findings should be written there or in a handoff summary, not only
left in chat.

For analysis, refactoring, migration, or multi-step implementation tasks, create
or update a concise checklist in `tools/project-memory/pending-tasks.md` or a
dedicated task plan in `tools/project-memory/` before editing code. Keep plans
task-relevant and update progress as meaningful steps complete.

When this project reveals a reusable improvement to agent instructions,
workflows, templates, or checklists, write a dated recommendation to the shared
instruction library's `updates/` folder if it is available. If it is not
available, use a local intake folder such as `tools/instruction-updates/` or
`tools/project-memory/instruction-updates/`. Treat recommendations as intake,
not accepted rules.

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
- Ask before destructive operations, broad refactors, or unrelated scope
  expansion.
- Do not commit secrets, credentials, local databases, logs, or generated caches.
- Do not print full `git diff` output by default. Prefer `git diff --stat` and
  targeted queries for relevant files or patterns.
- Do not read large files in full by default, including large `index.html`,
  bundled JS/CSS, logs, lockfiles, generated files, and build artifacts. Prefer
  targeted searches, heads, tails, or small line ranges such as
  `Get-Content -TotalCount`, `Get-Content -Tail`, and `Select-String` on
  PowerShell.
- For verification, count or query HTML elements programmatically instead of
  printing the whole HTML document.
- Do not produce broad artifacts, such as zip archives, or run full check
  matrices unless the user explicitly asks for that scope.
- Final responses should summarize only the changes, checks, and current status;
  do not restate the full investigation context.
- Search for specific symbols, paths, errors, or patterns before doing broad
  repository scans.
- Do not print large logs. Prefer tails and targeted error searches.
- Startup restore must be compact; do not dump large files, full runbooks, full
  SQLite contents, full logs, generated outputs, or full diffs.
- Launch applications in the background so focus does not jump away from the
  user's current window.
- Treat a short first message as a possible chat title: restore context, then
  ask what to do next instead of executing the title as a task.
- Treat short chat commands that start with `gi` as shared instruction-kit
  commands for `general-instructions`, not as product work for this project.
  If a `gi` command is missing a needed parameter, ask one short clarification
  question instead of guessing.
- Treat a first message that points to a shared instruction library as an
  instruction bootstrap, not as a request to add that library as a dependency.
- When the user asks to check instruction updates, use accepted release
  artifacts and `migrations/`; do not read the shared library's `updates/`.
- If the user asks to update from a shared instruction library but this project
  has no `tools/project-memory/instruction-kit.json`, treat it as a first-time
  instruction bootstrap/init from that library.
- For web applications, assume the user will inspect the UI manually. Do not
  open, browse, screenshot, or visually inspect the UI automatically unless the
  user explicitly asks for that.
- Default git policy: agent edits and verifies; user reviews and commits unless
  the project says otherwise.
- Commit only after an explicit user request. Use
  `tools/project-memory/git-preferences.json` for commit-message language
  preferences.
