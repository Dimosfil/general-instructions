# Pending Tasks

Use this file for active project-wide plans and multi-step work.

Keep entries concise and task-relevant. Do not store full diffs, large logs,
generated outputs, secrets, credentials, or private production data.

## Status Markers

- `[ ]` not started
- `[~]` in progress
- `[x]` done
- `[!]` blocked or needs attention

## Tasks

### Shared Instruction Bootstrap Sources

Goal: make a new project bootstrap from either a local shared-instruction folder
or a Git repository URL with enough clarity that any supported agent understands
the source, reads only the required shared files, and deploys a local instruction
kit into the current project.

Planned changes:

- [ ] Update `patterns/SHARED_INSTRUCTIONS_BOOTSTRAP.md` with explicit source
  handling for local folders, existing local clones, and Git repository URLs.
- [ ] Update `patterns/FIRST_MESSAGE_HANDLING.md` so a first message containing
  a shared-instruction folder or Git URL triggers bootstrap behavior.
- [ ] Document that Git URL access may require user approval before clone/fetch.
- [ ] Require bootstrapped projects to copy local files from templates, not add
  the shared repository as a dependency, package, submodule, symlink, or runtime
  reference.
- [ ] Ensure `tools/project-memory/instruction-kit.json` records source,
  installed version, install date, update-check settings, and copied files.
- [ ] Confirm `updates/` remains maintenance-only and is not read during
  consuming-project bootstrap.

Execution order:

- [ ] Update bootstrap and first-message patterns.
- [ ] Update playbook/checklist/template references if needed.
- [ ] Run documentation checks.

Risks or dependencies:

- [ ] Network access or private Git repositories may require explicit user
  approval and credentials.
- [ ] Existing project instruction files must be merged carefully rather than
  overwritten.

Verification:

- [ ] `git diff --check`
- [ ] Reread edited bootstrap files.
- [ ] Check that no guidance tells consuming projects to depend on the shared
  repository at runtime.

### Instruction Kit Migration Updates

Goal: support "check instruction updates" in consuming projects using accepted
migrations, similar to database schema migrations.

Planned changes:

- [x] Add `patterns/INSTRUCTION_KIT_MIGRATIONS.md`.
- [x] Add accepted `migrations/` files for recent instruction-kit changes.
- [x] Add `templates/check-instruction-kit-updates.template.ps1`.
- [x] Update index, playbook, checklist, templates, version, and changelog.

Verification:

- [x] `git diff --check`
- [x] Validate JSON templates.
- [x] Run the update-check script in a temporary project shape.
