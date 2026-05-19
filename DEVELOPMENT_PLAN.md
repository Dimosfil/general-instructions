# Development Plan

This file tracks planned improvements for the shared instruction library.

Keep entries concise, reusable, and project-agnostic. Accepted implementation
details should move into the relevant playbooks, templates, checklists, or
patterns.

## Planned Improvements

### Instruction Kit Versioning And Update Notices

Status: implemented 2026-05-15

Goal: let projects that already copied this instruction kit know when accepted
shared-instruction updates are available, without making projects depend on this
repository at runtime.

### Reduce Rule Duplication Across Files

Status: planned

Goal: the same rules (e.g., "do not read `updates/` during bootstrap", "gi means
general-instructions, not git") are duplicated across 5+ files. This creates
sync risk and makes maintenance expensive.

Proposed approach:

- Audit all rules across `AGENTS.md`, `COMMANDS.md`,
  `GENERAL_DEVELOPMENT_PLAYBOOK.md`, `patterns/`, and `templates/`.
- Define an authoritative source for each rule group.
- Cross-reference instead of duplicating. Remove redundant paragraphs.
- Keep templates lightweight (starter-only) with references to shared rules.
- Ensure `COMMANDS.md` stays a command reference, not a policy document.

### Clean Up Development Artifacts

Status: implemented 2026-05-19

- Removed stale handoff summaries from `tools/summary/`.
- Check `tools/project-memory/pending-tasks.md` for completed vs dangling
  items and update status.

### Evaluate User Guide Naming Convention

Status: planned

`USER_GUIDE.md` is fully in Russian but has an English filename. Consider
either renaming to `USER_GUIDE.ru.md` or maintaining a bilingual file pair.

### Template Size Audit

Status: planned

`templates/AGENTS.template.md` was 203 lines, mostly duplicated rules of which
~67 lines were removed. Audit other templates (`AGENT_RUNBOOK.template.md`,
`AGENT_WORKING_AGREEMENTS.template.md`) for similar bloat.
