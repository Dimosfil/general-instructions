# Connected Projects

This register tracks external projects and sources that the shared
`general-instructions` library depends on, publishes to, or coordinates with.
Agents should read it before changing instruction-kit propagation, update flows,
or cross-project integration guidance.

## Canonical GitHub Source Repository

- Purpose: public source of truth for the shared reusable instruction library.
- Business or architectural role: distributes accepted GI rules, templates,
  migrations, and project-memory patterns to consuming projects.
- Local folder: current checkout at repository root.
- Canonical Git URL: `https://github.com/Dimosfil/general-instructions.git`.
- Service ID or runtime endpoints: none.
- Owner or source of truth: Git history and accepted release artifacts in this
  repository.
- Data/API contract: consuming projects read accepted files such as `AGENTS.md`,
  `COMMANDS.md`, `patterns/`, `templates/`, `migrations/`, `VERSION.md`, and
  `CHANGELOG.md`.
- Setup, sync, build, test, or update commands: use project-local `gi обновить`
  semantics and verification checks; do not treat `gi ...` as a shell command.
- Version, branch, or update cadence: `VERSION.md` records the accepted
  instruction-kit version; `migrations/` records ordered propagation steps.
- Privacy, secret, license, and access boundaries: do not commit secrets,
  private project data, generated indexes, local paths outside documented
  examples, or unrelated consuming-project state.
- Status and caveats: active.
- Reason this dependency still exists: it is the canonical distribution channel
  for reusable GI behavior.

## Consuming Project Instruction Kits

- Purpose: project-local copies of the shared instructions in downstream
  repositories.
- Business or architectural role: let each project restore context, commands,
  project memory, and accepted rules without rereading this whole source repo.
- Local folder: project-specific and not part of this repository by default.
- Canonical Git/package/docs URLs: configured per project, normally pointing to
  `https://github.com/Dimosfil/general-instructions.git` through
  `tools/project-memory/instruction-kit.json`.
- Service ID or runtime endpoints: none by default.
- Owner or source of truth: each consuming project's local instructions govern
  its behavior after migration; this repository provides accepted defaults.
- Data/API contract: `gi обновить` applies accepted migrations and updates local
  metadata only after file changes are applied.
- Setup, sync, build, test, or update commands: consuming projects use their own
  local bootstrap/update flow and must not rely on this repository's dirty
  worktree or private state.
- Version, branch, or update cadence: compare project-local
  `tools/project-memory/instruction-kit.json` with this repository's
  `VERSION.md`.
- Privacy, secret, license, and access boundaries: do not read, edit, or scan
  consuming project folders unless the user gives an explicit path and task.
- Status and caveats: distributed integration pattern, not one fixed workspace.
- Reason this dependency still exists: reusable GI guidance is valuable only if
  consuming projects can find and apply accepted changes safely.

