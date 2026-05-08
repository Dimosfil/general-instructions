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
- Do not read large chunks of `index.html` unless necessary. Prefer targeted
  searches and small excerpts around the relevant UI, script, or markup.
- For verification, count or query HTML elements programmatically instead of
  printing the whole HTML document.
- Do not build zip archives or run every available check unless the user
  explicitly asks for that scope.
- Default git policy: agent edits and verifies; user reviews and commits unless
  the project says otherwise.
