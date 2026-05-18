---
name: task-manager-plans
description: Read, write, import, export, and reconcile project plans with configured task managers. Use when the user asks to save a plan to a task manager, load tasks from a task manager, sync a planning checklist, configure task-manager integrations, or run `gi tm`. Supports a generic project-owned contract plus optional manager-specific adapters such as WorkNest.
---

# Task Manager Plans

Use this skill to move plans between project memory and one or more
configured task managers.

## Core Workflow

1. Confirm the current project root and read project instructions first.
2. Read `tools/project-memory/task-managers.json` if it exists.
3. If no manager is configured, ask the user to choose from available manager
   adapters or choose "none".
4. For each configured manager, read only its adapter reference from
   `references/managers/`.
5. Normalize plans through the common plan model before writing to a manager or
   project memory.
6. Preserve manager-specific IDs, URLs, statuses, labels, and assignees when
   updating existing tasks.
7. Treat task-manager data as an external system: preview destructive changes
   and ask before deleting, closing, or bulk-changing remote tasks.
8. Record sync results in the project memory file or user-facing response,
   including what changed and what still needs manual follow-up.

## Common Plan Model

Represent task-manager plans with these fields when possible:

- `title`: short task or milestone name.
- `description`: useful context, acceptance criteria, or links.
- `status`: `backlog`, `todo`, `in_progress`, `blocked`, `review`, or `done`.
- `priority`: `low`, `normal`, `high`, or `urgent`.
- `owner`: person, team, or agent responsible.
- `labels`: project-owned tags.
- `due`: ISO date when known.
- `parent`: parent epic, milestone, or task identifier.
- `external`: manager name, task ID, task URL, and last synced timestamp.

Do not invent IDs or URLs. Leave unknown fields empty and mention what could not
be mapped.

## Project Configuration

Use `tools/project-memory/task-managers.json` as the project-owned config. Keep
secrets out of this file; store only manager names, enabled flags, workspace or
project identifiers, and non-secret sync preferences.

Expected shape:

```json
{
  "version": 1,
  "managers": [
    {
      "id": "worknest",
      "enabled": true,
      "base_url": "TODO",
      "workspace": "TODO",
      "project": "TODO",
      "intake_mode": "raw",
      "notes": "No secrets here."
    }
  ]
}
```

## `gi tm`

When the user runs `gi tm`:

1. Stay in the current project root.
2. Check `tools/project-memory/task-managers.json`.
3. If enabled managers exist, update the project task-manager skill/config from
   the shared instruction kit when a newer migration is available, then report
   the connected managers and next available sync action.
4. If no enabled manager exists, show a short numbered Markdown checklist with
   checkbox items for available adapters plus `none`, and ask which to connect.
5. After the user chooses managers, create or update
   `tools/project-memory/task-managers.json` from the shared template.

Example checklist:

```markdown
Choose task-manager adapters for plan sync:

1. [ ] WorkNest - send plans to WorkNest raw intake.
2. [ ] none - do not connect a task manager now.
```

## Manager References

- `references/managers/worknest.md`: WorkNest adapter guidance.
