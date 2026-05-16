# Agent Recommended General Instructions Updates

Date: 2026-05-14
Target repository: `D:\AI\general-instructions`
Audience: future AI agents maintaining the reusable instruction library

## Summary

Add an explicit workflow for proposing improvements to shared/general
instructions from any project. Future agents should not forget the shared
instruction repository when it exists, and should have a clear fallback when it
does not.

## Recommended Changes

### 1. Add a shared instruction update destination rule

Suggested target files after review:

- `GENERAL_DEVELOPMENT_PLAYBOOK.md`
- `AGENTS.md`
- `templates/AGENTS.template.md`
- `templates/AGENT_WORKING_AGREEMENTS.template.md`

Suggested rule:

```md
## Shared Instruction Updates

When a project reveals a reusable improvement to agent instructions, workflows,
templates, or checklists:

- First check whether the shared instruction repository exists at
  `D:\AI\general-instructions\`.
- If it exists, write the proposed update to:

  ```text
  D:\AI\general-instructions\updates\
  ```

- Name the file:

  ```text
  YYYY-MM-DD_HH-mm-ss_AGENT_RECOMMENDED_GENERAL_INSTRUCTIONS_UPDATES.md
  ```

- Treat files in `updates/` as intake recommendations, not automatically
  accepted instructions.
- Keep project-specific details out of reusable instructions unless they are
  clearly marked as examples.
- If `D:\AI\general-instructions\` does not exist, create an appropriate local
  project folder for instruction recommendations, such as:

  ```text
  tools/instruction-updates/
  ```

  or, if the project already has an agent-memory area:

  ```text
  tools/project-memory/instruction-updates/
  ```

- Store the recommendation there using the same dated filename pattern.
- Do not add the shared instruction repository as a project dependency,
  package, submodule, symlink, or runtime reference unless the user explicitly
  asks for that.
- Do not rely on chat history for reusable instruction improvements. Write
  them to the durable update destination.
```

### 2. Add a task planning workflow recommendation

Suggested target files after review:

- `GENERAL_DEVELOPMENT_PLAYBOOK.md`
- `templates/AGENT_WORKING_AGREEMENTS.template.md`

Suggested rule:

```md
## Task Planning Workflow

For analysis, refactoring, migration, or multi-step implementation tasks:

- Before editing code, create or update a concise task checklist in the
  project's durable planning location.
- For project-wide or ongoing work, use a shared pending/task file such as
  `tools/project-memory/pending-tasks.md`.
- For a large focused task, create a dedicated Markdown plan in
  `tools/project-memory/` with a clear task name.
- The checklist should include:
  - goal;
  - planned changes;
  - execution order;
  - risks or dependencies;
  - verification steps.
- Track progress while working:
  - `⬜` not started;
  - `🔄` in progress;
  - `✅` done;
  - `⚠️` blocked or needs attention.
- Update the checklist as meaningful steps are completed.
- After implementation, record important verified findings in project memory.
- Add or update test cases when a behavior was manually verified or a
  regression risk was covered.
- Run the relevant checks before committing, pushing, or handing off.
- Keep planning files concise and task-relevant. Do not store full diffs, large
  logs, generated outputs, secrets, credentials, or private production data.
```

### 3. Add a starter pending-tasks template to new project setup

Suggested target files after review:

- `checklists/NEW_PROJECT_AGENT_SETUP.md`
- `templates/project-memory-README.template.md`
- optionally a new `templates/pending-tasks.template.md`

Suggested starter content:

```md
# Pending Tasks

Use this file for active project-wide plans and multi-step work.

Status markers:

- ⬜ not started
- 🔄 in progress
- ✅ done
- ⚠️ blocked or needs attention
```

## Rationale

This keeps reusable instruction improvements out of chat-only memory and gives
agents one predictable place to put recommendations. It also gives projects
without `D:\AI\general-instructions\` a sensible local fallback until a better
automation path is designed.

The task planning workflow prevents large analysis/refactor tasks from becoming
implicit chat plans. Future agents can resume from durable project memory,
understand what was planned, see what was completed, and run the remaining
checks without rediscovering the work.
