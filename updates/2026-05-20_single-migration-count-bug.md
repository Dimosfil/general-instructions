# Recommendation: Fix Single Pending Migration Count

Date: 2026-05-20

## Observed Problem

`tools/check-instruction-kit-updates.ps1 -RecordApplied` failed when exactly
one pending migration existed because strict PowerShell mode treats the single
`FileInfo` result as an object without `.Count`.

## Proposed Reusable Rule Or Artifact

Wrap the pending migration pipeline in an array expression:

```powershell
$pending = @(Get-ChildItem ... | Where-Object { ... })
```

Apply the same singleton-safe pattern in generated instruction-kit scripts that
count pipeline results.

## Evidence

- Project: `D:\AI\WorkNest`
- Command: `.\tools\check-instruction-kit-updates.ps1 -RecordApplied`
- Failure: `The property 'Count' cannot be found on this object.`
- Local fixed file: `tools/check-instruction-kit-updates.ps1`

## Expected Benefit

Projects can apply a single pending GI migration without manual metadata edits
or agent-side script repair.

## Risks

Low. The change preserves behavior for zero and multiple migrations while
making singleton results countable.

## Privacy Review

No secrets, credentials, production data, local app logs, telemetry, or user
personal data are included.
