# User-Reported Agent Bug Log

This maintenance-only log records recurring agent-rule failures reported by the
user. It is intake for improving the shared instruction library, not runtime
context for consuming projects.

Keep entries compact. Remove secrets, credentials, private data, and incidental
project details unless a path or command is necessary evidence. A source project
or screenshot mentioned here is provenance only; it is not permission to inspect
or edit that project.

## Entries

### 2026-07-13: Tracked handoff file changed after a reported successful push

- Symptom: an agent reported that local and remote HEAD matched and that the
  operation had completed, while the response still exposed a newly modified
  tracked handoff-summary file.
- Evidence summary: a user-provided screenshot showed successful checks and
  matching HEAD claims together with a post-operation modified-file card.
- Likely rule gap: the Git finish workflow required pre-commit inspection but
  did not require all task writes to finish before staging or a final worktree
  check after the last mutation; matching HEAD was therefore mistaken for a
  clean worktree.
- Privacy review: no screenshot, machine-specific path, project name, commit
  identifier, private content, secrets, credentials, or raw logs were copied
  into this entry.
- Status: accepted and repaired in
  `2026.07.13.1__enforce_git_finalization_boundary`.

### 2026-07-10: Canonical GI init link misclassified as Git repository replacement

- Symptom: an agent treated `инит` with the canonical shared-instruction
  repository link as a possible project replacement or additional Git remote,
  then reported the rules active in chat without deploying the local
  instruction kit into the current project.
- Evidence summary: user-provided screenshots showed the incorrect Git/remote
  clarification and a later activation claim; the target project still lacked
  the required local `AGENTS.md` and instruction-kit metadata.
- Likely rule gap: the correct behavior existed in routed bootstrap documents,
  but the repository landing page did not expose it before request
  classification, and no deterministic installer or cross-form regression test
  enforced the workflow.
- Privacy review: no screenshots, machine-specific paths, private project
  contents, secrets, credentials, or raw logs were copied into this entry.
- Status: accepted and repaired in
  `2026.07.10.1__harden_gi_init_bootstrap_entrypoint`.

### 2026-07-06: Product source and logging architecture placed under `tools/`

- Symptom: user reports that a requested universal logging system was again
  partly placed in tooling/project-memory locations and asks for a strict rule
  defining what belongs in `tools/`.
- Evidence summary: user-provided chat excerpt says the previous work added a
  runtime logging package, plugins, tests, documentation, and an architecture
  contract, then also wrote logging-related project files under
  `tools/project-memory/`.
- Likely rule gap: existing `tools/` guidance banned generated outputs and
  one-off artifacts, but did not explicitly forbid product runtime/source
  packages, product plugin implementations, product tests, or full product docs
  from being placed under `tools/`.
- Privacy review: no secrets, credentials, private logs, production data, or
  external project file contents were copied into this log.
- Status: accepted as shared-rule improvement in
  `2026.07.06.4__strict_tools_product_boundary`.

### 2026-07-05: Startup GI update check should report zero pending migrations

- Symptom: user reports that first-request startup/update-check responses can
  say the instruction kit is current without explicitly saying whether pending
  migrations were checked and how many were found.
- Evidence summary: user-provided screenshot of a `gi обновить` style response
  shows version status and "new pending migrations нет" wording; user asked the
  rule to require reporting `0` migrations when none are pending.
- Likely rule gap: the quiet startup GI update-check rule required a compact
  status or blocker, but did not require an explicit pending migration count in
  the success status.
- Privacy review: no secrets, credentials, private data, raw logs, or external
  project files were copied into this log.
- Status: accepted as shared-rule improvement in
  `2026.07.05.1__report_zero_pending_startup_migrations`.

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
