# User-Reported Agent Bug Log

This maintenance-only log records recurring agent-rule failures reported by the
user. It is intake for improving the shared instruction library, not runtime
context for consuming projects.

Keep entries compact. Remove secrets, credentials, private data, and incidental
project details unless a path or command is necessary evidence. A source project
or screenshot mentioned here is provenance only; it is not permission to inspect
or edit that project.

## Entries

### 2026-07-04: GI rule bugs need command-based intake and repair

- Symptom: user wants to report logical GI rule errors through a short command
  instead of manually copying screenshots, text, and context into this
  repository, and wants a separate command that tells the agent to repair the
  rule gap.
- Evidence summary: user requested `gi ошибка` for evidence intake and
  `gi ошибка фикс` for fixing, plus a first-new-chat operation that checks
  accepted migrations before normal work.
- Likely rule gap: existing bug-log guidance allowed recording reported
  failures, but did not define user-facing GI commands for collecting available
  evidence, separating intake from repair, or running a quiet startup migration
  check on first concrete chat tasks.
- Privacy review: no screenshots, secrets, raw logs, credentials, private
  project files, or external paths were copied into this log.
- Status: accepted as shared-rule improvement in
  `2026.07.04.7__add_gi_error_intake_and_startup_update_check`.

### 2026-07-04: Project outputs and one-off work keep drifting into tooling folders

- Symptom: user reports that project work results, artifacts, scripts, and
  related output repeatedly end up under `tools/`, and asks why accepted rules
  stop being followed.
- Evidence summary: user-provided screenshot shows an agent treating
  `tools/deploy/` scripts and deploy maps as central project operation assets,
  while the user calls out the broader recurring issue of product artifacts and
  work results being stored in tooling areas.
- Likely rule gap: existing rules separated project memory from raw artifacts
  and warned against product-specific hard-code in development tools, but did
  not state strongly enough that `tools/` itself is not the default storage area
  for generated product output or selected-run artifacts.
- Privacy review: no secrets, credentials, production data, or private file
  contents were copied into this log. Concrete local project path omitted.
- Status: accepted as shared-rule improvement in
  `2026.07.04.3__log_user_reported_agent_bugs_and_tools_artifact_boundary`.
