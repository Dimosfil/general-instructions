# Agent Work Summary

Date: 2026-05-19 22:11:52 +03:00

## Current State

The repository is `https://github.com/Dimosfil/general-instructions.git` on branch `main`.
Working tree was clean immediately after the latest push.

Current accepted instruction-kit version is `2026.05.19.7`.

Latest commit:

```text
f7e3e4f Tighten agent boundary and progress rules
```

## What Changed

- Added accepted migrations:
  - `2026.05.19.5__keep_progress_updates_phase_level`
  - `2026.05.19.6__tighten_project_study_and_nested_scope`
  - `2026.05.19.7__protect_private_local_app_data`
- Tightened progress-update guidance so agents report phase-level updates and do
  not duplicate automatic UI tool counters.
- Tightened first-pass project study guidance so agents start from local
  instructions, README, manifests, and config entry points before recursive
  scans.
- Added nested checkout and vendored tree scope guidance.
- Added private local data guidance for `.codex`, `.cursor`, IDE logs, browser
  profiles, shell history, application SQLite databases, local app logs, and
  personal telemetry outside the project root.
- Clarified that `apps.txt`, product plans, summaries, and task-manager notes
  are intent signals only, not permission to inspect private local data sources.
- Updated `CHANGELOG.md`, `VERSION.md`, templates, and instruction-kit metadata
  to version `2026.05.19.7`.
- Committed and pushed the instruction-kit update to `origin/main`.

## Commands Run

- `git status --short`
- `git branch --show-current`
- `git remote -v`
- `git diff --stat`
- `git diff --cached --stat`
- `git diff --check --cached`
- JSON validation with `ConvertFrom-Json`
- migration count comparison
- `git add ...`
- `git commit ...`
- `git push origin main`
- `git log -3 --oneline`
- `Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'`

## Verification

- `templates/instruction-kit.template.json` validated as JSON.
- Migration files and `applied_migrations` in
  `templates/instruction-kit.template.json` were synchronized: `34 / 34`.
- `git diff --check --cached` passed.
- Push succeeded:

```text
main -> main
```

## Known Failures Or Caveats

- Git emitted LF-to-CRLF warnings for several Markdown and JSON files. No
  whitespace errors were reported.
- `rg` was unavailable earlier in the session due to `Access denied`, so local
  PowerShell search was used instead.
- This summary file is new and was created after the push, so it is currently
  uncommitted unless committed separately later.

## Next Best Steps

- If desired, review and commit this handoff summary.
- For the next `gi старт`, restore from this summary and the clean pushed state
  at `f7e3e4f`.
- When consuming projects update from this library, apply migrations through
  `2026.05.19.7`.

## Git Status Snapshot

Before this summary file was created:

```text
clean
```
