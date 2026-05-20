# check-instruction-kit single pending migration

Date: 2026-05-19

## Recommendation

Update `templates/check-instruction-kit-updates.template.ps1` so `$pending` is
always an array before `.Count` is used.

## Evidence

During a copied-kit update in `D:\AI\AiAnalytics`, exactly one pending migration
caused PowerShell StrictMode to fail with:

```text
The property 'Count' cannot be found on this object.
```

Wrapping the pipeline assignment with `@(...)` allowed the helper to list the
single migration, record it after file changes were applied, and report no
pending migrations afterward.

## Privacy Review

No secrets, user data, production data, local logs, telemetry, or private app
data are included. The project path is only used as evidence for where the
template issue surfaced.
