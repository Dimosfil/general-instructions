# Changelog

Accepted changes for the shared instruction library.

## 2026.05.16

- Clarified that `gi` command responses must stay scoped to the shared
  instruction-kit command and must not resume an older product task unless the
  user explicitly asks.
- Made instruction-kit update checks tolerant of unavailable saved shared
  library paths, such as `D:\AI\general-instructions` in environments without a
  `D:` drive; agents should use `GENERAL_INSTRUCTIONS_HOME`, an explicit command
  path, or ask for the shared library path instead of failing hard.
- Added `gi саммари` / `gi summary` as a short shared-instruction command that
  writes a handoff summary file under `tools/summary/` instead of only replying
  in chat.
- Clarified that ambiguous commit-message language selection prompts should use
  a concise Markdown checklist with current selections, not a prose-only list.
- Added the short `gi` chat-command prefix for shared instruction-kit commands,
  such as `gi обновись`, `gi init D:\AI\general-instructions\`, and
  `gi язык коммита: Russian`.
- Clarified that agents must not infer additional commit-message languages from
  the user's UI or message language; ambiguous requests should get a short
  clarification question.
- Clarified that reports about commit-language preference updates should mention
  `tools/project-memory/git-preferences.json` as a plain path, not a malformed
  placeholder markdown link.
- Added short user-facing agent prompts for bootstrapping, updating, restoring
  context, configuring commit-message languages, and requesting commits.
- Clarified that `Обновись из D:\AI\general-instructions\` is idempotent:
  bootstrap/init first when no local instruction kit exists, otherwise apply
  only pending migrations.
- Clarified that chat requests to configure commit-message languages should
  update `tools/project-memory/git-preferences.json` directly instead of only
  telling the user to run a PowerShell helper.
- Added instruction-kit migrations with `patterns/INSTRUCTION_KIT_MIGRATIONS.md`
  and accepted migration files under `migrations/`.
- Added `templates/check-instruction-kit-updates.template.ps1` for project-level
  update checks.
- Added `patterns/GIT_WORKFLOW.md` with explicit commit-request policy, dirty
  worktree handling, and commit-message language rules.
- Added project-local commit-message language preferences with English as the
  primary language and optional Russian, Spanish, German, or French additions.
- Added `templates/git-preferences.template.json` and
  `templates/select-git-commit-languages.template.ps1`.
- Updated startup restore to show the current commit-message language
  preferences and how to change them.
- Added the skill module concept, including `patterns/SKILL_MODULES.md` and
  `templates/SKILL.template.md`.
- Updated instruction-kit version parsing to support multiple releases on the
  same date.
- Renamed active project templates and copied project paths from tool-specific
  names to generic agent names.
- Updated startup, runbook, working-agreement, summary, checklist, bootstrap,
  and index guidance to use agent-neutral wording.
- Bumped copied instruction-kit provenance to `2026.05.16`.

## 2026.05.15

- Refactored `AGENTS.md` into focused sections for rule precedence, authoring,
  token economy, startup behavior, UI/focus, update intake, verification, and
  git policy.
- Added `patterns/FIRST_MESSAGE_HANDLING.md` for first-message title handling
  and shared-instruction bootstrap behavior.
- Reduced duplicated context-hygiene guidance in the development playbook and
  project templates.
- Generalized broad artifact guidance from zip archives to broad artifacts and
  full check matrices.
- Clarified PowerShell command examples and equivalent-command expectations for
  other shells.
- Added instruction-kit versioning artifacts for copied project instruction
  kits.
