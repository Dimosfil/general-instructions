# Instruction Kit Automatic Updates

## Scenario And Ownership

First concrete task -> checker resolves metadata policy and accepted source ->
context builder preserves policy evidence and pending-action handoff -> agent
merges and verifies listed Markdown migrations -> explicit metadata recording ->
checker confirms installed version and zero pending migrations.

`templates/check-instruction-kit-updates.template.ps1` owns policy defaults,
validation, source resolution, migration ordering, and status evidence.
`tools/get-gi-context.ps1` transports that output; it must not independently
decide policy. `patterns/AGENTS_RUNTIME/07-startup.md` owns agent execution.

## Invariants

- Missing update-check and auto-apply keys mean true. Only JSON boolean false
  establishes an explicit opt-out; cite the metadata path, key, and value.
- Reject non-boolean policy values. Invalid or unavailable evidence means
  unverified policy, never an invented disabled setting or user decision.
- A notice-only legacy helper and unsupported helper `-Apply` do not disable
  agent automatic application. No extra user command or confirmation is needed.
- Checking is read-only. The agent applies and verifies files before invoking
  `-RecordApplied`; only that explicit operation advances migration state.
- Preserve project settings, unrelated edits, and opt-outs. On an actual
  conflict or scope/access blocker, report the precise unperformed operation.
- Equal versions with no skipped migrations avoid reading migration entries.
  Disabled checks and missing migration sources have unknown pending count.
- The checkpoint means verified file installation, not automatic enforcement.
  The accepted `migrations/README.md` applicability contract and startup module
  govern historical recording language. Merge the whole ordered pending batch,
  including later host adapters; missing/conflicting files or failed installation
  checks block recording. Do not wait between file migrations for another host.
- Codex trust, CLI omission and Desktop delivery checks and OpenCode plugin/loop
  checks establish separate runtime readiness. Unavailable or failed activation
  must be reported with reason/next action and manual fallback, without leaving
  verified file migrations pending. Explicit runtime tasks remain unfinished.
  Source regression suites belong to source maintenance, not consuming startup.
- The checker emits host applicability before pending bodies, including on the
  `-Apply` error path; the context builder forwards it within existing budgets.
  No host probing, trust changes, synthetic activation success, or new readiness
  schema is required for metadata recording.

## Verification

`tools/test-gi-context-routing.ps1` exercises legacy/default/enabled policy,
explicit opt-outs with evidence, invalid values, pending action through the
actual builder, unchanged metadata during checks, and zero pending after
recording. It also covers the applicability handoff and a batch recovering
historical skipped Codex migrations together with the later OpenCode adapter,
without native host APIs or fabricated readiness. Bootstrap checks verify
delivery of the shared helper and modules.
