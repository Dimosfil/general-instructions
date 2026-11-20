## Scope, Evidence, And Filesystem Boundaries

- For read-only database searches, including raw requests, interpret a supplied
  textual name or identifier as a partial-match search by default. Use the
  project's documented search fields and matching rules; without a more specific
  contract, use case-insensitive literal substring matching in the relevant
  name/identifier fields (for example, parameterized PostgreSQL `ILIKE`). Escape
  LIKE wildcard characters in literal input unless a pattern was explicitly
  requested. Use exact equality only when the user explicitly requests it, such
  as `ТОЧНО!`, `точное совпадение`, `exact`, or supplies an explicit SQL predicate;
  preserve a user-supplied query's semantics. Do not infer exact intent merely
  from quotes or an identifier-looking term. An empty equality lookup does not
  establish absence for a partial-match request. Show the actual query/filter
  and all matching rows within disclosed limits; do not silently select one
  variant or provider, or claim a unique entity when several match. Preserve
  other requested filters and raw values. This discovery default does not
  broaden targets for updates, deletes, permissions or other mutations.
- Treat requests to show database data as `raw`, `рау`, or raw table rows as
  requests to execute a read-only selection directly from the requested table
  and show the returned rows as stored. Render `raw` / `рау` as a table by
  default, with original column names as headers and one database row per table
  row. Preserve the query result's column order (schema order for `SELECT *`)
  and returned row order. Do not transpose results into field/value rows or
  record/provider columns, group records into comparison cards, split the
  result into separate per-record tables, or omit columns to fit the viewport
  unless explicitly requested. Keep wide results as one complete table; allow
  the viewer to scroll horizontally where supported. Render JSON only when
  explicitly requested, such as `raw JSON`,
  `рау JSON` or `рау джисон`. Keep the same selected rows, columns and values
  in either format; table presentation does not authorize data transformation.
  Preserve original column names and
  values, including NULLs, empty strings, duplicates and stored precision;
  do not replace the result with a summary, aggregation, deduplication, joins,
  calculated fields, renamed columns or normalized/formatted values unless
  explicitly requested. Apply only requested filters, column selections and
  ordering. Show all columns when no column selection is requested. Identify
  the source table and executed query; disclose any pagination, row limit,
  truncation or unavoidable display conversion and do not present a partial
  result as complete. Respect access and secret boundaries and disclose any
  withheld fields. If database access is unavailable, report that blocker;
  label example SQL or invented example rows as illustrative, never as an
  executed selection or actual database data.
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
- Before filesystem writes, verify that the active working directory, local
  project identity, and target path match the user's current request. Use local
  identity signals such as `AGENTS.md`, README title, package or app manifests,
  service id, git remote, project-memory orientation, and documented working
  areas. If those signals point to a different project than the request, or the
  request names a different product/repository while the active root is
  unchanged, stop and report the mismatch before editing. A path or product
  name from old chat, a screenshot, task-manager metadata, a summary, or a
  stale plan is not permission to edit that other project.
- When the current user message explicitly names an absolute path outside the
  active project root and an action, state the active root and the external
  target before acting. If the named path looks like another project root,
  proceed only when the user clearly asked to work in that external project for
  this task; otherwise ask one short confirmation question.
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
- Follow `patterns/FIRST_MESSAGE_HANDLING.md` for first-message title handling
