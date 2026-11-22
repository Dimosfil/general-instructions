## Verification

Apply the whole-task gate in `03-rule-precedence.md`.

For full-scope work, reuse one inventory of affected areas and entry points.
Record evidence, exclusions, findings, and blockers. For settings, include
owners and runtime consumers. Keep unchecked or blocked areas open. Distinguish
search coverage from verification of fixes.

Choose checks by changed behavior, affected layers, risk, and the documented
project contract. Complete required checks, including any explicitly requested
full test or release workflow. Use the smallest sufficient set for other tasks.
Do not add tests for reversible, low-impact edits when they only restate the
implementation and protect no meaningful behavior.

Before a heavy run, verify the profile, scope, and likely resource use.
Apply the mandatory authorization boundary. Use focused checks and report
remaining gaps when a heavy run is outside the authorized scope.

After relevant checks pass, repeat or broaden them only for a new change,
failure, unresolved concern, or mandatory project gate. Respect the
authorization boundary, report unavailable checks, and continue independent work.

For behavior/architecture changes, check the pre-edit mechanism mapping, scenario
result, invariants, and side effects under `patterns/ARCHITECTURE_AND_CODE_QUALITY.md`.
Reject undocumented bypasses and tests merely mirroring code. A restored final
state does not prove intermediate effects safe; report live verification gaps.

For an affected module boundary, inspect direct and indirect dependency and call paths.
Verify through the normal entry point that success, failure, and fallback paths
respect the contract and that any bypass stays within its documented scope.

For consequential invariants, use controlled cases to show the check accepts a
representative conforming case and detects a representative violation. Reuse
existing evidence when sufficient and report verification gaps.

For configurable behavior, inspect identifier-selected branches, embedded limits,
defaults and mappings, and competing policies. Vary contract data to verify that
the normal entry point uses the authoritative value. Check the documented outcomes
for valid, missing and invalid data. Trace moved rules through old fallback paths.
If target storage is unavailable, verify the prepared data package offline and
report unapplied changes and pending live checks. Follow
`patterns/CONFIGURATION_BOUNDARIES.md`.

For documentation-only changes:

```powershell
git diff --check
```

For larger changes, reread the edited files and confirm links, paths, and
checklists still match the repository layout.

For a meaningful feature, workflow, business-rule, data-model, integration, or
architecture change, compare the scoped diff with the relevant durable
contracts before calling the task complete. Check each changed behavior,
state transition, failure path, invariant, and architecture decision against
the current source and tests. Update the affected focused project-memory spec
in the same scope, or record why an existing spec already covers it. Check
affected user-facing documentation separately, and verify links and current
implementation maps. A report, handoff summary, ticket, or commit message does
not satisfy this contract check. Do not expand the check into a whole-project
audit when the change is narrow.
When a spec is added, renamed, moved, or retired, check the project-memory
README or canonical spec index and its relative links in the same batch.

After API, admin-tool, or service writes that include Russian or other
non-ASCII text, read the saved value back through the API or product UI and
check the stored data, not only terminal display. Treat literal `????`,
replacement characters such as `�` or `пїЅ`, and whole mojibake fragments such
as `Р Сџ`, `Р С™`, `РЎРѓ`, or `РЎвЂљ` where readable text is expected as failures.
Do not flag a single normal Cyrillic letter such as `Р` or `С` by itself as
corruption.

If adding a file under `templates/`, `patterns/`, or `checklists/`, update
`INDEX.md` in the same change.
