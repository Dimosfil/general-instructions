# Agent Experience SQLite

Use SQLite as a local memory/index for the AI agent, not as the product
database and not as part of the application runtime.

## Purpose

The agent memory database stores verified project experience that helps future
sessions avoid rediscovery:

- indexed files and searchable text snippets
- symbols, routes, assets, config keys, or domain-specific references
- architectural findings
- debugging findings
- recurring failures and fixes
- useful commands and their observed results
- durable notes with evidence paths

## Location

Recommended location:

```text
tools/project-memory/project_memory.sqlite
```

The SQLite file is usually local/generated and should be ignored by git when it
is large or rebuildable.

Commit reviewable assets instead:

- `tools/project-memory/README.md`
- `tools/project-memory/STUDY_PLAN.md`
- `tools/project-memory/NOTES.md`
- schema or indexing scripts, for example `tools/project-memory/index_project.py`
- optional exported Markdown notes

## Rules

- Do not confuse agent memory SQLite with the project's application database.
- Do not store secrets, tokens, credentials, private user data, or production
  data in agent memory.
- Store verified facts, not loose guesses. Mark uncertain findings clearly.
- Include evidence paths for durable notes.
- Rebuild generated index tables from source files when possible.
- Keep human-reviewable durable knowledge exportable to Markdown.
- Do not dump the SQLite database or large query results into chat. Use targeted
  SQL queries with `LIMIT`.
- On startup, query only what is relevant to the task; do not load the whole
  database into context.

## Suggested Tables

Generated index tables depend on the project. Common options:

- `files`: path, extension, size, hash, modified time, indexed time, optional
  content or excerpt.
- `symbols`: path, line, kind, name, namespace/module.
- `references`: source path, line, target id/path, relationship type.
- `commands`: command, purpose, last_result, updated time.
- `failures`: symptom, cause, fix, evidence paths.
- `notes`: created time, topic, title, body, evidence paths.

Use FTS5 search tables when available, but keep a fallback query path for local
SQLite builds without FTS5.

## Suggested CLI

Provide one small script, for example:

```powershell
python .\tools\project-memory\index_project.py rebuild
python .\tools\project-memory\index_project.py stats
python .\tools\project-memory\index_project.py search "SomeSymbol"
python .\tools\project-memory\index_project.py note "topic" "title" "body" --evidence "path/to/file"
python .\tools\project-memory\index_project.py notes
python .\tools\project-memory\index_project.py export-notes
python .\tools\project-memory\index_project.py import-notes
```

## Markdown Export

SQLite is efficient for search, but Markdown is better for review.

Export durable notes to:

```text
tools/project-memory/NOTES.md
```

The export should say that SQLite is the local generated index and Markdown is
the reviewable long-lived memory.

## Startup Use

At the start of a task:

1. Read `AGENTS.md` and the latest handoff summary.
2. Use targeted memory search only if the task needs prior knowledge.
3. Query by symbol, path, topic, error, or feature name.
4. Read small results with evidence paths.
5. Open only the exact source files needed for the task.

Do not use SQLite memory as an excuse to load more context than the task needs.
