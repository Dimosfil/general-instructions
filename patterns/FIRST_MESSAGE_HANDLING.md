# First Message Handling

Use this pattern at the beginning of a new chat or after a context reset.

## Short Titles

Treat the first user message as a chat title when it looks like a short project
name, feature name, or label rather than an actionable request.

In that case:

- Run only the documented startup context restore.
- Stop after the restore.
- Ask what the user wants to do next.
- Do not execute the title text as a task.

Use judgment. A short first message can still be a real task when it contains an
action verb or an explicit request.

## Shared Instruction Bootstrap

If the first user message is a path to a shared instruction library, or a request
to connect shared instructions, treat it as an instruction bootstrap.

In that case:

- Read the shared rules needed for bootstrapping.
- Deploy a local instruction kit into the current project from the shared
  templates and checklist.
- Do not create only a thin `AGENTS.md` that points back to the shared folder.
- Do not add the shared folder as a dependency, package, submodule, symlink, or
  runtime reference unless the user explicitly asks for that.
- Do not read the shared library's `updates/` folder while bootstrapping a
  consuming project.
