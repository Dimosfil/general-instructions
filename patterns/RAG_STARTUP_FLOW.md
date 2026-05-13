# RAG Startup Flow

Use this flow when restoring project context. The goal is to retrieve only the
context needed for the current task, not to dump project memory into chat.

## Flow

1. Read root `AGENTS.md`.
2. Read only the latest handoff summary from `tools/summary/`.
3. Search `tools/project-memory/` by task terms, symbols, paths, errors, or
   feature names.
4. Query SQLite memory only with targeted searches and small `LIMIT`s.
5. Open only the exact source files needed for the task.
6. After meaningful work, write verified durable findings to project memory or
   the handoff summary.

## Token Rules

- Do not load the whole repository by default.
- Do not read all summaries, all notes, all logs, or the full SQLite database.
- Do not print full `git diff`; use `git diff --stat` and targeted searches.
- Do not print large files. Use heads, tails, line ranges, or search snippets.
- Do not print large SQLite query results. Always use `LIMIT`.
- Prefer evidence paths and short snippets over raw file dumps.

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
