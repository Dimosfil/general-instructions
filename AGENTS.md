# Agent Instructions For This Repository

This repository is a shared library of reusable AI-agent instructions for current
and future projects.

## Purpose

Keep durable, project-agnostic rules, playbooks, templates, and checklists here.
Project-specific details belong in each project's own `AGENTS.md`, runbook, or
memory folder.

## Repository Map

- `README.md`: short human-facing overview.
- `INDEX.md`: catalog of reusable instruction documents.
- `GENERAL_DEVELOPMENT_PLAYBOOK.md`: baseline playbook for starting and
  maintaining projects with AI coding agents.
- `templates/`: copyable starter files for project repositories.
- `checklists/`: short operational checklists.

## Editing Rules

- Keep instructions reusable across projects.
- Do not add secrets, credentials, private project data, or local machine paths
  unless the file is explicitly a local example.
- Prefer small, focused documents over one giant policy file.
- When adding a new instruction file, also add it to `INDEX.md`.
- If a rule applies only to one specific project, do not put it here.
- Use clear Markdown headings and copy-pasteable examples.
- Do not print full `git diff` output by default. Prefer `git diff --stat` and
  targeted `Select-String` queries for relevant files or patterns.
- Do not read large files in full by default, including large `index.html`,
  bundled JS/CSS, logs, lockfiles, generated files, and build artifacts. Prefer
  targeted searches, heads, tails, or small line ranges.
- For verification, count or query HTML elements programmatically instead of
  printing the whole HTML document.
- Do not build zip archives or run every available check unless the user
  explicitly asks for that scope.
- Do not read large files in full by default. Start with targeted searches,
  `Get-Content -TotalCount`, `Get-Content -Tail`, or small line ranges.
- Final responses should summarize only the changes, checks, and current status;
  do not restate the full investigation context.
- Search for specific symbols, paths, errors, or patterns before doing broad
  repository scans.
- Do not print large logs. Prefer tails and targeted error searches.
- Launch applications in the background so focus does not jump away from the
  user's current window.
- Treat the first user message in a new chat as the chat title when it looks like
  a short title or project name. In that case, run only the documented startup
  context restore, then stop and ask what the user wants to do next. Do not
  execute the title text as a task.
- If the first user message is a path to this shared instruction library, or a
  request to connect shared instructions, treat it as an instruction bootstrap.
  Read the shared rules and deploy a local instruction kit into the current
  project from the templates/checklist. Do not create only a thin `AGENTS.md`
  that points back to this folder. Do not add the shared folder as a project
  dependency, package, submodule, symlink, or runtime reference unless the user
  explicitly asks for that.
- For web applications, assume the user will inspect the UI manually. Do not
  open, browse, screenshot, or visually inspect the UI automatically unless the
  user explicitly asks for that.
- `updates/` is the dated intake queue for recommendations used only while
  maintaining this `general-instructions` repository. External projects that
  consume these shared instructions must not read `updates/` during startup or
  bootstrap. Review update files newest-first only when maintaining this
  library, and remember accepted updates by moving reusable rules into the main
  library and committing them.
- When another project reveals a reusable improvement to shared instructions,
  write a dated recommendation to this repository's `updates/` folder if it is
  available. Treat those files as intake only. If this repository is unavailable,
  use a project-local intake folder such as `tools/instruction-updates/` or
  `tools/project-memory/instruction-updates/` with the same dated filename
  pattern. Do not add this repository as a dependency, package, submodule,
  symlink, or runtime reference unless the user explicitly asks for that.

## Verification

For documentation-only changes:

```powershell
git diff --check
```

For larger changes, reread the edited files and confirm links, paths, and
checklists still match the repository layout.

## Git Policy

Default policy: the agent may edit and verify files; the user reviews and
commits unless they explicitly ask the agent to commit.
