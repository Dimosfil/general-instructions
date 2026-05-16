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

Scope boundary: this development plan and the `updates/` intake queue are only
for maintaining this `general-instructions` repository. Consuming projects must
not read them during startup, bootstrap, or update checks. They should only look
at accepted release artifacts such as `VERSION.md`, `CHANGELOG.md`, tags, or
release notes.

Proposed approach:

- Add a simple accepted-instructions version file, such as `VERSION.md`.
- Add `CHANGELOG.md` for accepted changes that consuming projects may need to
  review.
- Add a copied provenance template, such as
  `templates/instruction-kit.template.json`, so bootstrapped projects can record
  the installed instruction-kit version, source, install date, and copied files.
- Update `templates/agent-start.template.ps1` so local projects can compare the
  installed version with a nearby shared instruction library and print a compact
  notice when updates are available.
- Keep startup checks local-first. For remote/shared repositories, support a
  Git-based check only when explicitly configured or requested.
- Add update guidance that agents should review accepted versions and changelog,
  not the `updates/` intake queue, when deciding whether a consuming project
  should refresh its local instructions.

Verification ideas:

- Bootstrap a sample project from the templates.
- Confirm the startup script reports no update when versions match.
- Confirm the startup script reports a concise update notice when the shared
  version is newer.
- Confirm remote update checks fail quietly when Git or network access is
  unavailable.
