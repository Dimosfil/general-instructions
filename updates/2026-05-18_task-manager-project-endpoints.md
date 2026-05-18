# GI Task: Per-Project Task Manager API Endpoints

Date: 2026-05-18
Target project: shared `general-instructions`
Status: intake recommendation, not accepted rules

## Observed Problem

During WorkNest manager-flow testing, the project had two local services:

- UI: `http://127.0.0.1:5175/`
- API: `http://127.0.0.1:4187/`

The initial manager config used the UI URL as `base_url`. That made the visible
dashboard available, but it was not the endpoint agents needed for plan intake,
active sprint lookup, next-task lookup, task completion, or read-model checks.
A stale API process also responded to `/health` while returning `404` for
required manager endpoints.

## Proposed Reusable Rule

Update `gi` task-manager guidance so every consuming project selects and stores
its own task-manager adapter and API endpoint.

Required behavior for `gi tm`, `gi post plan`, `gi start sprint`, and related
plan-sync commands:

- Treat task-manager configuration as project-local state, not a global agent
  setting.
- If no manager is configured for the current project, ask the user to choose
  from available adapters plus `none`.
- For each selected manager, require a real project-specific API endpoint before
  sending plans or fetching sprint/task state.
- Treat `base_url` as the manager API endpoint used for operations.
- Do not use a UI URL as the manager endpoint unless the adapter explicitly
  says that the UI URL is also the API URL.
- Do not leave endpoint fields empty, guessed, or set to `TODO`.
- Before using a manager endpoint, verify required capabilities for the
  requested workflow, not just generic health.
- If health succeeds but required capabilities fail, report a stale or
  misconfigured manager endpoint and stop before sending work.

## Proposed Artifact Changes

Create an accepted `general-instructions` migration that updates:

- `templates/task-managers.template.json`
- `skills/task-manager-plans/SKILL.md`
- `skills/task-manager-plans/references/managers/worknest.md`
- `templates/AGENTS.template.md`
- `templates/AGENT_WORKING_AGREEMENTS.template.md`
- `COMMANDS.md` sections for `gi tm`, `gi post plan`, and `gi start sprint`

Recommended config shape:

```json
{
  "version": 1,
  "managers": [
    {
      "id": "worknest",
      "enabled": true,
      "base_url": "http://127.0.0.1:4187/",
      "workspace": "",
      "project": "worknest-core",
      "intake_mode": "raw",
      "notes": "Project-local manager API endpoint. UI URLs are documented separately if needed."
    }
  ]
}
```

Adapter-specific docs may add optional fields such as `ui_url`, but generic
`gi` rules should not require or infer UI URLs for manager operations.

## Evidence

- `tools/project-memory/task-managers.json`: corrected `base_url` from UI
  `http://127.0.0.1:5175/` to API `http://127.0.0.1:4187/`.
- `tools/project-memory/manager-flow-test-2026-05-18.md`: records the
  end-to-end manager-flow test and stale API finding.
- Test endpoints used:
  - `GET http://127.0.0.1:4187/health`
  - `GET http://127.0.0.1:4187/agent-intake/contract`
  - `POST http://127.0.0.1:4187/agent-intake/raw`
  - `GET http://127.0.0.1:4187/agent-intake/next-task`
  - `POST http://127.0.0.1:4187/agent-intake/task-completed`
  - `GET http://127.0.0.1:4187/worknest-data`

## Expected Benefit

- Prevents agents from sending plans to a UI-only URL.
- Avoids leaking one project's manager endpoint into another project.
- Catches stale task-manager services before work is posted.
- Makes `gi tm` setup safer and more predictable across projects.

## Risks

- Existing consuming projects may already use `base_url` ambiguously.
- Some adapters may expose UI and API through the same origin; adapter docs
  should say so explicitly.
- Capability checks must stay small and avoid broad or destructive probes.

## Privacy Review

This recommendation includes only local loopback URLs, project-relative file
paths, endpoint names, and generic workflow behavior. It does not include
secrets, credentials, private user data, production data, request payload
contents, or private business details.
