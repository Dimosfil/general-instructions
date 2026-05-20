# Recommendation: Treat Pending Migrations As An Array

Date: 2026-05-20

## Context

While applying a copied instruction-kit update in a downstream project, the
local `tools/check-instruction-kit-updates.ps1` helper failed when exactly one
pending migration existed.

## Evidence

PowerShell returned a scalar object for `$pending`, so `$pending.Count` failed
under `Set-StrictMode -Version Latest`.

## Suggested Change

Wrap the migration pipeline in `@(...)` in
`templates/check-instruction-kit-updates.template.ps1`, so zero, one, or many
pending migrations are handled consistently.

## Privacy

No private project data, logs, credentials, telemetry, or production data are
included.
