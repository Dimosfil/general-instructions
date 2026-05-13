# Instruction Updates

This folder stores dated recommendations from real projects.

Use it as an intake queue for improvements to the reusable instruction library.
Files should be named with a date/time prefix, for example:

```text
YYYY-MM-DD_HH-mm-ss_CODEX_RECOMMENDED_GENERAL_INSTRUCTIONS_UPDATES.md
```

## Rules

- Treat update files as incoming recommendations, not automatically accepted
  instructions.
- Review updates by date, newest first, when maintaining this repository.
- Extract reusable rules, patterns, templates, or checklist items into the main
  library.
- Keep project-specific details out of the main instructions.
- Preserve token economy: prefer short rules, targeted retrieval, and templates
  that avoid dumping large files, logs, diffs, databases, or generated outputs.
- Do not load all update files by default. Read only the update being evaluated
  or the latest relevant file.
- Remember accepted updates by committing the resulting library changes, not by
  relying on chat history.
