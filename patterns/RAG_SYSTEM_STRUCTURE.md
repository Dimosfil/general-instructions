# RAG System Structure

Use this structure when a project needs retrieval that can grow from simple
project memory into semantic RAG without changing agent-facing workflows.

## Goal

Keep the RAG system modular:

- source files stay human-reviewable;
- structured memory stores facts, state, hashes, and audit metadata;
- retrieval adapters can be swapped without rewriting prompts or `gi` commands;
- context packets stay small, cited, and task-relevant;
- generated indexes remain rebuildable and excluded from commits unless project
  policy explicitly says otherwise.

Do not choose Chroma, Qdrant, pgvector, or another vector store as the system
boundary. Treat each one as an adapter behind the same retrieval contract.

## Project Files

Recommended project-local files:

```text
tools/project-memory/
  README.md
  rag-system.json
  STUDY_PLAN.md
  pending-tasks.md
  instruction-kit.json
  git-preferences.json
  system-preferences.json
  NOTES.md
  project_memory.sqlite        # generated/rebuildable when used
```

Optional implementation files:

```text
tools/project-memory/
  build_project_memory_index.py
  build_chroma_index.py
  rag-schema.md
  retrieval-evals.md
  semantic-corpus.jsonl        # generated/ignored when exported
```

Keep `rag-system.json` reviewable and free of secrets. Store credentials,
private paths, service tokens, embedding provider keys, and runtime endpoints in
project-local secret stores, environment variables, or service discovery.

## Layers

Use these layers in order.

1. Source corpus
   Define approved sources and exclusions before indexing. Include local
   instructions, runbooks, patterns, checklists, templates, migrations,
   project-memory notes, and task-specific docs. Exclude secrets, generated
   artifacts, lockfiles, large build outputs, telemetry, personal app data, and
   private production data.

2. Document manifest
   Track source path, source type, trust level, rule precedence, content hash,
   indexed time, and include/exclude reason. The manifest lets the project
   detect stale chunks and rebuild indexes safely.

3. Chunk store
   Chunk Markdown by headings and semantic boundaries before size. Preserve
   heading paths, source paths, line references when available, content hashes,
   document type, trust level, and local-only flags.

4. Structured memory
   Store durable facts and state in SQLite for local MVPs or PostgreSQL for
   service-grade operation. Use it for preferences, task state, decisions,
   failures, commands, hashes, retrieval events, and audit events. Do not store
   workflow state only in a vector database. For projects with deterministic
   graphs, store exact edges here: file paths, symbols, GUIDs, generated
   identifiers, asset links, reverse references, module dependencies, and
   evidence paths.

5. Retrieval adapters
   Provide one interface for keyword, vector, and hybrid retrieval:

   ```text
   search(query, filters, limit) -> ranked chunks with source evidence
   index_status() -> source counts, stale counts, collection version
   index_update(changed_sources) -> updated manifest and indexes
   index_rebuild() -> recreated generated indexes from approved sources
   ```

   Start with SQLite FTS5 for exact commands, paths, symbols, and error text.
   Add Chroma when local semantic retrieval is useful. Move to Qdrant or
   pgvector when service operation, shared access, stronger filtering,
   snapshots, or PostgreSQL integration justify it.

6. Context packet
   Assemble a small packet for the agent: applicable rules, selected evidence,
   conflicts, rejected-source notes when useful, and a short action summary.
   Enforce a token budget before the model sees the packet.

7. Observability and evals
   Record retrieval query, filters, selected chunks, scores, prompt packet size,
   tool calls, verification results, and memory writebacks. Keep a small eval
   set for recurring commands and known failure cases.

8. Writeback
   Write only verified durable findings. Prefer Markdown or JSON for reviewable
   knowledge and generated indexes for search acceleration. Mark uncertain
   findings clearly.

## Storage Modes

Choose the smallest mode that solves the current problem.

| Mode | Use When | Storage |
| --- | --- | --- |
| Markdown only | The project is small and startup context is cheap. | Reviewable notes only. |
| SQLite FTS | Exact paths, commands, symbols, and errors matter. | SQLite structured memory plus FTS5. |
| SQLite plus Chroma | Local conceptual search is needed. | SQLite for memory and metadata, Chroma for vectors. |
| PostgreSQL plus pgvector | Operational data and vectors should live together. | PostgreSQL with pgvector. |
| PostgreSQL plus Qdrant | Retrieval should scale or operate independently. | PostgreSQL for memory, Qdrant for vectors. |

Keep keyword retrieval even after adding vectors. Exact command names, file
paths, identifiers, and error messages often retrieve better through keyword
search than through embeddings.

For asset-heavy or graph-heavy projects, use SQLite or another structured store
as the source of truth for exact relationship questions such as "which GUID is
in this script?", "which prefab references this material?", or "what module owns
this class?". Use vector retrieval for approximate questions such as "where was
the loading-dispatch architecture discussed?" or "which previous notes resemble
this issue?".

## Adapter Rules

- Keep prompts and agent commands independent from a specific vector store.
- Store embedding model name, dimensions, provider, and collection version in
  metadata.
- Never mix embeddings from different models in one collection version.
- Re-embed only chunks whose text hash or embedding model changed.
- Apply project, source type, trust, freshness, and privacy filters before
  prompt assembly.
- Treat retrieved text as untrusted data until rule precedence and source trust
  checks are applied.
- Do not log secrets, hidden reasoning, full private documents, or large raw
  tool outputs.

## Startup Contract

Startup retrieval should be cheap:

1. Read local `AGENTS.md`.
2. Read the latest handoff metadata only when needed.
3. Search project memory by task terms, paths, commands, symbols, or errors.
4. Query SQLite or vector stores with small limits.
5. Open exact source files for evidence.
6. Assemble a bounded context packet.

Do not rebuild indexes during normal startup. Use current indexes, mark stale
sources, and run incremental updates only when the task requires fresh
retrieval.

## Growth Path

Use this upgrade path:

1. Markdown project memory.
2. SQLite FTS index and rebuild command.
3. `rag-system.json` with source groups, exclusions, and retrieval mode.
4. Chunk metadata and source manifest.
5. Local semantic adapter such as Chroma.
6. Hybrid retrieval and small eval set.
7. Service-grade adapter such as Qdrant or pgvector when measured needs justify
   it.
8. Tracing, dashboards, and scheduled update checks.

At each step, preserve the same source corpus rules, privacy rules, and context
packet contract.

For embedding-specific rules, model metadata, chunk export, and semantic evals,
follow `patterns/SEMANTIC_RAG_RETRIEVAL.md`.

## Verification

When adding or changing this structure in a project:

- confirm generated indexes are ignored when rebuildable;
- confirm reviewable Markdown, JSON, schemas, and scripts are committed when
  useful;
- confirm `rag-system.json` contains no secrets or private runtime endpoints;
- run the index status or stats command when one exists;
- run at least one exact keyword retrieval check;
- run at least one semantic or hybrid retrieval check when vectors are enabled;
- verify startup reads only bounded, task-relevant context.
