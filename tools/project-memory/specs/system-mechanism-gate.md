# System Mechanism And Responsibility Gate Contract

Status: current accepted instruction behavior.
Last checked: 2026-10-13.

## Purpose And Ownership

GI requires agents to locate the responsibility and mechanism behind a scenario
before changing its behavior. This is an instruction and review gate; it is not
an automated guarantee that an agent will follow it.

- Detailed behavioral source: `patterns/ARCHITECTURE_AND_CODE_QUALITY.md`,
  section System Mechanism And Responsibility Gate.
- Loading: root/project-template `AGENTS.md`, runtime modules 04, 06, and 15.
- Execution and completion: senior-engineering and coherent-batch patterns.
- Consumer propagation: agreements template, installer, kit metadata, and
  `2026.10.13.2__enforce_system_mechanism_and_responsibility_gate`.

## Workflow

1. Trace the scoped scenario using source, relevant contracts, and tests.
2. Identify the existing mechanism, violated/new contract, state/decision owner,
   consumers, and side effects. Distinguish functioning code from scaffolding.
3. Before editing, keep a compact source-backed mapping in the plan or local
   contract: scenario -> mechanism -> contract owner -> change -> verification.
4. Correct or extend the mechanism at its owner. Explain any new mechanism or
   bypass. Keep temporary constraints and a removal/review condition explicit.
5. Verify scenario behavior, ownership, related invariants, and side effects;
   align code, tests, docs, and durable specs in the same scoped batch.

## Decision Cases

| Case | Required behavior |
| --- | --- |
| Caller restores state destroyed by shared cleanup | Correct the cleanup/completion contract at its owner; check intervening side effects |
| Multiple callers compensate for a primitive | Define explicit legitimate operation variants at the primitive boundary |
| Nested workflow rewrites a child's internal control flags | Review composition inputs, ownership, and completion contracts at the responsible boundary |
| An interface exists without an implementation | Treat it as scaffolding; justify and implement the smallest missing mechanism |
| An external implementation cannot be changed | Bound and document an adapter/bypass, verification, and removal/review trigger |
| Contract-defined transaction rollback or recovery | Preserve and verify that contract; do not classify all compensation as a workaround |
| A small edit has an adequate current mapping | Reuse it; avoid extra approval, broad scans, or new document ceremony |
| A test asserts only the implementation's shape | Add relevant scenario/contract evidence; do not claim intermediate effects or live behavior verified |

## Verification And Limits

Bootstrap regression verifies that a fresh consumer receives the gate and its
linked patterns, records them in metadata, and retains them across reinstall.
Routing regression verifies that refactor context exposes the gate and stays
within existing budgets. These checks prove propagation, not future agent
compliance or a consuming product's runtime behavior. Migration application
must preserve local adaptations and unrelated staged/unstaged work.
