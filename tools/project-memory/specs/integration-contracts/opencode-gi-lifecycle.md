# OpenCode GI Lifecycle Contract

## Scenario And Ownership

An OpenCode task receives current GI rules, delegates with those rules, survives
compaction, and cannot normally exit its text response loop without an automatic
review continuation. Entry: project-local `.opencode/plugins/gi-lifecycle.js`.
Policy/context owner: module 03 and `tools/get-gi-context.ps1`. Verification and
receipt owner: `tools/invoke-gi-lifecycle-hook.ps1`. Host continuation owner:
OpenCode's `session.prompt(noReply)` and response loop, verified on 1.15.7.
Integration and acceptance evidence: `tests/test_opencode_gi_hooks.mjs` and
`tests/test_opencode_gi_live.mjs`. User-facing operation: `docs/gi-opencode-hooks.md`.

## State And Invariants

- Track each session's user turn, effective agent/model/variant, handled assistant
  message and whether the engine requested continuation. Internal synthetic
  review insertion must not reset the user turn. Other incoming messages do.
- Load Work on every session model request and at compaction; do not rely on
  the agent remembering a manual helper call or summaries preserving rules.
- Forward mandatory-only context through `task`, preserving original task text
  and every routing field. Deny forwarding when the engine cannot supply rules.
- For assistant text-end, exclude compaction summaries, invoke the shared Stop
  protocol, then await persistence of a newer synthetic user message on block.
  `noReply` prevents a same-loop deadlock; the newer message prevents normal
  loop exit. Do not substitute post-idle restart or rewriting streamed text.
- Keep synthetic review text compact; full mandatory rules belong in the system
  transform. The shared engine still fingerprints full Complete context.
- Review the next assistant message against the engine's current fingerprint.
  Rules/work changes invalidate receipts. Engine retry limits and fail-closed
  errors remain authoritative. Preserve permissions and unrelated changes.
- Keep host state under `.opencode/.gi-hook-state/`, separate from Codex, and
  exclude both hosts' state from fingerprints. Persist no prompt, response or diff.
- Reject structured JSON output, whose core exit path bypasses this mechanism.
  No text-end on empty/error/cancelled responses means no successful receipt.
- The host can force review delivery, not prove model honesty or task correctness.

## Distribution And Verification

Bootstrap copies the adapter and shared engine without touching other plugins or
OpenCode config. Different existing owned files require a scoped migration merge.
Version/checkpoint changes follow actual verified source changes. A migration
installs into the consuming project only; no global or other-repository writes.

Contract tests use the actual PowerShell engine in temporary Git fixtures for
Work, compaction, forwarding, immutable destinations, receipt invalidation,
turn isolation, failed checks, missing context and private-data exclusion.
The live test uses the real installed OpenCode loop and a local fixture model:
`INITIAL` -> automatic review -> `REVIEWED` -> `completion_allowed`. It validates
host behavior without external models/credentials or claims of model judgment.
Codex protocol and bootstrap regressions must still pass after shared changes.
