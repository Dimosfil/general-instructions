# Changelog

Accepted changes for the shared instruction library.

## 2026.05.16

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
