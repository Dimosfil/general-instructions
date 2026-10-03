# Project Tester Contract

Status: current accepted instruction behavior. Last checked: 2026-10-03.

## Purpose And Sources

Provide one portable tester workflow while each consuming project owns its
scenarios, execution modes, settings, links, runtime identity, and artifacts.

- Rules: `patterns/AGENTS_RUNTIME/09-testing.md`.
- Explicit full-system flow: `patterns/AGENTS_RUNTIME/09-full-testing.md`.
- Routing: `config/gi-command-routes.json`; help: `COMMANDS.md`.
- Authoring scaffold: `templates/PROJECT_TESTING.template.md`.
- Propagation: `2026.10.03.2__generalize_project_tester_info_and_start`.
- Checks: `tools/test-gi-context-routing.ps1` and
  `tools/test-instruction-kit-bootstrap.ps1`.

## Invariants

- `gi test` / `ги тест` returns tester information and local scenario settings;
  it does not execute checks, start apps, inspect UI, reset, or write state.
- `gi test start` / `ги тест старт` runs the selected local scenario, resolved
  from explicit task, current chat, or documented project selection/default.
  Ambiguous selection requires clarification, not an invented full-system run.
- Task selection and test-plan commands remain distinct from execution.
- Full-system aliases retain live-surface and documented baseline requirements.
  Ordinary audits use their own state contract and do not inherit those resets.
- Shared guidance contains no product/provider IDs, concrete URLs, fixed ports,
  local paths, roles, modes, budgets, or fixture sets from a source project.
- Local canonical documentation defines scope, settings, access, action/input
  policies, expected results, environment gates, evidence, and state handling.
- Authorization persists for the same target/scope. UI is authorized when needed
  by the selected run; chargeable/destructive/external-send actions retain
  applicable explicit authorization requirements. Testing does not authorize
  product repairs, imports, deployment, or substituting storage/access.
- Evidence distinguishes case coverage, parameter variants, errors, skips,
  observed actions, measured effects, and unknown channels. Historical results
  and previews do not prove new live execution outside their scope.
- Durable checkpoints support interruption and resume with freshness checks.
  Raw artifacts and private backups stay in local approved locations; memory
  contains only compact verified contracts and evidence references.
- Run completion and product correctness are separate. Run states are
  `complete`, `incomplete`, `blocked`, and `restoration-required`.

## Verification Cases

| Case | Required result |
| --- | --- |
| Information command | Explain current scenarios/settings; no runtime mutation |
| Start with trailing task text | Longest-prefix execution route; chosen local scope |
| Plan/task command | Plan or selection; no implicit execution |
| Missing or ambiguous local scenario | Exact missing contract/question; independent reads continue |
| Observational audit | Local backup/restoration; no inherited factory reset |
| Full-system command | Dedicated full-system module, reset contract, live surfaces |
| Chargeable step without authorization | Hold that step; continue independent authorized cases |
| Quote/operation changes during wait | Record only current final result; bounded retry |
| Interrupted run | Durable checkpoint, remaining cases, freshness before resume |
| Unobserved network | Unknown count; do not infer zero from no UI actions |
| Restoration failure | Keep backup; report restoration-required |
| Found defects with complete coverage | Completed audit plus product failures |
| Fresh bootstrap | Both modules and scaffold copied; accepted version/checkpoint |
| Instruction migration | Preserve local scenarios and settings; update rule and routing |

These are instruction and routing guarantees. This library does not execute a
consumer's product scenario; consumer results require a fresh authorized run.
