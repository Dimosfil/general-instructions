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
- Do not read large chunks of `index.html` unless necessary. Prefer targeted
  searches and small excerpts around the relevant UI, script, or markup.
- For verification, count or query HTML elements programmatically instead of
  printing the whole HTML document.
- Do not build zip archives or run every available check unless the user
  explicitly asks for that scope.

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
