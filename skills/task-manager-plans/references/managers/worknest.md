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

`base_url` is required when enabling WorkNest. During setup, get it from the
project instructions, environment/config, or the user, then write it to
`tools/project-memory/task-managers.json`. Do not leave `base_url` as `TODO`.

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

## Sprint Workflow For Markdown Projects

When a WorkNest-style Markdown project receives an accepted plan, treat the plan
as a sprint. The sprint folder is the execution unit, and numbered task files
define the order in which agents should work.

Create a unique dated sprint folder directly inside the target project:

```text
projects/<project-id>/YYYY-MM-DD_<sprint-slug>/
```

Do not create a shared `sprints/` container by default. Each active sprint is
its own project-level folder. Completed sprint folders can later be moved to the
project archive.

Add `sprint.md` inside the sprint folder with:

- sprint title;
- status;
- project id;
- start date;
- source plan or source request;
- sprint goal;
- ordered task list.

Split the plan into numbered task files:

```text
001_short-task-title.md
002_short-task-title.md
003_short-task-title.md
```

Each task file should include at minimum:

```text
# Human-readable task title

Status: todo
Sprint: YYYY-MM-DD_<sprint-slug>
Order: 001
Project: <project-id>
Agent: <agent-or-unassigned>
SourcePlanId: <source-plan-id>
DependsOn: none
Tags: [...]
```

Agents should execute sprint task files in ascending `Order`. To get the next
task, find the first task file in order whose `Status` is `todo` or `ready`.

When a task is completed, update the task file status to `done` and append a
concise result or completion section.

Testing tasks can be added later. Do not block the initial sprint workflow on a
full testing model.

## Active Sprint Execution

Use this workflow for `gi старт спринт`, `gi start sprint`, or equivalent
commands.

Find active sprints by scanning WorkNest project folders for `sprint.md` files
whose status is `active`, `in_progress`, or equivalent project vocabulary. If
the project has a configured current project id, search that project first.

If exactly one active sprint exists, take it in work. If there are no active
sprints or several active sprints, show the concise list and ask the user to
choose.

For the selected sprint:

1. Read `sprint.md`.
2. List task files matching the numbered task pattern, such as
   `001_short-task-title.md`.
3. Sort tasks by `Order` or numeric filename prefix.
4. Find tasks whose `Status` is `todo` or `ready`.
5. Before starting a task, update its `Status` to `in_progress` unless the
   project uses another active-work status.
6. Execute the task according to its file instructions and the project rules.
7. On success, update `Status` to `done` and append a concise completion/result
   section with changed files, checks, and important caveats.
8. Continue to the next `todo` or `ready` task in order.

Stop the sprint run and report the blocker when a task needs user input, has
missing access, conflicts with project instructions, requires a destructive
action, or fails verification in a way that should not be papered over.

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

1. Require `base_url` in `tools/project-memory/task-managers.json`; ask for it
   before sending if missing or still `TODO`.
2. Prefer `POST /agent-intake/raw` with a compact payload containing:
   - `agent`
   - `type`
   - `title` or `body`
   - optional `source`
   - optional `metadata` or `tags`
3. Use `type: "task"` for task candidates unless the plan item is clearly an
   idea, note, report, project candidate, decision, or unknown.
4. Treat the raw intake response as a receipt, not as proof that a WorkNest card
   exists.
5. Do not auto-edit WorkNest project files. The parser/router and later
   accept/reject flow decide what becomes a real card.

When the user explicitly asks to turn a plan into a WorkNest Markdown sprint,
use the sprint workflow above instead of treating the plan as only a raw intake
receipt.

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
