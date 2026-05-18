# New Project Agent Setup Checklist

Use this when preparing a repository for AI-agent collaboration.

- [ ] Add root `AGENTS.md` from `templates/AGENTS.template.md`.
- [ ] Add `README.md` note: `For AI agents: read AGENTS.md first.`
- [ ] Add `.github/copilot-instructions.md`, `CLAUDE.md`, or `GEMINI.md` only
  as small redirects when needed.
- [ ] Add `tools/AGENT_WORKING_AGREEMENTS.md`.
- [ ] Add `tools/AGENT_RUNBOOK.md`.
- [ ] Add `tools/project-memory/README.md`.
- [ ] Add `tools/project-memory/STUDY_PLAN.md`.
- [ ] Copy or adapt `templates/pending-tasks.template.md` into
  `tools/project-memory/pending-tasks.md`.
- [ ] Copy or adapt `templates/instruction-kit.template.json` into
  `tools/project-memory/instruction-kit.json`.
- [ ] Copy or adapt `templates/git-preferences.template.json` into
  `tools/project-memory/git-preferences.json`.
- [ ] Copy or adapt `templates/select-git-commit-languages.template.ps1` into
  `tools/select-git-commit-languages.ps1`.
- [ ] Do not run the commit-language selector during bootstrap unless the user
  explicitly asks; keep the default `git-preferences.json`.
- [ ] Copy or adapt `templates/check-instruction-kit-updates.template.ps1` into
  `tools/check-instruction-kit-updates.ps1`.
- [ ] Confirm instruction updates use accepted `migrations/`, `VERSION.md`, and
  `CHANGELOG.md`, not `updates/`.
- [ ] Confirm `Обновись из general-instructions` is idempotent: bootstrap/init
  first when `tools/project-memory/instruction-kit.json` is missing, otherwise
  apply only pending migrations.
- [ ] Decide whether the project needs reusable skills. If yes, use
  `patterns/SKILL_MODULES.md` and `templates/SKILL.template.md`.
- [ ] Ask whether to connect task-manager plan sync. Offer available adapters
  from `skills/task-manager-plans/references/managers/` plus `none`.
- [ ] If task-manager sync is enabled, copy `skills/task-manager-plans/` and
  create `tools/project-memory/task-managers.json` from
  `templates/task-managers.template.json`.
- [ ] If the project builds an agentic runtime or model-driven tool loop, use
  `patterns/AGENT_HARNESS_RUNTIME.md` for harness boundaries, permissions,
  compaction, connectors, observability, and evals.
- [ ] Decide whether the project needs local agent memory SQLite/index.
- [ ] If SQLite memory is used, ignore the generated database and commit only
  scripts/schema/docs/Markdown exports.
- [ ] Add `tools/summary/`.
- [ ] Copy or adapt `templates/agent-start.template.ps1` into
  `tools/agent-start.ps1`.
- [ ] Confirm the startup script reports instruction-kit updates only from
  accepted release artifacts such as `VERSION.md` and `CHANGELOG.md`, not from
  `updates/`.
- [ ] Add agent-memory ignore rules from
  `templates/gitignore-agent-memory.template` to `.gitignore`.
- [ ] Decide whether the project uses SQLite memory, Markdown-only memory, or
  both.
- [ ] Confirm startup retrieval loads only task-relevant context.
- [ ] Confirm multi-step tasks have a concise durable checklist before editing.
- [ ] Define run, test, build, smoke-check, and log-inspection commands.
- [ ] Review `.gitignore` for logs, caches, local databases, build outputs, and
  secrets.
- [ ] Write the first handoff summary after meaningful setup work.
