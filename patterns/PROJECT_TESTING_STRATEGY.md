# Project Testing Strategy

Use this pattern when planning or running verification for a project, new
feature, bug fix, migration, or release check.

## Goals

- Prefer project-local test commands, scripts, runbooks, and CI configuration.
- Start with the fastest relevant checks before broad suites.
- Match verification depth to risk, blast radius, and user request.
- State clearly what was checked, what was not checked, and why.
- Avoid printing large logs, full diffs, generated output, or whole reports by
  default.

## Discovery

Inspect only task-relevant local context first:

- `AGENTS.md`, runbook, working agreements, and project memory;
- package or build files such as `package.json`, `pyproject.toml`, `.csproj`,
  `Cargo.toml`, `go.mod`, or equivalent;
- CI configs and local helper scripts;
- test directories and naming conventions;
- README commands when local instructions are missing.

Identify the project type before recommending checks:

- web frontend or full-stack app;
- backend/API/service;
- CLI/tooling project;
- library/package;
- game, Unity, or interactive app;
- documentation-only repository.

## Test Ladder

Build verification from narrow to broad:

- Syntax or static checks that are cheap and deterministic.
- Focused unit tests for touched code or nearby behavior.
- Integration checks for contracts, storage, network boundaries, or CLI flows.
- Smoke checks for app startup, health endpoints, or critical workflows.
- Manual checks for UI, visual behavior, accessibility, or external systems.
- Full test suite, build, or release checks only when justified by risk or
  requested by the user.

For documentation-only changes, prefer `git diff --check`, targeted rereads,
link/path sanity checks, and index consistency.

## Feature Verification

For each new feature or behavior change, cover:

- expected behavior and happy path;
- changed user or API workflows;
- regression areas near the touched code;
- failure paths, validation errors, empty states, and permission failures;
- edge cases and boundary values;
- migration, rollback, or fallback behavior when relevant;
- observability, logs, metrics, or user-visible errors when relevant.

## UI And Visual Checks

Follow local project instructions first. If the project says the user will
inspect UI manually, do not open browsers, screenshots, or visual inspection
tools unless the user explicitly asks.

When automatic UI verification is appropriate, prefer targeted checks:

- run the app in the background;
- check key DOM states or route responses programmatically;
- inspect screenshots only for the changed workflow;
- include mobile and desktop viewports when layout risk is meaningful.

When automatic UI verification is not appropriate, produce a manual checklist
with exact flows, inputs, expected states, and regression areas.

## Running Checks

Before running checks:

- choose the smallest command that can catch likely failures;
- avoid destructive commands and broad environment changes;
- explain any expensive, slow, or external check before running it;
- request approval when sandbox, network, or destructive actions require it.

After running checks:

- summarize command names and outcomes;
- quote only the important error lines when a check fails;
- suggest the next smallest useful check or fix;
- do not hide unrun checks behind vague confidence language.

## Reporting

Use concise sections when useful:

- Scope;
- Project Signals;
- Fast Checks;
- Focused Automated Tests;
- Manual Checks;
- Regression Areas;
- Not Checked;
- Confidence.

Final responses should distinguish:

- `Checked`: commands or manual reasoning actually completed;
- `Not checked`: checks skipped, unavailable, or left for the user;
- `Risk`: remaining uncertainty and likely failure modes.

## GI Command

Treat `gi тест-план`, `gi test plan`, `gi проверить фичу`,
`gi feature check`, `gi план проверки`, and `gi test strategy` as requests to
produce a project-aware verification plan in the current project root.

By default, this command plans checks and does not run them automatically. Run
checks only when the user explicitly asks, or when the current implementation
task already requires verification.
