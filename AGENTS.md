# Agent Instructions For This Repository

This repository is a shared library of reusable AI-agent instructions for current
and future projects.

## Purpose

Keep durable, project-agnostic rules, playbooks, templates, and checklists here.
Project-specific details belong in each project's own `AGENTS.md`, runbook, or
memory folder.

Keep GI agent-runtime neutral. These instructions are for any compatible AI
agent or assistant, not only Codex. Mention Codex only when a rule is about a
Codex-specific tool, folder, permission model, app surface, or workflow.

Treat this library as a token-economy and RAG-startup layer for projects that
copy it. Its short command prefix is always `gi`, not `GAI` or another alias.
Use it to restore only task-relevant context through local instructions, handoff
summaries, targeted searches, accepted migrations, and project memory instead of
broad repository reads or large chat outputs.

When a project needs retrieval that can grow beyond Markdown and SQLite FTS,
use `patterns/RAG_SYSTEM_STRUCTURE.md` and a project-local
`tools/project-memory/rag-system.json`. Keep Chroma, Qdrant, pgvector, and
similar stores behind retrieval adapters so `gi` startup, prompt assembly, and
memory writeback do not depend on one vector database.

Before enabling vector retrieval, prepare semantic-ready chunks, embedding
metadata, and a small eval set. Use `patterns/SEMANTIC_RAG_RETRIEVAL.md`, keep
generated embedding corpora and vector indexes ignored when rebuildable, and do
not mix embeddings from different models in one collection version.

Treat `gi ...` and `ги ...` forms as chat commands for the agent, not as
PowerShell commands. When the user wants a command that should be run literally
in PowerShell, require or use an explicit `PS` marker or a real PowerShell
command/script path such as `.\tools\agent-start.ps1`; do not present `gi ...`
as a terminal command.

Treat connected projects as experience sources for `gi`. When a project reveals
a reusable workflow, failure pattern, token-saving tactic, or agent instruction
improvement, capture a concise recommendation with evidence and privacy review
so this library can turn it into accepted guidance after maintenance review.

When maintaining this shared `general-instructions` repository, treat a user
request to add or accept a new reusable rule as approval to finish the accepted
instruction change end to end: update the relevant library files, verify them,
commit and push only the scoped rule changes, then run the `gi обновить` update
flow for accepted instruction-kit propagation when applicable. Do not include
unrelated dirty worktree changes, secrets, private data, or generated noise; do
not recurse into another commit/push merely because this finish rule itself was
added or run.

Accepted RAG, startup, command, workflow, and agent-safety rules must apply to
both this source repository and every consuming project. When changing an
accepted reusable rule, update the source repository's live files first, then
update the copied-project templates, accepted migrations, version/changelog, and
local instruction-kit metadata so future `gi обновить` runs can propagate the
same rule. Do not leave a rule only in `updates/`, only in a template, or only
in this repository's live `AGENTS.md`.

## Repository Map

- `README.md`: short human-facing overview.
- `INDEX.md`: catalog of reusable instruction documents.
- `GENERAL_DEVELOPMENT_PLAYBOOK.md`: baseline playbook for starting and
  maintaining projects with AI agents.
- `templates/`: copyable starter files for project repositories.
- `checklists/`: short operational checklists.

## Rule Precedence

- Treat safety, secrets, and destructive-action constraints as highest priority.
- Follow explicit user requests unless they conflict with safety or repository
  rules.
- Let project-local `AGENTS.md`, runbooks, and working agreements override these
  shared reusable rules when they are more specific.
- Use these shared rules when project-local guidance is absent or ambiguous.
- Agents may ask concise clarification questions about implementation details
  and may propose a better-fit solution, workflow, stack, algorithm, or tradeoff
  when it improves the user's stated goal.
- Prefer token economy and optimization after the correct scope is clear.

## Content And Authoring

- Keep instructions reusable across projects.
- Do not add secrets, credentials, private project data, or local machine paths
  unless the file is explicitly a local example.
- If a rule applies only to one specific project, do not put it here.
- If a feature workflow applies only to one project, keep it in that project's
  local docs or project memory. Use shared instructions only for the reusable
  rule that such contracts should exist and be respected.
- Prefer small, focused documents over one giant policy file.
- When adding a new instruction file, also add it to `INDEX.md`.
- Write instruction documents in imperative voice, with one rule per bullet when
  practical.
- Avoid long nested conditionals, filler, narration, and non-actionable prose.
- Use clear Markdown headings and copy-pasteable examples.
- Do not hard-code values that can change by deployment, user choice, runtime
  environment, host machine, service discovery, credentials, filesystem layout,
  feature flags, or operational policy. Keep application code focused on logic,
  constants, and internal defaults; move deploy/user/environment/system values
  into documented project-local configuration, environment variables, or
  service discovery records. Avoid embedding machine-specific absolute paths in
  source or shared instructions; when paths are accepted from config, resolve
  and validate them as absolute paths at the application boundary. When applying
  this rule to existing projects, audit and refactor relevant hard-coded values
  instead of only adding the rule text. Follow `patterns/CONFIGURATION_BOUNDARIES.md`.

## Windows Command Policy

- Prefer PowerShell-native networking commands such as `Invoke-RestMethod` and
  `Invoke-WebRequest` instead of `curl.exe`.
- Do not probe for `curl.exe` with `where.exe curl` or `Get-Command curl` unless
  the user explicitly asks for curl diagnostics.
- Prefer trusted helper binaries from `%USERPROFILE%\.codex\bin` before
  WindowsApps or System32 shims.
- If Windows or antivirus tools block agent commands with `Access denied`,
  trust narrow agent-owned tool folders such as `.codex\.sandbox-bin\` and
  `.codex\bin\`; do not add broad exclusions for System32 or PowerShell itself.

## Tool Usage And Token Economy

- Treat `cached input` as a symptom, not the main optimization target. Optimize
  for smaller total live context: current input plus cached context.
- Start a new session for unrelated new tasks when old context is no longer
  useful, and use compact handoff summaries instead of carrying long
  investigation history forward.
- Do not print full `git diff` output by default. Prefer `git diff --stat` and
  targeted queries for relevant files or patterns.
- For first-pass project study, read local instructions, README, manifests, and
  config entry points before building a file map. Use recursive scans only after
  a targeted search fails or the task clearly requires repository-wide
  inventory.
- When creating or running a test, smoke-check, or verification plan, verify
  exact commands, CLI flags, ports, routes, health endpoints, request payload
  fields, and environment variables from current project-local instructions,
  runbooks, manifests, config entry points, or source code. Treat handoff
  summaries, task notes, screenshots, and old chat examples as status evidence,
  not as authoritative command contracts; do not reuse stale ports, payloads, or
  flags without checking the current project.
- Do not read large files in full by default, including large `index.html`,
  bundled JS/CSS, logs, lockfiles, generated files, and build artifacts. Prefer
  targeted searches, heads, tails, or small line ranges, such as
  `Get-Content -TotalCount`, `Get-Content -Tail`, and `Select-String`.
- Command examples use PowerShell on Windows. Use equivalent head, tail,
  line-range, and targeted-search commands on other shells.
- Preserve text encodings when editing files. On Windows, do not rewrite source
  files with PowerShell pipelines such as `Get-Content ... | Set-Content ...`
  unless both read and write encodings are explicit and known correct. Prefer
  `apply_patch`, editor-native saves, or language APIs that read and write the
  file with an explicit encoding such as UTF-8. If non-ASCII text appears as
  mojibake after a command, stop, restore the last clean file version, and
  reapply only the intended small patch.
- Search for specific symbols, paths, errors, or patterns before doing broad
  repository scans.
- Before changing a feature with a recorded workflow contract, read the
  contract and preserve its user-visible sequence, branches, background work,
  loading/error states, and verification guarantees unless the user explicitly
  changes the agreement.
- For non-trivial feature work, keep the feature idea, functional description,
  workflow contract, implementation plan, sprint breakdown, task breakdown,
  definitions of done, and verification linked together. Tasks do not replace
  the feature contract: tasks say what to change, while the contract says what
  behavior must remain true.
- Do not print large logs. Prefer tails and targeted error searches.
- For verification, count or query HTML elements programmatically instead of
  printing the whole HTML document.
- Do not produce broad artifacts, such as zip archives, or run full check
  matrices unless the user explicitly asks for that scope.
- Split multi-step R&D into separate tasks when later steps do not need the
  full previous reasoning trace.
- Broader scans, longer logs, or larger check suites are acceptable for incident
  debugging, explicit user requests, release checks, or unclear failures after
  targeted searches.
- Final responses should summarize only the changes, checks, and current status;
  do not restate the full investigation context.

## Scope And Startup Behavior

- Treat short greetings, thanks, acknowledgements, and status-neutral messages
  as no-ops unless they include an explicit task, path, command, error, or
  project question. Do not run startup restore or read project files for those
  messages; reply briefly and ask what the user wants to do next.
- For `gi start`, `gi restore`, and title-only first messages, restore only the
  minimum orientation needed for the next turn: local instructions, latest
  summary metadata or relevant sections, and compact git state. Do not read full
  summaries, runbooks, memory notes, logs, or diffs unless a concrete task needs
  them.
- Do not treat remembered plans, old refactoring phases, stale task notes, or
  local commits ahead of a remote as the next action during `gi start` or
  `gi restore`. Mention them only as compact context when relevant, then ask for
  the user's current task instead of offering to continue, run, push, or finish
  them.
- Treat `init <source>`, `инит <source>`, and `инициализируй <source>` that
  point to the canonical shared-instruction Git repository
  `https://github.com/Dimosfil/general-instructions.git`, the current
  shared-instruction checkout/cache, `GENERAL_INSTRUCTIONS_HOME`, or another
  known shared-instruction source as a shared-instruction bootstrap/startup
  request, even without the `gi` prefix.
  Read the repository's local instructions and follow the documented `gi`
  bootstrap rules. Do not reinterpret that form as Git initialization, OpenCode
  setup, project creation, or skill creation unless the user explicitly names
  that action.
  Treat `инит правила <source>` the same way when `<source>` points to
  `general-instructions`. Examples such as
  `инит <path-to-general-instructions>` and
  `инит правила <path-to-general-instructions>` mean "load or initialize
  instruction rules from the existing shared-instruction source"; they never
  mean `git init`. Do not create folders, initialize `.git`, or suggest
  `npm init` / `python -m venv` for this form.
- Treat screenshots, logs, pasted errors, or other bug evidence as requests for
  analysis first. Explain the likely issue and ask what action the user wants
  before editing files, unless the user explicitly says to fix it, such as
  `fix`, `почини`, or `gi почини`.
- When the user explicitly says to fix an issue, treat that as approval to take
  required low-risk implementation and verification actions without an extra
  confirmation prompt, including rebuilding, restarting the affected local
  process, or closing a currently running app window that blocks single-instance
  verification. Still ask before destructive actions, possible data loss,
  credential or secret handling, external system changes, or unrelated scope.
- When a user provides a PDF path or attachment and asks to inspect, verify, or
  reread it, read the actual PDF before relying on memory, chat fragments, or
  screenshots. First confirm the file exists and page count/metadata when cheap,
  then try local text extraction with available PDF tools or libraries. On this
  Windows setup, if plain `python` is blocked by user-profile AppData access,
  prefer `uv run --with pypdf python -c "..."` as a non-project fallback for
  extracting page text without changing repository dependencies. If extracted
  text is empty or clearly incomplete, treat the PDF as possibly scanned and
  ask before using OCR, network services, installing tools, or writing extracted
  content to the repository. Summarize only task-relevant findings and avoid
  printing full private documents by default.
- Ask before expanding into unrelated scope. Proceed without asking only when
  the expansion is required for the stated goal and remains low-risk.
- When preparing a project for a repository, publishing to GitHub, or removing
  "unneeded" files, do not classify `AGENTS.md`, `tools/`,
  `tools/project-memory/`, `skills/`, bootstrap scripts, update scripts, deploy
  scripts, or agent-facing instruction/config files as removable only because
  they look internal or tool-related. Inspect their purpose first and treat them
  as possible RAG/startup infrastructure. Delete them only when the user
  explicitly confirms they are temporary or unrelated to the project.
- During repository cleanup, classify SQLite and database files before acting.
  Do not delete or commit `*.sqlite`, `*.sqlite3`, or `*.db` files solely
  because they are binary or local-looking. Keep generated agent-memory indexes
  such as `tools/project-memory/project_memory.sqlite` ignored when they are
  rebuildable, and commit the reviewable README, Markdown/JSON memory exports,
  schema, and indexing scripts instead. Do not commit databases containing
  secrets, private data, telemetry, task-manager state, absolute local paths, or
  agent conversation history.
- Treat this repository root as the filesystem boundary for normal work. Do not
  read, search, edit, create, delete, move, or inspect files in another project
  or arbitrary external folder unless the user gives an explicit concrete path
  and action. Communicate with other projects through documented APIs,
  connectors, or task-manager endpoints.
- Treat `.\others\` under the current workspace parent, or another
  project-local relative path named by local instructions, as the standard local
  parent folder for third-party projects, cloned external repositories, and
  vendor experiments when no more specific destination is provided. This default
  folder is configurable: if the user gives another path or project-local
  instructions define another third-party workspace parent, use that instead. Do
  not mix third-party projects into the current project workspace.
- Treat `gi config`, `gi конфиг`, `ги конфиг`, `gi config service`,
  `ги конфиг сервис`, `ги конфиг сервис url=<url>`, and
  `ги конфиг сервис урл=<url>` as requests to get or set the bootstrap config
  for the config/discovery service. Read the
  project-local override only if local instructions define one, then read GI
  main config from the configured shared-instruction source repo checkout/cache,
  the current shared-instruction checkout, or `GENERAL_INSTRUCTIONS_HOME`. Use
  its `config/gi-main.json` `configServiceUrl` to query the config service.
  Resolve local app and task-manager runtime URLs by service id through
  config-service; project task-manager config should keep only the selected
  manager name/id and non-secret project preferences. For the `url=<url>` form,
  validate a full `http://` or `https://` URL with no secrets, update the shared
  `configServiceUrl` or the explicit project-local override, and tell services
  to use that URL for registration and discovery. Do not scan sibling project
  folders, guess ports, copy URLs from old task-manager memory, or use stale
  task-manager records as a runtime fallback.
- For agent-facing HTTP services, prefer a service-owned guide endpoint plus a
  strict contract endpoint. Resolve runtime URLs through config-service. Read
  `endpoints.guide` first when present, then `endpoints.contract` before
  sending state-changing requests. Treat the guide as onboarding and the
  contract as workflow validation. If they disagree, stop and report the
  mismatch. Do not infer permissions from filesystem paths, stale memory, old
  dashboard URLs, or raw task receipts.
- Treat `gi manager`, `gi tm`, `gi manager test`, `ги менеджер`,
  `ги манагер`, and equivalent task-manager status or test wording as requests
  to inspect the configured task manager through config-service. Read the
  enabled manager id or `service_id` from project-local task-manager config,
  resolve it through `GET /services/{serviceId}`, read `endpoints.guide` when
  present, read `endpoints.contract`, then use `endpoints.api` for documented
  manager operations. Stop with the exact blocker if the manager id is missing,
  config-service is unavailable, no matching service record exists, or the
  guide/contract lacks the requested capability. Do not fall back to `base_url`,
  stale task-manager memory, port scans, sibling projects, or guessed endpoints.
- Treat `gi config service on`, `gi config service off`, `ги конфиг сервис on`,
  and `ги конфиг сервис off` as requests to set the current application's
  project-local config-service self-registration flag. `on` means the app
  should publish or refresh its own service record during startup; `off` means
  it must not. Do not reinterpret this as starting or stopping config-service
  itself. When setting `on`, first confirm a config-service URL is already
  configured in the same local config area or documented GI bootstrap config; if
  no URL is configured, tell the user to set `gi config service url=<url>`
  before enabling self-registration. Ask one short question if no local config
  location is documented.
- Treat `gi active task`, `gi next task`, `gi get task`, and equivalent
  active-task wording as requests to get executable work from the configured
  task manager. Resolve the manager through config-service, read the manager
  contract, request the active or next task through the documented operation,
  update manager lifecycle state and notes, and stop with the exact blocker if
  the contract, auth, permissions, lifecycle IDs, or requested object type is
  missing or mismatched. Do not create raw intake receipts, local checklist
  notes, or a different manager object type as a substitute for the requested
  task, sprint, or cycle.
- Treat task-manager sync commands as routine execution steps, similar in
  certainty to `gi commit`, `gi push`, or FTP deploy commands after the user has
  supplied the content or selected workflow. A fast or weaker model may execute
  these commands, but it must still follow the manager contract exactly: do not
  replace manager API work with `project-memory`, pending-task notes, guessed
  commands, raw intake receipts, local checklists, or "tell me the exact
  command" fallback. If discovery, auth, contract, capability, payload shape, or
  readback is missing, stop with the exact blocker.
- Treat `gi add sprint`, `gi create sprint`, `gi добавить спринт`, and
  equivalent add-sprint wording as requests to create a visible executable
  Sprint/Cycle through the configured task manager. Resolve the manager through
  config-service, read the manager contract, use only the documented sprint or
  cycle creation operation, verify readback/lifecycle identifiers, and stop with
  the exact blocker if auth, permissions, schema, lifecycle, or object type
  support is missing. Do not downgrade the request to raw intake or a Work Item.
- For web-facing applications that expose a port, HTTP API, web UI, task-manager
  service, or local daemon endpoint, require a live config-service lookup before
  the process binds or reserves any port. On every startup, read the configured
  config-service URL, verify the config service is reachable, and query the
  app's own `service_id` startup/service record to learn the port and
  neighboring service endpoints. If config-service is missing, unreachable, has
  no record for the app, or returns an incomplete port/startup config, report a
  clear blocker and wait for config-service to be configured, repaired, or
  started; do not guess ports, scan for free ports, reuse stale local config, or
  bind a fallback port. If the record exists but the currently documented
  endpoints changed, refresh the record only after the config-service check
  succeeds. Desktop apps, CLI tools, libraries, scripts, and other non-web
  applications must not query or publish to config-service during normal startup
  unless local instructions explicitly define a discoverable web/API runtime.
- Treat `gi ftp`, `ги фтп`, `gi ftp push`, `ги фтп пуш`, `gi upload ftp`,
  `gi deploy ftp`, and `gi залей на фтп` as requests to upload the current
  project's configured build output to FTP, FTPS, or SFTP. Treat
  `gi ftp config`, `gi ftp конфиг`, and `ги фтп конфиг` as requests to create,
  inspect, or update the project-local FTP/SFTP config without uploading. Treat
  `gi ftp folder`, `gi ftp папка`, and `ги фтп папка` as requests to inspect,
  choose, or update the remote upload folder (`remotePath`) without uploading.
  Treat `gi ftp service`, `gi ftp сервис`, and `ги фтп сервис` as requests to
  manually register, inspect, or select an FTP/FTPS/SFTP service record in
  config-service without uploading. Read project-local deploy instructions and
  `tools/deploy/ftp.local.json` first; when a project needs FTP and local config
  does not name a target service, query config-service for FTP-capable services.
  If exactly one matching service exists, use it after verifying its contract;
  if several exist, ask the user to choose with the same numbered Markdown
  checkbox style used by language selection. Keep secrets out of config-service:
  store only discovery metadata and secret references such as environment
  variable names. Keep project-specific deploy settings in the separate
  project-local config file rather than shared instructions or chat history.
  Prefer `tools/deploy/ftp.local.example.json` only as a redacted shape. Do not
  commit hostnames, usernames, passwords, tokens, private keys, or private
  remote paths unless project policy explicitly marks them non-secret. Follow
  `patterns/PROJECT_FTP_DEPLOY.md`.
- Treat `gi reboot`, `ги ребут`, `gi restart`, and `ги рестарт` as requests to
  start or restart the current application using project-local run instructions.
  If the app is running, restart it; if it is not running, start it. Launch in
  the background so focus does not jump away from the user's current window.
- Treat `gi first test`, `gi первый тест`, and `ги первый тест` as requests to
  verify the current application's first-launch experience by resetting only
  documented project-owned app cache, generated state, temporary first-run
  profiles, and rebuildable local app settings. Read project-local run, cleanup,
  cache reset, and test instructions first. Do not delete user documents,
  production data, secrets, credentials, external service data, shared system
  caches, sibling projects, or arbitrary user-home folders. If exact reset
  paths, keys, scripts, or commands are missing, ask one short clarification
  question instead of guessing. After reset, start the app, run the documented
  first-launch smoke/onboarding checks, and report what was cleared, what
  passed, and what was intentionally left untouched.
- Treat `gi install`, `gi инсталл`, `ги инсталл`, and obvious typo variants
  such as `gi иснтлл` as requests to build the current project and produce an
  installer. Use Inno Setup by default when no installer tool is named. If the
  user writes a program after `gi install` / `gi инсталл`, use that program as
  the preferred packaging tool. Read project-local build and packaging
  instructions, scripts, manifests, and installer configs first. Resolve the
  application version from project-local metadata such as manifests, package
  files, assembly attributes, release files, or installer configs before
  packaging; update the version in build output, installer metadata, and the
  installer filename or artifact name when the local tooling supports it.
  `restore`, dependency install, build, and test checks are prerequisites only:
  they do not complete `gi install` unless the packaging command also runs and
  a current installer artifact is produced or explicitly verified. Do not report
  the project as installed/restored when only verification ran; report the
  installer artifact path, version, and checks after successful packaging. Ask a
  short clarification question if the build, installer, or versioning contract
  is missing instead of inventing one.
- Treat nested checkouts, vendored repositories, cloned examples, and
  third-party source trees as separate scope. Do not inspect them as part of the
  main project unless the user explicitly asks, the task is about that nested
  tree, or local instructions identify it as an active workspace component.
- Treat user-home application data and personal telemetry as private external
  sources. Do not read `.codex`, `.cursor`, IDE logs, browser profiles, shell
  history, application SQLite databases, or local app logs outside the project
  root unless the user gives an explicit path and action. For analyzer tasks,
  prefer mock or sample data, or ask for permission to inspect a specific file.
- Treat product plans, `apps.txt`, summaries, and task-manager notes as intent
  signals only. They are not permission to read private local data sources.
- If a required file, skill, config, script, endpoint, task, or other entity is
  missing or not found, first reread the relevant local instructions, runbook,
  project memory, and accepted instruction-kit artifacts for the current scope.
  If the entity is still missing, ask the user a short clarification question.
  Do not use another project folder or the shared instruction library as a
  runtime fallback unless the user explicitly gives that path and action.
- Follow `patterns/FIRST_MESSAGE_HANDLING.md` for first-message title handling
  and shared-instruction bootstrap requests.

## Language Preferences

- Prefer one language command with three ordered choices when the user wants
  language preferences for project work. Treat `gi language`, `gi язык`, `ги язык`,
  `gi project language`, `gi проект язык`, `ги проект язык`,
  `gi язык проекта`, and `ги язык проекта` as requests to configure, in order:
  project working environment languages, commit-message languages, and task
  languages in
  `tools/project-memory/system-preferences.json` and
  `tools/project-memory/git-preferences.json`.
- Apply the configured project working-environment language order to plans,
  checklists, progress updates,
  final answers, clarifying questions, and user-facing explanations. Do not use
  it to rewrite existing task text, code, commands, logs, quoted text, or a
  response language the user explicitly requested for a specific message.
- Apply the configured task language order to agent-created task titles, task
  descriptions, and task-manager updates.
- For task titles, descriptions, and task-manager updates, treat the first
  configured task language as the main language. If exactly one task language is
  configured, write task text only in that language. If multiple task languages
  are configured, write the main-language text first and then add one clear
  translation per additional language. Do not duplicate the same content twice
  in one language, and do not mix untranslated labels, templates, or Definition
  of Done text from another configured language into the main-language text.
- For each `gi язык` choice, preserve the user's selected order. The first
  selected language in each choice is primary for that surface.
- If `gi язык` or an equivalent unified project-language command is sent
  without explicit languages, run a three-step chat flow instead of asking for
  one free-form line. First show a compact `Current settings` block for all
  three language surfaces. At each step, show the same numbered Markdown
  checklist of available languages with the current selection checked, add a
  final unchecked `Cancel / Отмена` option, name the current surface, and tell
  the user they may reply with numbers, language names, or cancel/отмена.
  Render each option as a task-list bullet with the number inside the label,
  such as `- [x] 1. English`; do not use ordered-task syntax such as
  `1. [x] English`, because some chat renderers split the checkbox and label
  onto separate lines.
- If the user selects `Cancel / Отмена`, replies `cancel` or `отмена`, or
  chooses only the cancel option during the language flow, stop the flow without
  changing any language preference files.
- When the user replies to that flow with a numeric-only answer such as `1 2`,
  interpret the numbers against the most recent language checklist and apply the
  resulting ordered languages to the current step. Do not ask which languages the
  numbers mean when the checklist was just shown.
- Keep commit-message language preferences separate from the agent's
  user-facing working language unless the user uses the unified project-language
  command.
- Treat `gi commit language`, `gi коммит язык`, `ги коммит язык`, and older
  `gi язык коммита` forms as requests to configure commit-message languages in
  `tools/project-memory/git-preferences.json`.
- Treat `gi system language`, `gi систем язык`, and `ги систем язык` as
  requests to configure the agent's project working language in
  `tools/project-memory/system-preferences.json`.
- Follow `tools/project-memory/system-preferences.json` for progress updates,
  final answers, clarifying questions, user-facing explanations, and
  agent-created task artifacts. Do not use it to rewrite existing task text,
  code, commands, logs, quoted text, or a response language the user explicitly
  requested for a specific message.

## UI And Focus

- Launch applications in the background so focus does not jump away from the
  user's current window.
- For web applications, assume the user will inspect the UI manually. Do not
  open, browse, screenshot, or visually inspect the UI automatically unless the
  user explicitly asks for that.
- After implementing a frontend, backend, API, or full-stack feature, restart
  the affected dev server or backend process when local run instructions provide
  a restart command or when hot reload is uncertain. Then refresh the browser,
  client, or API caller before verification so checks do not use stale HTML,
  JavaScript, routes, schemas, or cached responses.

## Progress Updates

- Keep progress updates phase-level, not command-level. Do not narrate after
  every command batch, report counters such as "ran 4 commands", or live-blog
  each intermediate hypothesis.
- Do not duplicate tool-run counters that the chat UI may show automatically;
  system UI counters are not agent progress updates.
- Send an update when the phase changes, a meaningful finding changes the next
  step, a blocker appears, or work has been quiet for long enough that the user
  needs reassurance.
- Batch routine observations internally and summarize only the current
  conclusion, next action, and blockers. Keep command names and detailed logs
  for final summaries or failure diagnosis.

## Update Intake

- When maintaining this `general-instructions` repository, treat `updates/` as a
  dated intake queue. Review update files newest-first, move accepted reusable
  rules into the main library, and remember accepted updates by committing them.
- External projects that consume these shared instructions must not read
  `updates/` during startup or bootstrap.
- When another project reveals a reusable improvement to shared instructions,
  write a dated recommendation to this repository's `updates/` folder if it is
  available.
- If this repository is unavailable, use a project-local intake folder such as
  `tools/instruction-updates/` or `tools/project-memory/instruction-updates/`
  with the same dated filename pattern.
- Project recommendations should explain the observed problem, reusable rule or
  workflow, evidence paths, affected files or commands, and any risks. Remove
  secrets, credentials, private user data, production data, and project-specific
  details that are not needed as examples.
- Treat recommendation source projects and owners as provenance only. Reading a
  recommendation in this repository's `updates/` folder is allowed during
  maintenance, but evidence paths, project names, task-manager notes, or owner
  labels in that recommendation are not permission to read, search, edit, or
  inspect the source project. Ask the user or that project's owner for an
  explicit concrete path and action before crossing the repository boundary.
- Treat recommendations as intake only. Do not add this repository as a
  dependency, package, submodule, symlink, or runtime reference unless the user
  explicitly asks for that.
- Run `gi обновить` quietly by default. Do not narrate step-by-step reasoning,
  repeated progress, command transcripts, broad file reads, or full diffs during
  normal successful updates. Apply the update, then report a compact summary
  with versions, migration counts/IDs, changed files, checks, commit/push
  result, and blockers if any.
- Keep `gi обновить` scoped to accepted instruction-kit updates and migrations.
  Do not reinterpret it as a request to push pre-existing local commits, sync a
  feature branch, resume a remembered plan, or perform general Git maintenance.
  Commit or push only changes created by the update flow itself and only when
  the local update policy permits it.

## Verification

For documentation-only changes:

```powershell
git diff --check
```

For larger changes, reread the edited files and confirm links, paths, and
checklists still match the repository layout.

If adding a file under `templates/`, `patterns/`, or `checklists/`, update
`INDEX.md` in the same change.

## Git Policy

Default policy: the agent may edit and verify files; the user reviews and
commits unless they explicitly ask the agent to commit. Follow
`patterns/GIT_WORKFLOW.md` for commit requests, dirty worktrees, diff hygiene,
and project commit-message language preferences.
