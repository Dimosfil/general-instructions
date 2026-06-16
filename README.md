# General Instructions Library

Reusable instructions, templates, and playbooks for AI-agent collaboration live
here.

These files should stay project-agnostic. If a rule mentions a concrete path, scene,
database, product name, or local environment, it belongs in that project's own
`AGENTS.md`, runbook, or project memory instead.

Start with:

- `VERSION.md` and `CHANGELOG.md`: current accepted instruction-kit version and
  release notes for copied project instruction kits.
- `COMMANDS.md`: common commands for using and maintaining the instruction kit.
- `USER_GUIDE.md`: short user-facing overview of the main rules.
- `INDEX.md`: catalog of available instructions and templates.
- `GENERAL_DEVELOPMENT_PLAYBOOK.md`: must-have setup plan for starting and
  maintaining a project with an AI agent.
- `patterns/GIT_WORKFLOW.md`: reusable git policy and commit-message language
  preferences.
- `patterns/INSTRUCTION_KIT_MIGRATIONS.md`: migration-style update workflow for
  copied project instruction kits.
- `patterns/FEATURE_WORKFLOW_CONTRACTS.md`: project-local contracts for agreed
  feature workflows, branching states, background work, and behavior guarantees.
- `patterns/RAG_SYSTEM_STRUCTURE.md`: expandable RAG structure for project
  memory, source indexing, retrieval adapters, context packets, and writeback.
- `patterns/SEMANTIC_RAG_RETRIEVAL.md`: embedding and semantic retrieval rules
  for chunk export, hybrid search, evals, and safety.
- `patterns/SKILL_MODULES.md`: guidance for reusable agent skill modules.
- `migrations/`: accepted ordered migrations for updating copied instruction
  kits.
- `templates/`: starter files to copy into project repositories.
- `checklists/`: short operational checklists.
- `updates/`: maintenance-only dated recommendations for this repository.
  External projects should not read this folder during startup.
