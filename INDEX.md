# General Instructions Index

Reusable instructions in this repository are grouped by job.

## User Documents

- `CHANGELOG.md`: accepted instruction-kit changes by version.
- `config/gi-main.json`: bootstrap pointer to the local GI config service.
- `COMMANDS.md`: user-facing agent prompts and helper commands for
  bootstrapping projects, restoring context, configuring Git commit languages
  and agent working languages, checking instruction updates, and maintaining
  this library.
- `USER_GUIDE.md`: short user-facing overview of the main instructions and
  rules.
- `VERSION.md`: current accepted instruction-kit version.

## Project Memory

- `tools/project-memory/README.md`: local project-memory usage, including the
  generated SQLite index workflow.
- `tools/project-memory/build_project_memory_index.py`: stdlib-only SQLite
  indexer for fast rebuilds from git tracked files and targeted searches.

## Core Playbooks

- `DEVELOPMENT_PLAN.md`: planned improvements for this shared instruction
  library.
- `GENERAL_DEVELOPMENT_PLAYBOOK.md`: baseline process for starting and
  maintaining a project with an AI agent.

## Patterns

- `patterns/AGENT_EXPERIENCE_SQLITE.md`: local SQLite memory/index pattern for
  AI-agent experience, with Markdown export for review.
- `patterns/AGENT_HARNESS_RUNTIME.md`: runtime pattern for building or auditing
  model-tool-observation loops, tool permissions, compaction, connectors, evals,
  and production agent harnesses.
- `patterns/AI_ENGINEERING_BENCHMARKS.md`: benchmark pattern for proving AI
  engineering cost reduction while preserving task quality.
- `patterns/CONFIGURATION_BOUNDARIES.md`: configuration-boundary rules for
  keeping deploy, user, runtime, machine, service, credential, path,
  feature-flag, and operational values out of application logic.
- `patterns/FIRST_MESSAGE_HANDLING.md`: first-message title detection and shared
  instruction bootstrap behavior.
- `patterns/FEATURE_WORKFLOW_CONTRACTS.md`: project-local contracts for agreed
  feature workflows, branching states, background work, and user-visible
  behavior guarantees.
- `patterns/FULL_RAG_AGENT_PLATFORM.md`: architecture pattern for a LangGraph
  agent platform with structured memory, semantic retrieval, tracing, evals,
  and optional n8n automation.
- `patterns/GIT_WORKFLOW.md`: git policy, explicit commit requests, dirty
  worktrees, and commit-message language preferences.
- `patterns/INSTRUCTION_KIT_MIGRATIONS.md`: migration-style update workflow for
  copied project instruction kits.
- `patterns/MODEL_ROUTING_AND_COST_CONTROL.md`: model-routing and cost-control
  pattern for agent applications that use multiple models, tools, RAG, prompt
  caching, and explicit budget limits.
- `patterns/PROJECT_TESTING_STRATEGY.md`: project-aware testing strategy for
  new features, bug fixes, smoke checks, and release confidence.
- `patterns/PROJECT_FTP_DEPLOY.md`: project-local FTP/FTPS/SFTP deploy config
  and `gi ftp` upload workflow.
- `patterns/RAG_SYSTEM_STRUCTURE.md`: expandable RAG structure that separates
  source corpus, structured memory, retrieval adapters, context packets,
  tracing, evals, and writeback.
- `patterns/RAG_STARTUP_FLOW.md`: token-conscious startup retrieval flow for
  restoring only task-relevant context.
- `patterns/SERVICE_DISCOVERY_CONFIG.md`: config-service bootstrap,
  service-identity verification, mismatch handling, and local override rules.
- `patterns/SHARED_INSTRUCTIONS_BOOTSTRAP.md`: how to deploy local project
  instruction files from this shared library when the user provides its path.
- `patterns/SKILL_MODULES.md`: when to use rules, patterns, templates, or
  self-contained skill modules.

## Skills

- `skills/task-manager-plans/SKILL.md`: optional skill for reading, writing, and
  syncing plans through configured task managers, with a WorkNest adapter under
  `skills/task-manager-plans/references/managers/worknest.md`.

## Templates

- `templates/AGENTS.template.md`: starter root `AGENTS.md` for a project.
- `templates/AGENT_RUNBOOK.template.md`: starter project runbook.
- `templates/AGENT_WORKING_AGREEMENTS.template.md`: starter working agreements.
- `templates/AI_ENGINEERING_BENCHMARK.template.md`: copyable form for measuring
  raw and optimized AI engineering workflows.
- `templates/check-instruction-kit-updates.template.ps1`: project command for
  checking accepted instruction-kit migrations.
- `templates/config-service-local.template.json`: starter project-local
  bootstrap override for the GI config service.
- `templates/project-memory-README.template.md`: starter memory folder README.
- `templates/rag-system.template.json`: project-local RAG configuration shape
  for source groups, exclusions, structured memory, retrieval adapters, context
  packets, and writeback.
- `templates/pending-tasks.template.md`: starter active task checklist.
- `templates/STUDY_PLAN.template.md`: starter study plan for mapping a project.
- `templates/agent-start.template.ps1`: compact startup script template with
  line guards and `git diff --stat`.
- `templates/FEATURE_TEST_PLAN.template.md`: copyable plan for verifying a new
  feature or risky change.
- `templates/FEATURE_WORKFLOW_CONTRACT.template.md`: copyable contract for
  documenting a feature's agreed runtime workflow and behavior guarantees.
- `templates/ftp.local.template.json`: redacted starter shape for a
  project-local `tools/deploy/ftp.local.json` upload config.
- `templates/git-preferences.template.json`: project-local commit-message
  language preference defaults.
- `templates/system-preferences.template.json`: project-local agent working
  language preference defaults.
- `templates/select-project-language.template.ps1`: interactive project setup
  command for ordered language choices covering project working environment,
  commit messages, and tasks.
- `templates/gitignore-agent-memory.template`: ignore snippet for local agent
  memory and runtime noise.
- `templates/instruction-kit.template.json`: copied provenance and local update
  check configuration for project instruction kits.
- `templates/select-git-commit-languages.template.ps1`: interactive project
  setup command for commit-message language preferences.
- `templates/select-system-language.template.ps1`: interactive project setup
  command for the agent's user-facing working language.
- `templates/SKILL.template.md`: starter `SKILL.md` for a self-contained agent
  skill module.
- `templates/SUMMARY.template.md`: handoff summary template.
- `templates/task-managers.template.json`: starter project-local task-manager
  configuration for optional plan sync skills.

## Update Intake

- `updates/`: maintenance-only dated recommendations for this
  `general-instructions` repository. External projects must not read this folder
  during startup or bootstrap.

## Migrations

- `migrations/`: accepted ordered instruction-kit migrations for consuming
  projects. External projects may read this folder only when checking or applying
  instruction updates.

## Checklists

- `checklists/NEW_PROJECT_AGENT_SETUP.md`: quick checklist for adding agent
  support to a project.

## Library Rules

- Keep files project-agnostic.
- Prefer templates when the target project needs its own local decisions.
- Link new files here when they become part of the reusable library.
