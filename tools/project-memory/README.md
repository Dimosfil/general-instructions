# Project Memory

This folder stores concise, durable project knowledge for AI agents.

Use Markdown and JSON files here for human-reviewable memory. Use the local
SQLite database only as a generated search index that can be rebuilt from git
tracked files.

## SQLite Index

Recommended local database:

```text
tools/project-memory/project_memory.sqlite
```

Rebuild it from git tracked repository content:

```powershell
python .\tools\project-memory\build_project_memory_index.py rebuild
```

Check index size:

```powershell
python .\tools\project-memory\build_project_memory_index.py stats
```

Search indexed content:

```powershell
python .\tools\project-memory\build_project_memory_index.py search "gi config"
```

Export semantic-ready chunks for a future embedding adapter:

```powershell
python .\tools\project-memory\build_project_memory_index.py export-chunks
```

Build a local Chroma vector index from the exported chunks:

```powershell
uv run --with chromadb python .\tools\project-memory\build_chroma_index.py rebuild
```

Run semantic search through Chroma:

```powershell
uv run --with chromadb python .\tools\project-memory\build_chroma_index.py query "semantic startup retrieval"
```

The database is ignored by git. Commit this README, durable Markdown notes,
preference JSON files, and indexing scripts instead.

Use SQLite for deterministic project facts and graphs: paths, symbols, exact
references, generated identifiers, asset links, reverse dependencies, commands,
failures, and evidence-backed notes. In Unity-like projects, this can include
`.meta` GUID mappings, prefab/scene/material/script references, and
assembly-definition dependencies.

Use vector retrieval only as a second semantic layer for conceptual questions
over curated notes, summaries, architecture docs, and selected chunks. Do not
replace exact graph queries with embeddings, and always verify current source
files before editing because generated indexes can be stale.

## RAG System Structure

This repository records its expandable RAG configuration in:

```text
tools/project-memory/rag-system.json
```

The current mode is SQLite FTS. Chroma, Qdrant, pgvector, or other vector stores
should be added as retrieval adapters behind the same structure rather than as a
replacement for project memory.

Generated semantic exports such as `tools/project-memory/semantic-corpus.jsonl`
are ignored and should be rebuilt from tracked source files.

The generated Chroma index under `tools/project-memory/vector-index/chroma` is
ignored and can be rebuilt from `semantic-corpus.jsonl`.
