# RAG Startup Flow

Use this flow when restoring project context. The goal is to retrieve only the
context needed for the current task, not to dump project memory into chat.

## Before Restoring

If the user only sends a short greeting, thanks, acknowledgement, or
status-neutral message, do not restore project context. Reply briefly and ask
what they want to do next. Run this flow only after the user gives a task,
question, command, path, or error that needs project context.

## Flow

1. Read root `AGENTS.md`.
2. Read only the latest handoff summary from `tools/summary/`, and read only
   its heading, current state, and next steps unless the current task needs more.
3. Search `tools/project-memory/` by task terms, symbols, paths, errors, or
   feature names.
4. Query SQLite memory only with targeted searches and small `LIMIT`s.
5. Open only the exact source files needed for the task.
6. After meaningful work, write verified durable findings to project memory or
   the handoff summary.

For first-pass project study, read local instructions, README, manifests, and
config entry points before building a file map. Use recursive scans only when a
targeted search fails or the task clearly requires repository-wide inventory.

## Token Rules

- Treat `cached input` as a symptom, not the main optimization target. Reduce
  total live context: current input plus cached context.
- Start a new session for unrelated new tasks when old context is no longer
  useful.
- Prefer compact handoff summaries over carrying long investigation history
  forward.
- For `gi start`, `gi restore`, or title-only first messages, restore the
  minimum state needed to orient the next turn; do not read full summaries,
  runbooks, memory notes, logs, or diffs unless a concrete task needs them.
- Do not load the whole repository by default.
- Do not read all summaries, all notes, all logs, or the full SQLite database.
- Do not print full `git diff`; use `git diff --stat` and targeted searches.
- Do not print large files. Use heads, tails, line ranges, or search snippets.
- Do not print large SQLite query results. Always use `LIMIT`.
- Prefer evidence paths and short snippets over raw file dumps.
- Treat nested checkouts, vendored repositories, cloned examples, and
  third-party source trees as separate scope. Do not inspect them during startup
  unless the user explicitly asks, the task is about that nested tree, or local
  instructions identify it as an active workspace component.
- Treat user-home application data and personal telemetry as private external
  sources. Do not read `.codex`, `.cursor`, IDE logs, browser profiles, shell
  history, application SQLite databases, or local app logs outside the project
  root unless the user gives an explicit path and action. For analyzer tasks,
  use mock or sample data by default.
- Split multi-step R&D into separate tasks when later steps do not need the
  full previous reasoning trace.

## When To Query Memory

Use project memory when the task references:

- a symbol, class, route, scene, prefab, feature, command, or known error
- a previous decision or recurring failure
- architecture already investigated in an earlier session
- a project-specific workflow that may be documented locally

Skip memory search for trivial edits when the relevant files are already known.

## What To Store

Store only verified facts that future agents would otherwise rediscover:

- architecture findings
- debugging causes and fixes
- reliable commands and observed results
- file or symbol relationships
- decisions and rationale
- caveats with evidence paths

Mark uncertain findings clearly. Never store secrets, credentials, private user
data, or production data.

## First Message Rule

If the first user message in a new chat looks like a short title or project
name, treat it as the chat title. Run only this startup restore flow, then stop
and ask what the user wants to do next. Do not execute the title as a task.
