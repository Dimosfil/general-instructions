# Agent Recommended General Instructions Updates

Date: 2026-05-13
Target repository: `D:\AI\general-instructions`
Audience: future AI agents maintaining the reusable instruction library

## Summary

The current instruction library is structurally sound and ready to use for new project setup. It already contains the main agent entry point, general development playbook, setup checklist, templates, and the SQLite agent-memory pattern.

Recommended improvements are mostly about making the RAG/project-memory workflow more directly actionable and reducing repeated guidance across files.

## Recommended Changes

### 1. Add a dedicated RAG startup flow pattern

Create:

```text
patterns/RAG_STARTUP_FLOW.md
```

Suggested purpose:

- Explain the startup retrieval sequence for a project.
- Keep the rule explicit: retrieve only relevant context, do not dump all memory into chat.
- Define when to query `tools/project-memory/project_memory.sqlite` or Markdown notes.
- Define how to record new verified findings after work.

Suggested flow:

1. Read root `AGENTS.md`.
2. Read the latest handoff summary from `tools/summary/`.
3. Search `tools/project-memory/` by task terms, symbols, paths, errors, or feature names.
4. Query SQLite memory only with targeted searches and small `LIMIT`s.
5. Open only exact source files needed for the task.
6. After meaningful work, write durable verified findings to project memory or summary.

Rules to include:

- Do not load the whole repository, all notes, all summaries, or the full SQLite database by default.
- Store verified facts with evidence paths.
- Mark uncertain findings clearly.
- Never store secrets, credentials, private user data, or production data.

### 2. Add a startup script template

Create:

```text
templates/agent-start.template.ps1
```

Suggested behavior from project root:

- Print `AGENTS.md` if present.
- Print `tools/AGENT_WORKING_AGREEMENTS.md` if present.
- Print the latest file in `tools/summary/` if present.
- Show `git status --short`.
- Show `git diff --stat` instead of full diff.
- Show available run/test/build commands from `tools/AGENT_RUNBOOK.md` or remind that they are TODO.
- Optionally show how to run project-memory search if an index script exists.

The script should avoid dumping large logs, full diffs, full SQLite contents, or full generated files.

### 3. Add a gitignore snippet for agent memory

Create:

```text
templates/gitignore-agent-memory.template
```

Suggested content:

```gitignore
# Local/generated AI-agent memory and runtime noise
tools/project-memory/*.sqlite
tools/project-memory/*.sqlite-*
tools/project-memory/*.db
tools/project-memory/*.db-*
tools/summary/*.tmp
*.log
```

Note: project-specific repos may need additional ignores for caches, build outputs, local env files, and product databases.

### 4. Add a handoff summary template

Create:

```text
templates/SUMMARY.template.md
```

Suggested sections:

```markdown
# Agent Work Summary

Date: TODO

## Current State

TODO

## What Changed

TODO

## Commands Run

TODO

## Verification

TODO

## Known Failures Or Caveats

TODO

## Next Best Steps

TODO

## Git Status Snapshot

TODO
```

### 5. Reduce duplicated guidance in the playbook and templates

Several rules currently appear multiple times in `GENERAL_DEVELOPMENT_PLAYBOOK.md`, `AGENTS.md`, and `templates/AGENT_WORKING_AGREEMENTS.template.md`:

- Do not read large files in full by default.
- Prefer targeted searches, heads, tails, and small line ranges.
- Do not print full logs or full diffs.
- Use `git diff --stat` by default.
- Do not automatically open or inspect web UI unless asked.
- Treat the first short user message as a possible chat title and only restore context.

Recommended cleanup:

- Keep one canonical section in `GENERAL_DEVELOPMENT_PLAYBOOK.md`, for example `Context Hygiene Rules`.
- In templates, keep a shorter summarized version and point to the detailed project-local rules.
- Preserve the behavior, but reduce repetition so future edits do not drift.

### 6. Update index and checklist after adding files

Update:

```text
INDEX.md
checklists/NEW_PROJECT_AGENT_SETUP.md
```

Add references to:

- `patterns/RAG_STARTUP_FLOW.md`
- `templates/agent-start.template.ps1`
- `templates/gitignore-agent-memory.template`
- `templates/SUMMARY.template.md`

Checklist additions:

- [ ] Copy or adapt `templates/agent-start.template.ps1` into `tools/agent-start.ps1`.
- [ ] Add agent-memory ignore rules to `.gitignore`.
- [ ] Decide whether the project uses SQLite memory, Markdown-only memory, or both.
- [ ] Confirm startup retrieval loads only task-relevant context.

## Suggested Implementation Order

1. Add the four new template/pattern files.
2. Update `INDEX.md`.
3. Update `checklists/NEW_PROJECT_AGENT_SETUP.md`.
4. Lightly deduplicate `GENERAL_DEVELOPMENT_PLAYBOOK.md`.
5. Reread changed files and run `git diff --check`.

## Bottom Line

The library is correct as-is, but these additions would make the RAG/project-memory setup more turnkey for new projects and easier for future agent sessions to follow consistently.
