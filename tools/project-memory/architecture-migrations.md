# Architecture Migrations

This file records major architecture rewrites, platform moves, framework
replacements, storage changes, service splits, routing changes, and other
changes that alter how this repository is organized.

Do not use this file for ordinary chat handoffs. Keep current chat state in
`tools/summary/` and durable reusable rules in the main instruction files,
patterns, templates, and accepted migrations.

## Entries

### 2026-09-22: Bounded Runtime Context Pipeline

Previous architecture: root entrypoints, migration history metadata, and the
combined 07/08/09 runtime modules still imposed large fixed or route-level
context costs. Update status, command routing, summary restore, and Git state
also required separate tool loops.

New architecture: focused 07/08/09 modules are selected by the route manifest;
the old combined paths are compatibility indexes. `tools/get-gi-context.ps1`
assembles update status, one routed packet, and bounded start evidence in one
call. Metadata schema v2 stores an `applied_through` checkpoint with explicit
addition/skip exceptions, and `config/gi-context-budgets.json` makes context
ceilings executable regression gates.

Reason: reduce fixed input tokens and repeated tool-loop amplification while
preserving accepted behavior, legacy metadata compatibility, deterministic
routing, and measurable safeguards against context growth.

### 2026-08-06: Optional Code Intelligence Federation

Previous architecture: GI project memory could index exact source facts and
semantic documentation, but it had no shared contract for deeper symbol/call
graphs, Git-aware change risk, or provider code-health evidence. Integrations
would have been provider-specific and easy to confuse with durable project
knowledge.

New architecture: `rag-system.json` has an optional, disabled-by-default
`code_intelligence` layer. A stdlib MCP bridge routes only configured
capabilities to allowlisted tools, preserves raw provider output, attaches Git
freshness metadata, and leaves project memory authoritative for specifications,
decisions, workflows, and exact project facts. Repowise is the first tested
adapter but remains independently installed and indexed.

Reason: gain code-topology and risk evidence without replacing GI's existing
database, coupling agent workflows to one vendor, or allowing external tooling
to mutate repositories and editor configuration implicitly.

### 2026-06-21: Modular Agents Runtime Entrypoint

Previous architecture: root `AGENTS.md` and the copied project template carried
large inline runtime rule sets. Agents had to load broad guidance even when a
task needed only one command family or policy area.

New architecture: root and copied `AGENTS.md` files are compact entrypoints with
a routing table. Detailed reusable runtime rules live in
`patterns/AGENTS_RUNTIME/` modules by topic, and instruction-kit metadata copies
those modules alongside the entrypoint.

Reason: preserve accepted behavior while reducing startup context, making
project onboarding faster, and giving agents an explicit map for task-specific
rule retrieval.

### 2026-09-22: Lazy GI Command Routing And Staged Update Check

Previous architecture: every specific `gi` command loaded the full command
reference before its runtime modules, and first-task update guidance allowed
equal-version checks to pull changelog, index, and migration inventory into
model context.

New architecture: `config/gi-command-routes.json` and
`tools/resolve-gi-command.ps1` select the longest matching alias and return one
compact command contract plus only its mandatory context files. `COMMANDS.md`
is a bounded help index. Startup update checks compare installed and accepted
versions first; equal versions return zero pending migrations immediately, while
newer accepted versions enumerate and load only unapplied migrations.

Reason: reduce persistent conversation context and tool-result amplification
without weakening command safety, deterministic routing, or migration
application guarantees.

### 2026-06-21: Coherent Batch Verification Pattern

Previous architecture: batch-completion expectations were spread across
configuration, project-memory, verification, and `gi refactor` guidance.

New architecture: `patterns/COHERENT_BATCH_VERIFICATION.md` is the reusable
module for checking source-of-truth consistency, durable project-memory
writeback, scoped diffs, and evidence-backed verification after meaningful
implementation, refactor, migration, or configuration cleanup batches.

Reason: agents need a portable completion standard that catches cross-layer
drift, stale specs, unrelated files, and ambiguous verification warnings without
turning every batch into a full-project audit.

### 2026-06-21: Architecture And Code Quality Pattern Extraction

Previous architecture: the reusable architecture and code-quality baseline lived
mostly as inline guidance in `AGENTS.md`, `templates/AGENTS.template.md`, and the
accepted code-quality migration.

New architecture: `patterns/ARCHITECTURE_AND_CODE_QUALITY.md` is the reusable
module for OOP, SOLID, DRY, clean-code, separation of concerns, interface and
adapter boundaries, abstraction discipline, and verification. The live
instructions and copied-project template keep concise baseline text and link to
the pattern.

Reason: consuming projects need a copyable, focused module for architecture and
code-quality rules instead of only receiving duplicated inline text.
