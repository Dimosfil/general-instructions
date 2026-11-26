# API Key And Secret Safety

Use this pattern when a project creates, stores, configures, rotates, or calls
external APIs with credentials such as API keys, tokens, webhook secrets,
service-account keys, signing secrets, or provider-specific access credentials.

## Project API Integration Commands

- Use `gi custom [name]` or `ги кастом [имя]` to select an API integration
  for the current chat and project. Pass the exact chat command to
  `tools/get-gi-context.ps1 -CommandText`. Treat the whole suffix as the name
  or alias and match it exactly after normalizing case and whitespace.
- Register integrations in the current project's existing
  `tools/project-memory/specs/integration-contracts/connected-projects.md`.
  Use a level-two or level-three heading as the plain-text name and add the
  four bullets shown in `templates/CONNECTED_PROJECTS.template.md`. The
  `GI custom aliases` bullet opts an entry in and accepts comma-separated aliases
  or an empty value for heading-only matching. Keep names and aliases unique.
- Use one `API reference` for the API list or documentation. Provide an HTTPS
  URL without user info or a query string, or a project-relative Markdown path.
  Use one `API runbook` pointing to project-relative Markdown with endpoints,
  request instructions, and the approved way to invoke the authenticated tool.
  Keep both resources free of credential values.
- Use one `Credential source` bullet with comma-separated non-secret references
  such as `env:API_LOGIN`, `env:API_PASSWORD`, `connector:service-account`, or
  `secret:integrations/service`. Use references for the sources the runbook
  actually uses. Keep values in the approved store and give them directly to
  the authenticated tool when executing the requested operation.
- On `list`, show the registered names. On `registry unavailable`, report the
  expected project-local path. On `unknown`, report that no profile matches.
  On `ambiguous`, present the matching entries and ask which one to select
  before activating any of them. Use the registry line to distinguish entries
  with identical names. After an explicit choice, apply the same reference
  checks to that entry. Preserve any prior selection until a new one succeeds.
- On `selected`, open only the returned local documentation and runbook for
  the chosen entry. Report the integration, documentation links, and explicit
  setup gaps. Remember the selection for this chat in the active project.
  Keep credential references as metadata and leave credential availability
  unverified during activation. Make API requests only for a later explicit
  operation in the same project, following the runbook and its authorization
  boundaries.

## Rule

- Keep API keys and tokens out of source code, committed config, generated
  bundles, logs, traces, screenshots, handoff summaries, task-manager payloads,
  RAG indexes, and chat responses.
- Never place provider API keys in client-side code, mobile apps, desktop app
  bundles, public frontend environment variables, or downloadable artifacts.
  Route browser, mobile, and packaged-app requests through a backend,
  server-side function, proxy, or token-exchange service that enforces the
  project's authorization and rate limits.
- Prefer one credential per person, runtime service, application, environment,
  or integration boundary. Do not share one personal key across a team, and do
  not reuse one production key across unrelated services.
- Keep development, staging, and production credentials separate. Prefer
  sandbox or test-mode credentials for development, and use separate
  provider-side projects, apps, bot tokens, or service accounts when the
  provider supports them.
- Store local development secrets in ignored local files or user-level secret
  stores. Store production secrets in the hosting platform's secret manager,
  KMS, vault, cloud secret store, deployment secret store, or another approved
  managed secret backend. Treat `.env` as a local-development fallback unless
  project-local production policy explicitly approves it.
- Commit only redacted examples, environment variable names, secret reference
  names, provider project IDs that are documented as non-secret, and setup
  instructions that do not reveal private values.
- When the provider supports credential scoping, grant the minimum needed
  permissions, models, resources, environments, or API capabilities.
- When the provider supports network restrictions, restrict production
  credentials to trusted infrastructure with IP allowlists, VPC/private
  connectivity, workload identity, mTLS, or equivalent controls.
- Monitor usage, quota, billing, error rates, and unusual access patterns for
  production credentials. Document the owner and expected workload so anomalous
  usage is easier to recognize.
- Rotate a credential immediately when it may have leaked, appeared in logs,
  been committed, been pasted into chat, been exposed to a client bundle, or
  left the control of its intended owner. Revoke the old credential, update the
  runtime secret reference, redeploy or restart affected services, and verify
  with a harmless health check.
- Treat a credential pasted into chat as compromised, but do not treat that fact
  alone as a blocker for the whole development task or require rotation as a
  precondition for unrelated safe work. Warn once without repeating the value,
  recommend rotation, and continue local implementation, configuration wiring,
  mocked or sandboxed tests, documentation, and other independent steps that do
  not expose or unsafely persist the credential.
- If the requested task needs authenticated access, prefer an existing approved
  secret store, environment reference, connector authorization, or another
  non-echoing project-approved path. If no safe credential path is available,
  mark only the affected authenticated operation blocked or unverified and
  continue the rest of the task. Do not repeatedly interrupt the user about the
  same exposure.
- Do not print secret-bearing command lines or raw config in terminal output,
  final responses, runbooks, or support notes. Redact values while preserving
  enough non-secret context to debug the issue.

## Implementation

- Load secrets at the application boundary through environment variables,
  deployment secrets, secret-manager clients, service discovery secret
  references, or connector authorization. Pass credentials inward through typed
  config or explicit dependency injection, not global ad hoc reads spread across
  the codebase.
- Validate required secret references at startup and fail with a clear missing
  configuration message that names the variable or reference, not the secret
  value.
- Keep provider-specific credential setup in project-local docs or runbooks.
  Shared instructions should describe the boundary and safe handling pattern,
  not real project names, account IDs, domains, private endpoints, or secret
  values.
- For frontend or packaged-app features that need user-specific access, prefer
  short-lived scoped tokens, backend sessions, OAuth/device authorization,
  signed upload URLs, or project-approved token exchange rather than embedding
  long-lived provider credentials.
- For automated agents and tools, use the narrowest available credential and
  scope it to the task. Avoid giving a maintenance script a broad production
  credential when a read-only, staging, sandbox, or single-service credential
  would satisfy the workflow.

## Verification

- Search touched source, committed config, examples, generated bundles, logs,
  traces, docs, and project-memory files for accidental secrets before commit.
- Confirm `.gitignore`, deploy manifests, and project-local config examples
  exclude real local secret files and include only redacted examples.
- Confirm client-side bundles and public environment variables do not contain
  long-lived provider credentials.
- Confirm production deployments resolve secrets from the documented secret
  backend or secret reference, not from committed files.
- Confirm leaked or suspected credentials were revoked or rotated before
  reporting the issue resolved.
