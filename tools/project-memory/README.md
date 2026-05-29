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

The database is ignored by git. Commit this README, durable Markdown notes,
preference JSON files, and indexing scripts instead.
