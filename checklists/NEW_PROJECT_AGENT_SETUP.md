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
- [ ] Decide whether the project needs local agent memory SQLite/index.
- [ ] If SQLite memory is used, ignore the generated database and commit only
  scripts/schema/docs/Markdown exports.
- [ ] Add `tools/summary/`.
- [ ] Add a startup command such as `tools/codex-start.ps1`.
- [ ] Define run, test, build, smoke-check, and log-inspection commands.
- [ ] Review `.gitignore` for logs, caches, local databases, build outputs, and
  secrets.
- [ ] Write the first handoff summary after meaningful setup work.
