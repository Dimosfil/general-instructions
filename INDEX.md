# General Instructions Index

Reusable instructions in this repository are grouped by job.

## User Documents

- `USER_GUIDE.md`: short user-facing overview of the main instructions and
  rules.

## Core Playbooks

- `DEVELOPMENT_PLAN.md`: planned improvements for this shared instruction
  library.
- `GENERAL_DEVELOPMENT_PLAYBOOK.md`: baseline process for starting and
  maintaining a software project with an AI coding agent.

## Patterns

- `patterns/AGENT_EXPERIENCE_SQLITE.md`: local SQLite memory/index pattern for
  AI-agent experience, with Markdown export for review.
- `patterns/RAG_STARTUP_FLOW.md`: token-conscious startup retrieval flow for
  restoring only task-relevant context.
- `patterns/SHARED_INSTRUCTIONS_BOOTSTRAP.md`: how to deploy local project
  instruction files from this shared library when the user provides its path.

## Templates

- `templates/AGENTS.template.md`: starter root `AGENTS.md` for a project.
- `templates/CODEX_RUNBOOK.template.md`: starter project runbook.
- `templates/CODEX_WORKING_AGREEMENTS.template.md`: starter working agreements.
- `templates/project-memory-README.template.md`: starter memory folder README.
- `templates/pending-tasks.template.md`: starter active task checklist.
- `templates/STUDY_PLAN.template.md`: starter study plan for mapping a project.
- `templates/codex-start.template.ps1`: compact startup script template with
  line guards and `git diff --stat`.
- `templates/gitignore-agent-memory.template`: ignore snippet for local agent
  memory and runtime noise.
- `templates/SUMMARY.template.md`: handoff summary template.

## Update Intake

- `updates/`: maintenance-only dated recommendations for this
  `general-instructions` repository. External projects must not read this folder
  during startup or bootstrap.

## Checklists

- `checklists/NEW_PROJECT_AGENT_SETUP.md`: quick checklist for adding agent
  support to a project.

## Library Rules

- Keep files project-agnostic.
- Prefer templates when the target project needs its own local decisions.
- Link new files here when they become part of the reusable library.
