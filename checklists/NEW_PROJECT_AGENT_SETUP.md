# New Project Agent Setup Checklist

Use this when preparing a repository for AI-agent collaboration.

- [ ] Add root `AGENTS.md` from `templates/AGENTS.template.md`.
- [ ] Add `README.md` note: `For AI agents: read AGENTS.md first.`
- [ ] Add `.github/copilot-instructions.md`, `CLAUDE.md`, or `GEMINI.md` only
  as small redirects when needed.
- [ ] Add `tools/CODEX_WORKING_AGREEMENTS.md`.
- [ ] Add `tools/CODEX_RUNBOOK.md`.
- [ ] Add `tools/project-memory/README.md`.
- [ ] Add `tools/project-memory/STUDY_PLAN.md`.
- [ ] Copy or adapt `templates/pending-tasks.template.md` into
  `tools/project-memory/pending-tasks.md`.
- [ ] Copy or adapt `templates/instruction-kit.template.json` into
  `tools/project-memory/instruction-kit.json`.
- [ ] Decide whether the project needs local agent memory SQLite/index.
- [ ] If SQLite memory is used, ignore the generated database and commit only
  scripts/schema/docs/Markdown exports.
- [ ] Add `tools/summary/`.
- [ ] Copy or adapt `templates/codex-start.template.ps1` into
  `tools/codex-start.ps1`.
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
