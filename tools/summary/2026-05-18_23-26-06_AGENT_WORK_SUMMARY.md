# Agent Work Summary

Date: 2026-05-18 23:26:06 Europe/Moscow

## Current State

The `general-instructions` repository is on branch `main`. The latest pushed
commit is `4c8116e Require project-local task manager API endpoints`.

The current accepted instruction-kit version is `2026.05.18.13`.

## What Changed

- Clarified that the short command prefix is `gi`, not `GAI`, and that copied
  instruction kits use `gi` as the local command surface in each project.
- Clarified that `gi` primarily exists for token economy and RAG-style context
  restoration through local instructions, summaries, targeted searches, accepted
  migrations, and project memory.
- Added guidance for projects to collect reusable experience for `gi`: workflows,
  repeated failures, token-saving tactics, startup retrieval improvements, and
  instruction improvements.
- Accepted the task-manager endpoint recommendation from
  `updates/2026-05-18_task-manager-project-endpoints.md`.
- Added migration `2026.05.18.13__require_project_local_task_manager_api_endpoints`
  requiring project-local task-manager API endpoints and workflow-specific
  capability checks.
- Updated task-manager skill docs, WorkNest adapter docs, task-manager config
  template, project templates, commands, changelog, and version metadata.

## Commands Run

- `git status --short`
- `git diff --stat`
- `git diff --check`
- `git diff --cached --check`
- `Get-Content ... | ConvertFrom-Json | ConvertTo-Json -Depth 8`
- `git add ...`
- `git commit ...`
- `git push origin main`
- `git log -3 --oneline`

## Verification

- `git diff --check` passed before commits.
- `git diff --cached --check` passed before commits.
- `templates/instruction-kit.template.json` validated as JSON.
- `templates/task-managers.template.json` validated as JSON.
- Changes were committed and pushed to `origin/main`.

## Known Failures Or Caveats

- PowerShell/Git reported LF-to-CRLF warnings for Markdown and JSON files; no
  whitespace errors were reported by `git diff --check`.
- One untracked intake file remains outside the commits:
  `updates/2026-05-18_instruction-kit-apply-should-not-record-before-file-application.md`.
- `rg` failed earlier in this environment with `Access is denied`; PowerShell
  targeted searches were used instead.

## Next Best Steps

- Review and decide whether to accept or defer
  `updates/2026-05-18_instruction-kit-apply-should-not-record-before-file-application.md`.
- If accepted, add a focused migration and update version/changelog/templates as
  needed.
- If no longer needed, leave it as intake or ask the user whether to remove it.

## Git Status Snapshot

```text
?? updates/2026-05-18_instruction-kit-apply-should-not-record-before-file-application.md
```
