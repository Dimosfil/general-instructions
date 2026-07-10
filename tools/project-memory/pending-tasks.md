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

Status: completed by migrations `2026.07.07.1__clarify_gi_init_github_source`
and `2026.07.10.1__harden_gi_init_bootstrap_entrypoint`.

Planned changes:

- [x] Update `patterns/SHARED_INSTRUCTIONS_BOOTSTRAP.md` with explicit source
  handling for Git repository URLs.
- [x] Update `patterns/FIRST_MESSAGE_HANDLING.md` so a first message containing
  a Git URL triggers bootstrap behavior.
- [x] Document source resolution, deterministic checkout/install behavior, and
  environment permission handling.
- [x] Add executable regression checks for URL, short repo, Markdown link, and
  local checkout forms.

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

### Full RAG Agent Platform

Goal: evolve `gi` from a file-based shared instruction library into a
token-conscious agent platform with structured memory, semantic retrieval,
observability, and optional workflow automation.

Status: architecture pattern added in `patterns/FULL_RAG_AGENT_PLATFORM.md`.
Implementation is still pending.

Target stack:

- Core orchestration: LangGraph.
- Memory: SQLite for local MVP, PostgreSQL when multi-project or multi-user
  concurrency is needed.
- RAG: Chroma for simple local MVP, Qdrant or pgvector for a service-grade
  retrieval layer.
- Monitoring: LangSmith free for traces, prompts, tool calls, and retrieval
  quality checks.
- Automation: n8n only for external workflows, schedules, notifications, or
  cross-service integrations that do not belong inside the agent core.

Missing to reach the goal:

- [x] Define product boundary: what `gi` should do as an agent platform versus
  what remains plain reusable Markdown instructions.
- [x] Define source corpus: `AGENTS.md`, `INDEX.md`, `patterns/`,
  `checklists/`, `templates/`, accepted migrations, project memory, and
  handoff summaries.
- [x] Define structured memory schema for project preferences, task state,
  accepted decisions, index metadata, service registry references, and audit
  events.
- [x] Choose MVP storage mode: SQLite-only, SQLite plus Chroma, or
  PostgreSQL plus Qdrant/pgvector.
- [ ] Design Markdown-aware chunking that preserves headings, file paths,
  document type, rule priority, and source links.
- [x] Define embedding metadata and chunk hash rules so only changed content is
  re-indexed. Provider-specific model selection stays project-local.
- [ ] Build retrieval flow with metadata filters, precedence rules,
  deduplication, token budget limits, and source attribution.
- [ ] Add reranking or second-pass relevance checks for ambiguous queries.
- [ ] Model the agent workflow in LangGraph: startup restore, task routing,
  retrieval, tool execution, verification, memory writeback, and failure
  handling.
- [ ] Connect LangSmith tracing for graph runs, retrieved chunks, prompt
  packets, tool calls, errors, and evaluation samples.
- [ ] Create retrieval quality tests for `gi start`, `gi restore`, `gi config`,
  `gi install`, commit workflow, update intake, and screenshot/error analysis.
- [ ] Define n8n integration boundaries for notifications, scheduled checks,
  external issue/task sync, and long-running workflows.
- [x] Document security rules for secrets, user-local data, private project
  memory, service credentials, and cross-project retrieval isolation.
- [x] Add operating docs for indexing, reindexing, backup, migration, and
  troubleshooting.

### Development Artifact Cleanup

Goal: remove stale development artifacts from the shared library.

- [x] Remove stale handoff summaries from `tools/summary/` (5 files).
- [x] Update status of completed tasks in this file.
