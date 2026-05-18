# WorkNest Task Manager Adapter

Use this reference only when the project has enabled the `worknest` manager or
the user explicitly asks to connect WorkNest.

## Configuration

Store non-secret WorkNest settings in `tools/project-memory/task-managers.json`:

- `id`: `worknest`
- `enabled`: `true` or `false`
- `base_url`: WorkNest API URL from the project config
- `workspace`: WorkNest workspace slug or name, if known
- `project`: WorkNest project slug, board, or list, if known
- `intake_mode`: `raw` for the current HTTP intake MVP
- `default_status`: optional default status for newly created tasks

Do not store API tokens, cookies, passwords, or private workspace data in the
shared instruction files or committed project memory.

## Current Intake MVP

The current WorkNest working version exposes a minimal raw HTTP intake for
external agents.

Known commands from the WorkNest project:

```powershell
npm run check:api
npm run dev:api
```

Known endpoints:

- `GET /health`
- `POST /agent-intake/raw`
- `GET /agent-intake/raw`
- `GET /agent-intake/raw/:id`

Raw intake payloads are stored under `storage/agent-intake/raw/` in the WorkNest
project and may contain user-supplied data. Do not commit, print, or log full
raw payloads by default.

Future WorkNest storage stages:

- `storage/agent-intake/parsed/`
- `storage/agent-intake/routed/`
- `storage/agent-intake/rejected/`

The intake API is intentionally neutral. Do not bind an intake item directly to
a project or folder unless the user explicitly asks. Parser/router stages should
later convert raw envelopes into normalized events and routed candidates.

## Mapping

Map the common plan model to WorkNest concepts using the project-owned names:

- Plan item `title` -> WorkNest task title.
- Plan item `description` -> WorkNest task description or notes.
- Plan item `status` -> WorkNest board column or task state.
- Plan item `priority` -> WorkNest priority when available; otherwise use a
  label.
- Plan item `owner` -> WorkNest assignee when the user provides an exact name.
- Plan item `labels` -> WorkNest tags or labels.
- Plan item `parent` -> WorkNest epic, parent task, or project section.

When WorkNest field names differ in a project, prefer the project's existing
board/list vocabulary over these defaults.

## Read Plan

When reading from WorkNest:

1. Identify the workspace/project from project config or ask the user.
2. Fetch only the relevant board, list, epic, or task set.
3. Convert tasks into the common plan model.
4. Preserve WorkNest IDs and URLs in `external`.
5. Summarize imported tasks without dumping the whole manager export.

## Write Plan

When writing to the current WorkNest intake:

1. Prefer `POST /agent-intake/raw` with a compact payload containing:
   - `agent`
   - `type`
   - `title` or `body`
   - optional `source`
   - optional `metadata` or `tags`
2. Use `type: "task"` for task candidates unless the plan item is clearly an
   idea, note, report, project candidate, decision, or unknown.
3. Treat the raw intake response as a receipt, not as proof that a WorkNest card
   exists.
4. Do not auto-edit WorkNest project files. The parser/router and later
   accept/reject flow decide what becomes a real card.

When writing to a future concrete WorkNest task API:

1. Match existing tasks by WorkNest ID first, then by exact title only if the
   user accepts the risk of title collisions.
2. Create missing tasks only after showing a concise preview.
3. Update changed fields while preserving WorkNest-only metadata.
4. Ask before closing, deleting, reassigning, or bulk-moving tasks.

## Unknowns

The current shared adapter knows only the raw intake MVP. It does not yet define
concrete card, board, or accept/reject APIs. Use project runbooks,
official WorkNest docs, configured MCP connectors, browser automation, or
user-provided export files when those surfaces become available.
