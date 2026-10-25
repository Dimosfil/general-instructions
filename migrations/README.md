# Instruction Kit Migrations

This folder contains accepted, ordered migrations for projects that copied this
instruction kit.

Consuming projects may read this folder when the user asks to check or apply
instruction updates. They must not read `updates/`; that folder is intake only
for maintaining this shared library.

Migration file names use:

```text
YYYY.MM.DD.N__short_description.md
```

Apply migrations in filename order and record applied migration IDs in
`tools/project-memory/instruction-kit.json`.

## Release Order

Assign every new migration a numeric version strictly greater than the last
published `VERSION.md`, even when the underlying work predates that release.
Do not backdate, rename or renumber released IDs. If an older ID was published
late, deliver the omitted changes through a new forward migration: advancing a
checkpoint or an equal-version zero-pending result does not verify file delivery.

Before committing or publishing a source release, run
`tools/test-instruction-kit-release.ps1 -BaseRef
<previous-published-ref>` against the actual previous release commit. The check
includes untracked, staged and committed additions relative to that ref and
rejects removal/renaming of released migration IDs. Keep
the reference fixed through the release; defaulting to the new HEAD after a
commit would hide additions. Run routing, task-verification and bootstrap checks
for the changed delivery contract before recording installation.

## Installation And Host Applicability

This contract governs recording for all migrations, including historical
Verify And Record sections. Read the pending batch in order and merge its file
changes, including later host adapters, before recording the completed batch.
Do not stop between migrations solely to wait for another host's activation.

Record installation only after required files, project-preserving merges and
applicable installation checks pass. Missing files, merge conflicts and failed
installation checks remain blockers. Source-library regression suites apply
when maintaining the library; do not copy its development tests into consuming
projects merely to satisfy historical verification text.

Keep runtime evidence separate from installation metadata:

| Check | Applicable runtime | Effect on recording |
| --- | --- | --- |
| Required files and project-preserving merge | Every installation | Must pass before `-RecordApplied` |
| `/hooks`, `hooks/list`, project/definition trust, CLI omission, Desktop create/send | Codex | Report configured/trusted/live-tested separately; unavailable activation does not block installed files |
| Plugin loading and automatic review in the response loop | OpenCode | Report configured/loaded/live-tested separately; unavailable activation does not block installed files |

Unavailable, failed or unperformed runtime checks must remain explicit runtime
gaps with the reason and next action (for example, reload or native trust).
Do not fabricate success, grant trust, or treat the checkpoint/zero pending
count as proof of enforcement. Use manual Work/Complete when automatic hooks
are unverified. A task explicitly requiring runtime activation or live tests
remains unfinished until those requirements pass, even after installation is
recorded. Preserve explicit opt-outs and unresolved file migration blockers.
