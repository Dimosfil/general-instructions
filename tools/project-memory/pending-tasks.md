# Pending Tasks

Use this file for active project-wide plans and multi-step work.

Keep entries concise and task-relevant. Do not store full diffs, large logs,
generated outputs, secrets, credentials, or private production data.

## Status Markers

- `[ ]` not started
- `[~]` in progress
- `[x]` done
- `[!]` blocked or needs attention

## Tasks

### Reduce Rule Duplication

Goal: reduce maintenance risk from the same rules being duplicated across 5+
files (AGENTS.md, COMMANDS.md, patterns/, templates/).

Planned changes:

- [x] Audit template duplication in `templates/AGENTS.template.md` — removed
  ~67 lines of duplicated `gi` rules (lines 136–203), replaced with short
  cross-references.
- [x] Restructure `COMMANDS.md` — removed duplicated policy paragraphs, kept
  compact command reference with source references.
- [x] Update `DEVELOPMENT_PLAN.md` with current planned items.
- [ ] Audit remaining templates (`AGENT_RUNBOOK.template.md`,
  `AGENT_WORKING_AGREEMENTS.template.md`) for similar duplication.
- [ ] Audit `patterns/` for cross-duplication with `AGENTS.md` and
  `GENERAL_DEVELOPMENT_PLAYBOOK.md`.

### Shared Instruction Bootstrap Sources

Goal: make a new project bootstrap from either a local shared-instruction folder
or a Git repository URL.

Status: local folder bootstrap is covered. Git URL bootstrap is still pending.

Planned changes:

- [ ] Update `patterns/SHARED_INSTRUCTIONS_BOOTSTRAP.md` with explicit source
  handling for Git repository URLs.
- [ ] Update `patterns/FIRST_MESSAGE_HANDLING.md` so a first message containing
  a Git URL triggers bootstrap behavior.
- [ ] Document that Git URL access may require user approval before clone/fetch.
- [ ] Run documentation checks.

### GI Service Discovery Standard

Goal: design a reusable discovery layer so agents stop relying on changing
ports, stale UI endpoints, guessed lifecycle APIs, or project-specific service
knowledge.

Planned changes:

- [ ] Define the GI main config role: point to discovery/config sources, not
  store secrets or volatile runtime state.
- [ ] Define project-local or user-local service registry shape for task
  manager, token-lens, Telegram bot, and other agent-facing services.
- [ ] Specify a service health/discovery contract that returns service identity,
  API version, capabilities, and relevant endpoint paths.
- [ ] Document endpoint-selection rules for agents: project-local registry
  first, GI discovery pointer second, capability verification before use.
- [ ] Decide whether to recommend a stable local reverse proxy for moving
  localhost ports.
- [ ] Add mismatch handling rules for cases where `/health` works but required
  lifecycle endpoints are missing.

### Development Artifact Cleanup

Goal: remove stale development artifacts from the shared library.

- [x] Remove stale handoff summaries from `tools/summary/` (5 files).
- [x] Update status of completed tasks in this file.
