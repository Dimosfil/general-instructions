# GI Update: Next-Task Endpoint Contract Clarification

Date: 2026-05-19
Target project: shared `general-instructions`
Status: intake recommendation, not accepted rules

## Observed Problem

During a `gi start sprint` session, an agent:

1. Posted a `type: plan` to `POST /agent-intake/raw` and received a sprint with
   task IDs and a sprint ID.
2. Tried `POST /agent-intake/next-task` with a JSON body containing `sprintId`
   and received `404`.
3. Tried `GET /agent-intake/next-task?sprintId=...` and received `400`.
4. Instead of checking the contract or asking the user, worked around the
   failure by executing tasks directly and submitting them through
   `POST /agent-intake/task-completed`.

The correct endpoint contract is:

```
GET /agent-intake/next-task?project=<project>&sprintId=<sprintId>
```

It requires query parameters, not a JSON body, and uses GET, not POST.

## Proposed Reusable Rule

Update the WorkNest adapter docs so the `next-task` endpoint shows the
full method + parameter signature, not only the path.

Current docs at `skills/task-manager-plans/references/managers/worknest.md:47`:

```
- `GET /agent-intake/next-task`
```

Proposed:

```
- `GET /agent-intake/next-task?project=<project>&sprintId=<sprintId>` —
  returns the next `todo` or `ready` task for the given sprint, or
  `{"sprintStatus": "complete", "task": null}` when no tasks remain.
```

Also add a reminder to the `gi start sprint` workflow in
`skills/task-manager-plans/SKILL.md` that when a manager endpoint returns
an unexpected error, the agent should first re-read the adapter's endpoint
documentation before working around the issue.

## Evidence

- `updates/2026-05-18_task-manager-project-endpoints.md` documents the
  endpoint list with `GET http://127.0.0.1:4187/agent-intake/next-task` but
  does not show query parameters.
- Session log: the agent spent time on wrong method (POST) and wrong
  parameter format (JSON body, missing `project` param).

## Expected Benefit

- Prevents future agents from guessing the wrong HTTP method or parameter
  format for `next-task`.
- Reduces wasted time on endpoint debugging.
- Makes the `gi start sprint` workflow more reliable.

## Privacy Review

This recommendation includes only local loopback URLs, endpoint names, query
parameter names, and method information. No secrets, credentials, private
data, or production data.
