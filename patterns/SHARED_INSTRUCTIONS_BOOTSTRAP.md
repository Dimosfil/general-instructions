# Shared Instructions Bootstrap

Use this when a user starts a new project by giving a path to the shared
instruction library, for example:

```text
Connect shared instructions: D:\AI\general-instructions
```

Also use this when the user asks to update from a shared instruction library but
the current project does not yet have `tools/project-memory/instruction-kit.json`,
for example:

```text
Обновись из D:\AI\general-instructions\
```

## Meaning

This command means: read the shared instruction library and deploy a local
instruction kit into the current project.

It does not mean:

- add the shared folder as a dependency
- add it as a package
- add it as a submodule
- create a symlink
- create a runtime reference
- create only a thin `AGENTS.md` that points back to the shared library

## Required Behavior

1. Read the shared library's `AGENTS.md`, `USER_GUIDE.md`, `INDEX.md`, and
   relevant templates.
2. Create or adapt local project files from templates:
   - root `AGENTS.md`
   - `tools/AGENT_WORKING_AGREEMENTS.md`
   - `tools/AGENT_RUNBOOK.md`
   - `tools/project-memory/README.md`
   - `tools/project-memory/STUDY_PLAN.md`
   - `tools/summary/`
   - `tools/agent-start.ps1`
3. Add agent-memory ignore rules to the local `.gitignore` when appropriate.
4. Keep the local files project-owned and editable.
5. Mention the shared library only as the source used for bootstrapping, not as a
   live dependency.
6. Record the copied baseline in `tools/project-memory/instruction-kit.json`
   with included migrations marked as already applied.
7. Stop after setup and ask what the user wants to do next.

## Token Rules

- Do not copy every shared document into the project.
- Use the templates and checklist, not a full dump of the library.
- Do not read `updates/`; it is maintenance-only for `general-instructions`.
- Do not run broad checks, builds, UI inspection, or zip packaging unless the
  user asks.

## If Files Already Exist

If local instruction files already exist:

- preserve project-specific content
- merge missing rules carefully
- avoid overwriting without reading the target file first
- summarize what was created or updated
