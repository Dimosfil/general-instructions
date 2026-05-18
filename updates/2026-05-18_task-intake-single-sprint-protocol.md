# Recommended GI Update: Task Intake Must Become Executable Sprint Work

Date: 2026-05-18
Source project: WorkNest
Status: intake recommendation, not an accepted rule

## Observed Problem

A task-manager adapter accepted a `type: task` payload and stored it as raw intake, but did not create an executable sprint/task record. A downstream agent could see the card in the dashboard but could not close it through `next-task` / `task-completed` because there was no `sprintId`. The agent worked around the issue by creating a separate one-task `type: plan` sprint, leaving the original raw task apparently unfinished.

## Proposed Reusable Rule

When an instruction-kit task-manager workflow accepts single-task intake, it must either:

- convert `type: task` into a one-task executable sprint/task object and return its execution identifiers, or
- explicitly reject `type: task` with a clear contract error that tells the caller to send `type: plan`.

Agents must not invent a replacement plan to complete a raw task. If an intake receipt lacks required execution identifiers, report the contract gap and stop or ask for the correct task-manager endpoint behavior.

## Proposed Artifact

Add a task-manager adapter checklist item:

- Verify that all accepted intake types are executable through the advertised lifecycle endpoints. For each accepted task payload, confirm the response includes enough identifiers for `next-task`, `task-completed`, and archive/close flows, or that the adapter documents the payload as intake-only.

## Evidence

- WorkNest API route: `apps/api/src/server.js`
- WorkNest sprint workflow: `apps/api/src/sprintWorkflow.js`
- WorkNest web raw overlay: `apps/web/src/App.tsx`
- Repaired task plan: `projects/worknest-core/planning/task-intake-single-sprint-fix.md`
- Reproduction symptom: a `type: task` card stayed visible in project backlog while the agent created and completed a separate `type: plan` sprint.

## Expected Benefit

Prevents orphan raw-task cards, duplicate workaround sprints, and false reports that API-only task execution succeeded while the original task remains unexecuted.

## Risks

Some projects may intentionally treat `type: task` as intake-only. The reusable rule should allow explicit rejection or explicit intake-only documentation instead of forcing every adapter to create sprints.

## Privacy Review

No secrets, credentials, production data, or private user content included. Evidence paths are structural project paths only; task names are generic test artifacts.
