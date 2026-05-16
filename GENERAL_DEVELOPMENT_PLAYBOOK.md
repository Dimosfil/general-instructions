# General Development Playbook

This is a reusable must-have plan for starting and maintaining a software project with an AI coding agent. Keep it short, explicit, and local to the repository.

## 1. Create The Agent Entry Point

Add `AGENTS.md` in the repository root.

It should contain:

- What the project is.
- How to restore context.
- Where durable memory lives.
- How to run, test, build, and inspect logs.
- What files/folders are safe working areas.
- Rules about git, commits, generated files, secrets, and destructive commands.

For other tools, add tiny redirect files when useful:

- `.github/copilot-instructions.md`
- `CLAUDE.md`
- `GEMINI.md`
- root `README.md` section: `For AI agents: read AGENTS.md first.`

Do not duplicate the whole instruction set everywhere. Keep `AGENTS.md` the source of truth.

## 2. Define Durable Memory

Create a local memory folder, for example:

```text
tools/project-memory/
```

Minimum contents:

- `README.md`: what memory exists and how to use it.
- `STUDY_PLAN.md`: roadmap for understanding the project.
- `instruction-kit.json`: copied instruction-kit provenance and local update
  check configuration when the project uses a shared instruction library.
- Local agent memory database or index, ignored by git when large/generated.
- A command to rebuild the index from source files.
- A command to save durable investigation notes.

Rule: important findings must be written locally, not only said in chat.

When a project reveals a reusable improvement to agent instructions, workflows,
templates, or checklists, write a dated recommendation to the shared instruction
library's `updates/` folder if that library exists. Treat those files as intake
recommendations, not automatically accepted rules.

If no shared instruction library is available, create a local project intake
folder such as:

```text
tools/instruction-updates/
```

or, when the project already has agent memory:

```text
tools/project-memory/instruction-updates/
```

Use this filename pattern:

```text
YYYY-MM-DD_HH-mm-ss_AGENT_RECOMMENDED_GENERAL_INSTRUCTIONS_UPDATES.md
```

Keep project-specific details out of reusable instruction recommendations unless
they are clearly marked as examples. Do not add the shared instruction library
as a dependency, package, submodule, symlink, or runtime reference unless the
user explicitly asks for that.

Recommended pattern: use `tools/project-memory/project_memory.sqlite` as a local
SQLite memory/index for the agent, not as the product database and not as part
of the application runtime. Commit only reviewable docs, schema/scripts, and
Markdown exports when useful. Keep the SQLite file ignored when it is large or
rebuildable.

SQLite agent memory should support targeted queries, for example search by
symbol, path, topic, error, or feature name. Do not dump the database or load it
whole into context. Use small SQL queries with `LIMIT`, and keep durable notes
exportable to Markdown such as `tools/project-memory/NOTES.md`.

Use two project-memory layers:

- Markdown is the human-reviewable layer for concise handoff summaries,
  decisions, architecture notes, and curated exports.
- SQLite is the searchable agent-memory layer for detailed findings,
  file/symbol indexes, references, commands, failures, and evidence-backed notes.

Do not blindly migrate all Markdown into SQLite. When Markdown memory becomes
too large to read cheaply, introduce or rebuild the SQLite memory/index and keep
Markdown as the concise reviewable export.

For analysis, refactoring, migration, or multi-step implementation tasks, create
or update a concise checklist in the project's durable planning location before
editing code. For project-wide or ongoing work, use a shared task file such as
`tools/project-memory/pending-tasks.md`. For a large focused task, create a
dedicated Markdown plan in `tools/project-memory/` with a clear task name.

Task plans should include the goal, planned changes, execution order, risks or
dependencies, and verification steps. Track progress while working and keep the
file concise; do not store full diffs, large logs, generated outputs, secrets,
credentials, or private production data.

## 3. Add A Startup Script

Create one command that restores project context.

Example:

```powershell
.\tools\agent-start.ps1
```

It should print:

- `AGENTS.md`
- working agreements
- latest summary
- `git status --short`
- useful `git diff --stat` information
- next recommended commands

The goal is that a new chat can become useful in minutes.

Startup scripts must stay compact. Do not dump large files, full runbooks, full
logs, full SQLite contents, generated files, or full diffs. Use line guards and
targeted queries, such as `Get-Content -TotalCount`, `Get-Content -Tail`,
`Select-String`, and `git diff --stat` on PowerShell.

If the project has `tools/project-memory/instruction-kit.json`, the startup
script may compare its installed version with a configured local shared
instruction library's `VERSION.md` and print a compact update notice. It should
point to accepted release artifacts such as `CHANGELOG.md`, not to `updates/`.

On startup or after context loss, the agent should continue from recorded state,
not from memory alone. It should read the latest summary, inspect relevant diffs,
and only then edit files.

Use `patterns/RAG_STARTUP_FLOW.md` for token-conscious context restoration and
`patterns/FIRST_MESSAGE_HANDLING.md` for first-message title or bootstrap
behavior.

## 4. Write Working Agreements

Create:

```text
tools/AGENT_WORKING_AGREEMENTS.md
```

Include:

- Do not revert user changes unless explicitly requested.
- Treat dirty worktrees as normal.
- Whether the agent may commit or only edit. Default safe rule: the agent edits
  and verifies; the user reviews and commits, unless the project says otherwise.
- Preferred edit method. For manual edits, prefer patch-style edits that keep
  changes scoped and reviewable.
- Prefer small scoped changes.
- Main project folders.
- Where logs and generated files live.
- When to ask before expanding scope.
- If a change needs files outside the agreed working area, say so before
  expanding scope.

## 5. Write A Runbook

Create:

```text
tools/AGENT_RUNBOOK.md
```

It should answer:

- How to install dependencies.
- How to run the app.
- How to run tests.
- How to build.
- How to smoke-check the most important workflow.
- How to inspect logs.
- Known environmental caveats.

Every command should be copy-pasteable.

## 6. Keep Handoff Summaries

Create:

```text
tools/summary/
```

After meaningful work, write a concise summary named:

```text
YYYY-MM-DD_HH-mm-ss_AGENT_WORK_SUMMARY.md
```

Include:

- Current state.
- What changed.
- Commands run and results.
- Known failures or caveats.
- Next best steps.
- Current git status snapshot.

Summaries are for handoff. Durable knowledge belongs in project memory notes.

## 7. Map The Architecture Early

Before large changes, build a first map:

- Entry points.
- Modules/packages/assemblies.
- Dependency graph.
- Data flow.
- Runtime lifecycle.
- Config/secrets boundaries.
- Storage/database/API boundaries.
- Assets/templates/UI/routes as applicable.
- Tests and automation.

Do not try to understand everything in one pass. Build a searchable index and record small verified findings.

## 8. Establish Quality Gates

Every project should define minimum checks:

- After changing any artifact, verify it once: reread the edited code, JSON,
  config, docs, generated metadata, or command output instead of assuming the
  edit landed correctly.
- Fast syntax/type check.
- Unit tests.
- Integration or smoke test for the main workflow.
- Build/package command.
- Lint/format command when available.
- Log inspection command for runtime systems.
- If debugging or a check requires closing the project, editor, app, or other
  user-visible process, ask first and offer a choice: allow the close once, or
  allow the same close action for the rest of the current chat.
- Launch applications, editors, browsers, and GUI tools quietly in the
  background whenever possible. Do not steal keyboard focus, move the cursor, or
  bring the launched app to the foreground, because the user may be typing in
  another project.

If a check cannot run locally, document why.

## 9. Decide Git Rules

Write the policy clearly:

- Who commits.
- Branch naming.
- Whether generated files are committed.
- What must never be committed.
- How to handle unrelated dirty files.
- Default diff review command, such as `git diff --stat`.
- Whether full diffs are allowed in chat. Default: avoid full diff dumps unless
  the user explicitly asks.

Default safe rule: the agent edits and verifies; the user reviews and commits.

## 10. Protect Secrets And Generated Noise

Before real work starts:

- Review `.gitignore`.
- Ignore local databases, logs, cache folders, build outputs, temp folders.
- Never store credentials in summaries or notes.
- Document where secret/config examples live.

## 11. Make The First Useful Vertical Slice

For a new product, avoid spending the first phase only on structure.

Build one thin but real workflow:

- UI/API entry.
- Domain action.
- Persistence or external integration if needed.
- Test or smoke check.
- Logging/observability.

Then expand around a working spine.

## 12. End Every Session Cleanly

Before stopping:

- Run the relevant checks.
- Record failures honestly.
- Update summary.
- Save durable findings as notes.
- Leave `git status --short` understandable.

The next chat should never have to reconstruct the previous session from vibes.

## Minimal New Project Checklist

- [ ] Root `AGENTS.md`
- [ ] Root `README.md` with human setup and AI redirect
- [ ] `.gitignore`
- [ ] `tools/AGENT_WORKING_AGREEMENTS.md`
- [ ] `tools/AGENT_RUNBOOK.md`
- [ ] `tools/summary/`
- [ ] `tools/project-memory/README.md`
- [ ] `tools/project-memory/STUDY_PLAN.md`
- [ ] `tools/project-memory/instruction-kit.json`
- [ ] Optional local agent memory SQLite/index script
- [ ] Optional Markdown export for durable agent notes
- [ ] Two-layer memory policy: concise Markdown for review, SQLite for
  searchable detailed agent memory when Markdown becomes too large
- [ ] Startup script
- [ ] Test/build/run commands
- [ ] Secret/config policy
- [ ] First handoff summary

## Token Budget Rule

The agent must not load the whole repository, full chat history, or all summaries by default.

Startup context should include only:
- AGENTS.md
- latest handoff summary
- relevant memory notes found by search
- current git status
- `git diff --stat`, not full `git diff`
- exact files needed for the task

Prefer retrieval over dumping context.
Prefer short summaries over raw logs.
Prefer file excerpts over full files.
Prefer targeted searches over full diff dumps.
Avoid broad artifacts, full check matrices, large logs, and whole-file reads
unless the user asks for that scope or targeted investigation cannot isolate the
failure.

## Instruction Update Intake

The `general-instructions` repository may receive dated recommendation files
from different projects under:

```text
updates/
```

Treat those files as an intake queue for maintaining `general-instructions`, not
as automatically accepted rules.

External projects:

- May write dated recommendations to `updates/` when the shared library is
  available.
- Must not read `updates/` during startup or bootstrap.
- Must not add the shared library as a dependency, package, submodule, symlink,
  or runtime reference unless the user explicitly asks.

When maintaining this library:

- Review update files by date, newest first.
- Read only the specific update being evaluated, not the whole folder by
  default.
- Extract reusable rules, patterns, templates, or checklist items into the main
  library.
- Keep project-specific details out of shared instructions.
- Preserve token economy: avoid recommendations that encourage dumping large
  files, full diffs, logs, SQLite contents, generated outputs, or all memory.
- Remember accepted updates by committing the resulting instruction changes.

## Usage Awareness

Prefer retrieval, concise summaries, targeted checks, and scoped edits
throughout the session. Do not wait until usage is nearly exhausted to become
token-conscious.

Before expensive operations such as full repository scans, repeated retries,
large multi-file edits, or huge context restores, confirm that the scope is
needed for the user's goal.
