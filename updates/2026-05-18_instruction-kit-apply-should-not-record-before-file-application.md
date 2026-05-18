# Recommendation: Make instruction-kit -Apply safer

Date: 2026-05-18
Source project: frogmail_pro

## Observation

During `gi обновить`, `tools/check-instruction-kit-updates.ps1 -Apply` recorded pending migrations as applied in `tools/project-memory/instruction-kit.json`, while also printing that the script records migration metadata only and that an agent must still apply each migration's file changes.

This creates a risky partial-update state: metadata says the project is on the new instruction-kit version, but project instruction files may still be missing the migration content unless the agent notices and applies the markdown migration instructions manually.

## Suggested Shared Instruction Improvement

Update the instruction-kit migration workflow and/or script so metadata is not advanced before file changes are actually applied. Safer options:

1. Split commands clearly:
   - `-Plan` or default: list pending migrations.
   - `-RecordApplied`: metadata-only, explicitly dangerous/manual.
   - Agent-driven apply: update files first, then record migrations.
2. Make `-Apply` stop before writing metadata unless a migration has a machine-applicable patch or an explicit confirmation flag.
3. Add a standard agent instruction: after running a metadata-only apply script, immediately verify migrated file content and correct metadata if application fails.

## Why It Matters

Consuming projects can silently skip future migrations because `applied_migrations` already contains IDs whose file changes were never applied. That makes later `gi обновить` checks report "No pending instruction migrations" even when local rules are stale.
