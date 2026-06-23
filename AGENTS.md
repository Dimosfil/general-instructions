# Agent Instructions For This Repository

This is the lightweight runtime entrypoint for the shared instruction library.
Detailed rules live in focused modules under `patterns/AGENTS_RUNTIME/` so agents
can load only the context needed for the current task.

## Project Purpose

Maintain reusable, project-agnostic AI-agent instructions, templates, patterns,
checklists, and migration metadata for projects that copy this kit.

## Loading Contract

- Start with this file.
- Read only the modules needed for the current request.
- Before acting on a concrete task, select and read the matching module(s);
  this entrypoint alone is enough only for greetings or status-neutral replies.
- For broad or unclear work, read `patterns/AGENTS_RUNTIME/01-purpose.md`,
  `patterns/AGENTS_RUNTIME/03-rule-precedence.md`,
  `patterns/AGENTS_RUNTIME/06-tool-usage-and-token-economy.md`, and the most
  relevant task module.
- If a task crosses topics, read every matching module before acting.
- Keep behavior compatible with the previous monolithic `AGENTS.md`; this split
  changes retrieval shape, not the accepted rules.

## Core Safety

- Treat safety, secrets, destructive operations, and repository scope as highest
  priority.
- Do not add secrets, private project data, generated noise, or unrelated dirty
  worktree changes to shared instructions.
- Keep reusable guidance project-agnostic; project-specific behavior belongs in
  that project's local instructions, docs, runbook, or project memory.

## Runtime Module Routing

- Repository purpose, RAG startup, project memory, handoff summaries, connected
  projects, and shared-rule propagation: `patterns/AGENTS_RUNTIME/01-purpose.md`
- Repository map: `patterns/AGENTS_RUNTIME/02-repository-map.md`
- Rule precedence and scope arbitration: `patterns/AGENTS_RUNTIME/03-rule-precedence.md`
- Authoring reusable rules, configuration boundaries, code quality, stack
  inventory, and batch verification: `patterns/AGENTS_RUNTIME/04-content-and-authoring.md`
- Windows shell and networking policy: `patterns/AGENTS_RUNTIME/05-windows-command-policy.md`
- Token economy, verification command lookup, `gi refactor`, feature contracts,
  and large-output handling: `patterns/AGENTS_RUNTIME/06-tool-usage-and-token-economy.md`
- Startup, restore, project goal, bug evidence, PDF inspection, repository
  cleanup, filesystem boundaries, and first-message handling:
  `patterns/AGENTS_RUNTIME/07-startup-and-scope.md`
- Config-service, service guide/contract lookup, task manager commands, sprint
  commands, and web-service port registration:
  `patterns/AGENTS_RUNTIME/08-config-service-and-task-manager.md`
- FTP deploy, restart/reboot, first test, full test, default reset, installer
  packaging, SQL/vector inspection, and project/RAG rebuild commands:
  `patterns/AGENTS_RUNTIME/09-project-operation-commands.md`
- Nested repositories, private local app data, product-plan intent signals, and
  missing required entities:
  `patterns/AGENTS_RUNTIME/10-private-scope-and-missing-context.md`
- Project, commit, task, and response language preferences:
  `patterns/AGENTS_RUNTIME/11-language-preferences.md`
- UI focus, app launch focus, and frontend verification expectations:
  `patterns/AGENTS_RUNTIME/12-ui-and-focus.md`
- Progress-update style: `patterns/AGENTS_RUNTIME/13-progress-updates.md`
- Update intake and `updates/` handling: `patterns/AGENTS_RUNTIME/14-update-intake.md`
- Verification policy: `patterns/AGENTS_RUNTIME/15-verification.md`
- Git policy: `patterns/AGENTS_RUNTIME/16-git-policy.md`

## Library Entrypoints

- `README.md`: human-facing overview and high-level entry points.
- `INDEX.md`: catalog of shared instructions and reusable files.
- `COMMANDS.md`: compact user-facing command index.
- `GENERAL_DEVELOPMENT_PLAYBOOK.md`: baseline project workflow.
- `templates/AGENTS.template.md`: copied project-local runtime entrypoint.
