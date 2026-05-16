# Instruction Updates

This folder stores dated recommendations from real projects for maintaining this
`general-instructions` repository.

Use it as an intake queue for improvements to the reusable instruction library.
Files should be named with a date/time prefix, for example:

```text
YYYY-MM-DD_HH-mm-ss_AGENT_RECOMMENDED_GENERAL_INSTRUCTIONS_UPDATES.md
```

## Rules

- Treat update files as incoming recommendations, not automatically accepted
  instructions.
- This folder is maintenance-only for `general-instructions`. External projects
  that consume the shared instructions must not read it during startup or
  bootstrap.
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
