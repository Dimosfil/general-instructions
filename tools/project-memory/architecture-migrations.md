# Architecture Migrations

This file records major architecture rewrites, platform moves, framework
replacements, storage changes, service splits, routing changes, and other
changes that alter how this repository is organized.

Do not use this file for ordinary chat handoffs. Keep current chat state in
`tools/summary/` and durable reusable rules in the main instruction files,
patterns, templates, and accepted migrations.

## Entries

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
